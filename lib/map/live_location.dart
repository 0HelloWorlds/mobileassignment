import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart';

class LiveLocationMap extends StatefulWidget {
  final double? height;
  final double borderRadius;
  final double zoom;
  final bool interactive;
  final VoidCallback? onTap;

  final List<Marker> extraMarkers;

  final List<Polyline> polylines;

  /// Called every time a new GPS fix comes in, with the updated LatLng.
  final ValueChanged<LatLng>? onLocationChanged;

  const LiveLocationMap({
    super.key,
    this.height = 140,
    this.borderRadius = 16,
    this.zoom = 16,
    this.interactive = false,
    this.onTap,
    this.extraMarkers = const [],
    this.polylines = const [],
    this.onLocationChanged,
  });

  @override
  State<LiveLocationMap> createState() => _LiveLocationMapState();
}

class _LiveLocationMapState extends State<LiveLocationMap> {
  final Location _location = Location();
  final MapController _mapController = MapController();
  StreamSubscription<LocationData>? _locationSub;

  LatLng? _currentLatLng;
  bool _loading = true;
  bool _serviceDisabled = false;
  bool _permissionDenied = false;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    super.dispose();
  }

  Future<void> _initLocation() async {
    // 1. Make sure device GPS/location service is turned on.
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        if (!mounted) return;
        setState(() {
          _serviceDisabled = true;
          _loading = false;
        });
        return;
      }
    }

    // 2. Make sure we have permission to read the user's location.
    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }
    if (permission != PermissionStatus.granted &&
        permission != PermissionStatus.grantedLimited) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
        _loading = false;
      });
      return;
    }

    // 3. Start listening for live position updates.
    _locationSub = _location.onLocationChanged.listen((locData) {
      if (locData.latitude == null || locData.longitude == null) return;
      final newLatLng = LatLng(locData.latitude!, locData.longitude!);
      if (!mounted) return;
      setState(() {
        _currentLatLng = newLatLng;
        _loading = false;
      });
      widget.onLocationChanged?.call(newLatLng);
      if (_mapReady) {
        _mapController.move(newLatLng, _mapController.camera.zoom);
      }
    });
  }

  Future<void> _retry() async {
    setState(() {
      _loading = true;
      _serviceDisabled = false;
      _permissionDenied = false;
    });
    await _initLocation();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: widget.height == null
            ? SizedBox.expand(child: _buildContent())
            : SizedBox(
          height: widget.height,
          width: double.infinity,
          child: _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) {
      return Container(
        color: Colors.blue[50],
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_serviceDisabled) {
      return _buildMessage(
        icon: Icons.location_disabled,
        message: 'GPS is turned off. Tap to try again.',
        onTap: _retry,
      );
    }

    if (_permissionDenied) {
      return _buildMessage(
        icon: Icons.location_off,
        message: 'Location permission denied. Tap to try again.',
        onTap: _retry,
      );
    }

    if (_currentLatLng == null) {
      return Container(
        color: Colors.blue[50],
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: _currentLatLng!,
        initialZoom: widget.zoom,
        interactionOptions: InteractionOptions(
          flags: widget.interactive ? InteractiveFlag.all : InteractiveFlag.none,
        ),
        onMapReady: () {
          _mapReady = true;
        },
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.mob_ass',
        ),
        if (widget.polylines.isNotEmpty)
          PolylineLayer(polylines: widget.polylines),
        if (widget.extraMarkers.isNotEmpty)
          MarkerLayer(markers: widget.extraMarkers),
        MarkerLayer(
          markers: [
            Marker(
              point: _currentLatLng!,
              width: 40,
              height: 40,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMessage({
    required IconData icon,
    required String message,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.blue[50],
        padding: const EdgeInsets.all(12),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.grey),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}