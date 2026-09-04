import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:mob_ass/route_result.dart';
import 'package:mob_ass/map/live_location.dart';
import 'package:mob_ass/map/geocoding.dart';

import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/models/safety_alert.dart';
import 'package:mob_ass/safety_alerts_store.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onNavigateToTab;
  const HomePage({super.key, this.onNavigateToTab});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _locationText = 'Getting your location...';
  LatLng? _lastGeocodedPosition;
  DateTime? _lastGeocodeTime;
  LatLng? _currentPosition;
  static const _distance = Distance();
  final SafetyAlertsStore _alertsStore = SafetyAlertsStore.instance;

  @override
  void initState() {
    super.initState();
    _alertsStore.addListener(_onStoreChanged);
  }

  @override
  void dispose() {
    _alertsStore.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  // Called by LiveLocationMap every time a new GPS fix comes in.
  void _onLocationChanged(LatLng position) async {
    _currentPosition = position;
    final movedFar = _lastGeocodedPosition == null ||
        _distance(position, _lastGeocodedPosition!) > 50;
    final longEnoughSinceLastCall = _lastGeocodeTime == null ||
        DateTime.now().difference(_lastGeocodeTime!) > const Duration(seconds: 5);

    if (!movedFar || !longEnoughSinceLastCall) return;

    _lastGeocodedPosition = position;
    _lastGeocodeTime = DateTime.now();

    final address = await reverseGeocode(position);
    if (!mounted) return;
    setState(() {
      _locationText = address ?? 'Location unavailable';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: (){},
                      icon: const Icon(Icons.menu),),
                    Column(
                      children: const [
                        Text(
                          'Safe Route Planner',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                        Text(
                          'Travel safer, travel smarter',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.notifications_none, color: Colors.red),
                      onPressed: (){},
                    ),
                  ],
                ),
                const SizedBox(height: 16,),

                // Search Bar
                GestureDetector(
                  onTap: (){
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const RouteResultPage(),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.search, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Where do you want to go ?',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ),
                        Icon(Icons.my_location, color: Colors.green),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Current location card
                InkWell(
                  onTap: () => widget.onNavigateToTab?.call(1),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.green, size: 28),
                        const SizedBox(width: 12),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Current Location',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _locationText,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Mini Map Preview Box - real, live-updating OpenStreetMap
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade100),
                  ),
                  child: LiveLocationMap(
                    height: 260,
                    interactive: false,
                    onTap: () => widget.onNavigateToTab?.call(1),
                    onLocationChanged: _onLocationChanged,
                  ),
                ),

                const SizedBox(height: 20),

                //Nearby Alert Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Nearby Alert',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => widget.onNavigateToTab?.call(2),
                      child: const Text('View all', style: TextStyle(color: Colors.green)),
                    )
                  ],
                ),
                Column(
                  children: _buildNearbyAlertCards(),
                ),
              ],
            ),
          )
      ),
    );
  }
  // Builds the top 3 nearest alert cards from the shared alerts store.
  List<Widget> _buildNearbyAlertCards() {
    final position = _currentPosition;
    final List<SafetyAlert> nearest = position != null
        ? _alertsStore.nearby(position, radiusMeters: 50000).take(3).map((e) => e.key).toList()
        : _alertsStore.alerts.take(3).toList();

    if (nearest.isEmpty) {
      return [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text(
            'No alerts nearby right now.',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ),
      ];
    }

    final cards = <Widget>[];
    for (final alert in nearest) {
      final option = mapLayerOptions.firstWhere(
            (o) => o.id == alert.typeId,
        orElse: () => mapLayerOptions.first,
      );
      final subtitle = position != null
          ? '${(_alertsStore.distanceFrom(position, alert) / 1000).toStringAsFixed(1)} km away'
          : (alert.description ?? 'Reported recently');

      cards.add(GestureDetector(
        onTap: () => widget.onNavigateToTab?.call(2),
        child: _buildAlertCard(
          icon: option.icon,
          iconColor: option.color,
          title: alert.title,
          subtitle: subtitle,
        ),
      ));
      cards.add(const SizedBox(height: 8));
    }
    if (cards.isNotEmpty) cards.removeLast();
    return cards;
  }

//Helper function to build alert items
  Widget _buildActionButton(BuildContext context, IconData icon, String label, Color color) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Filter by $label')),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

//Helper function to build alert items
  Widget _buildAlertCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }){
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Colors.grey),
        ],
      ),
    );
  }

}