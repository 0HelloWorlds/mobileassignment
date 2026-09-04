import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:mob_ass/routing.dart';
import 'package:mob_ass/navigation.dart';

class RouteResultPage extends StatefulWidget {
  const RouteResultPage({super.key});

  @override
  State<RouteResultPage> createState() => _RouteResultPageState();
}

class _RouteResultPageState extends State<RouteResultPage> {
  final TextEditingController _destinationController = TextEditingController();
  final MapController _mapController = MapController();

  LatLng? _origin;
  LatLng? _destination;

  List<PlaceResult> _searchResults = [];
  bool _searching = false;

  List<RouteOption> _routes = [];
  int _selectedIndex = 0;
  bool _loadingRoutes = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  @override
  void dispose() {
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    final location = loc.Location();

    var serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) return;
    }

    var permission = await location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await location.requestPermission();
    }
    if (permission != loc.PermissionStatus.granted &&
        permission != loc.PermissionStatus.grantedLimited) {
      return;
    }

    final data = await location.getLocation();
    if (data.latitude == null || data.longitude == null) return;
    if (!mounted) return;
    setState(() {
      _origin = LatLng(data.latitude!, data.longitude!);
    });
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.trim().length < 3) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() => _searching = true);
    final results = await searchPlaces(query);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _searching = false;
    });
  }

  Future<void> _selectDestination(PlaceResult place) async {
    setState(() {
      _destination = place.position;
      _destinationController.text = place.displayName;
      _searchResults = [];
    });
    await _fetchRoutes();
  }

  Future<void> _fetchRoutes() async {
    final origin = _origin;
    final destination = _destination;
    if (origin == null || destination == null) return;

    setState(() {
      _loadingRoutes = true;
      _errorMessage = null;
      _routes = [];
    });

    try {
      final routes = await fetchRoutes(origin, destination);
      if (!mounted) return;
      setState(() {
        _routes = routes;
        _selectedIndex = 0;
        _loadingRoutes = false;
      });
      _fitMapToRoute(routes.first.points);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not find a route. Please try again.';
        _loadingRoutes = false;
      });
    }
  }

  void _fitMapToRoute(List<LatLng> points) {
    if (points.isEmpty) return;
    // Wait a frame so the map has a size before we try to fit bounds to it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedRoute = _routes.isNotEmpty ? _routes[_selectedIndex] : null;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Route Result'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFromToCard(),
                    const SizedBox(height: 16),
                    _buildMapPreview(),
                    const SizedBox(height: 16),
                    if (_loadingRoutes)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red, fontSize: 13),
                        ),
                      ),
                    for (int i = 0; i < _routes.length; i++) ...[
                      _buildRouteCard(_routes[i], i),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ),
            if (selectedRoute != null) _buildStartNavigationButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildFromToCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('From',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.circle, color: Colors.green, size: 12),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _origin == null
                            ? 'Getting current location...'
                            : 'Current Location',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('To',
                    style: TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.location_on, color: Colors.red, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: TextField(
                        controller: _destinationController,
                        decoration: const InputDecoration(
                          hintText: 'Search destination',
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        onChanged: _onSearchChanged,
                      ),
                    ),
                  ],
                ),
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: LinearProgressIndicator(),
                  ),
                if (_searchResults.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: _searchResults.map((place) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.place_outlined, size: 18),
                            title: Text(
                              place.displayName,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () => _selectDestination(place),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.swap_vert, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildMapPreview() {
    final selectedRoute = _routes.isNotEmpty ? _routes[_selectedIndex] : null;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 220,
        child: _origin == null
            ? Container(
          color: Colors.blue[50],
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        )
            : FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _origin!,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.mob_ass',
            ),
            if (selectedRoute != null)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: selectedRoute.points,
                    strokeWidth: 5,
                    color: Colors.green,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                Marker(
                  point: _origin!,
                  width: 20,
                  height: 20,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
                if (_destination != null)
                  Marker(
                    point: _destination!,
                    width: 32,
                    height: 32,
                    child: const Icon(Icons.location_on,
                        color: Colors.red, size: 32),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(RouteOption route, int index) {
    final selected = index == _selectedIndex;
    final isSafest = route.label == 'Safest Route';

    return GestureDetector(
      onTap: () {
        setState(() => _selectedIndex = index);
        _fitMapToRoute(route.points);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Colors.green : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      route.label,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (isSafest) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.verified, color: Colors.green, size: 16),
                    ],
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildMetric('Distance', '${route.distanceKm.toStringAsFixed(1)} km'),
                _buildMetric('ETA', '${route.durationMin} mins'),
                _buildMetric(
                  'Safety Score',
                  '${route.safetyScore}/100',
                  valueColor: route.safetyScore >= 85
                      ? Colors.green
                      : route.safetyScore >= 70
                      ? Colors.orange
                      : Colors.red,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value, {Color? valueColor}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: valueColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartNavigationButton() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              final destination = _destination;
              if (destination == null) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => NavigationPage(
                    route: _routes[_selectedIndex],
                    destination: destination,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.navigation),
            label: const Text('Start Navigation',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}