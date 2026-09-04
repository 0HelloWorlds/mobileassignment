import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/models/safety_alert.dart';
import 'package:mob_ass/report_alert_page.dart';
import 'package:mob_ass/safety_alerts_store.dart';

class SafetyAlertPage extends StatefulWidget {
  const SafetyAlertPage({super.key});

  @override
  State<SafetyAlertPage> createState() => _SafetyAlertPageState();
}

class _SafetyAlertPageState extends State<SafetyAlertPage> {
  static const double _proximityRadiusMeters = 300;

  final SafetyAlertsStore _store = SafetyAlertsStore.instance;
  final loc.Location _location = loc.Location();
  StreamSubscription<loc.LocationData>? _locationSub;

  LatLng? _currentPosition;
  final Set<String> _notifiedAlertIds = {};

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _startLocationTracking();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    _locationSub?.cancel();
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    loc.PermissionStatus permission = await _location.hasPermission();
    if (permission == loc.PermissionStatus.denied) {
      permission = await _location.requestPermission();
    }
    if (permission != loc.PermissionStatus.granted &&
        permission != loc.PermissionStatus.grantedLimited) {
      return;
    }

    _locationSub = _location.onLocationChanged.listen((data) {
      if (data.latitude == null || data.longitude == null) return;
      final pos = LatLng(data.latitude!, data.longitude!);
      if (!mounted) return;
      setState(() => _currentPosition = pos);
      _checkProximity(pos);
    });
  }

  void _checkProximity(LatLng position) {
    final nearby = _store.nearby(position, radiusMeters: _proximityRadiusMeters);
    for (final entry in nearby) {
      final alert = entry.key;
      if (_notifiedAlertIds.contains(alert.id)) continue;
      _notifiedAlertIds.add(alert.id);
      _showProximityBanner(alert, entry.value);
    }
  }

  void _showProximityBanner(SafetyAlert alert, double distanceMeters) {
    if (!mounted) return;
    final option = _optionFor(alert.typeId);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: option.color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
        content: Row(
          children: [
            Icon(option.icon, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${alert.title} — ${distanceMeters.round()}m ahead',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MapLayerOption _optionFor(String typeId) => mapLayerOptions.firstWhere(
        (o) => o.id == typeId,
    orElse: () => mapLayerOptions.first,
  );

  Future<void> _openReportPage() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => const ReportAlertPage()),
    );
    if (result == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your report has been added.')),
      );
    }
  }

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final alerts = _currentPosition != null
        ? _store.nearby(_currentPosition!, radiusMeters: 50000).map((e) => e.key).toList()
        : _store.alerts;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Safety Alerts'),
      ),
      body: alerts.isEmpty
          ? const Center(child: Text('No alerts nearby right now.'))
          : ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final alert = alerts[index];
          final option = _optionFor(alert.typeId);
          final distanceLabel = _currentPosition != null
              ? '${(_store.distanceFrom(_currentPosition!, alert) / 1000).toStringAsFixed(1)} km away'
              : null;
          final metaParts = [
            if (distanceLabel != null) distanceLabel,
            _relativeTime(alert.reportedAt),
            if (alert.userReported) 'Reported by traveler',
          ];

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(option.icon, color: option.color, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metaParts.join(' • '),
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      if (alert.description != null) ...[
                        const SizedBox(height: 4),
                        Text(alert.description!, style: const TextStyle(fontSize: 12)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.green,
        onPressed: _openReportPage,
        icon: const Icon(Icons.add_alert),
        label: const Text('Report'),
      ),
    );
  }
}