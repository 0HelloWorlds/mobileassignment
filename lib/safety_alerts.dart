import 'dart:async';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:location/location.dart' as loc;
import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/models/safety_alert.dart';
import 'package:mob_ass/alerts/report_alert_page.dart';
import 'package:mob_ass/alerts/safety_alerts_store.dart';
import 'package:mob_ass/alerts/alert_detail_page.dart';

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
  String _statusFilter = 'active';

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _startLocationTracking();
    _store.loadAlerts();
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
      if (alert.status != 'active') continue;
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
                '${_severityLabel(alert.severity)} · ${alert.title} — ${distanceMeters.round()}m ahead',
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

  Color _severityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Colors.green;
      case AlertSeverity.medium:
        return Colors.orange;
      case AlertSeverity.high:
        return Colors.red;
    }
  }

  String _severityLabel(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return 'Low';
      case AlertSeverity.medium:
        return 'Medium';
      case AlertSeverity.high:
        return 'High';
    }
  }

  void _openAlertDetails(SafetyAlert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlertDetailPage(alert: alert)),
    );
  }

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

  Widget _statusTab({
    required String label,
    required String value,
    required int count,
  }) {
    final selected = _statusFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _statusFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(
          '$label ($count)',
          style: TextStyle(
            color: selected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allAlerts = _currentPosition != null
        ? _store.nearby(_currentPosition!, radiusMeters: 50000).map((e) => e.key).toList()
        : _store.alerts;
    final alerts = allAlerts.where((a) => a.status == _statusFilter).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Safety Alerts'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _statusTab(
                    label: 'Active',
                    value: 'active',
                    count: allAlerts.where((a) => a.status == 'active').length,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _statusTab(
                    label: 'Resolved',
                    value: 'resolved',
                    count: allAlerts.where((a) => a.status == 'resolved').length,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: alerts.isEmpty
                ? Center(
              child: Text(
                _statusFilter == 'active'
                    ? 'No active alerts nearby right now.'
                    : 'No resolved alerts to show.',
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
              itemCount: alerts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final alert = alerts[index];
                final option = _optionFor(alert.typeId);
                final severityColor = _severityColor(alert.severity);
                final distanceLabel = _currentPosition != null
                    ? '${(_store.distanceFrom(_currentPosition!, alert) / 1000).toStringAsFixed(1)} km away'
                    : null;
                final metaParts = [
                  if (distanceLabel != null) distanceLabel,
                  _relativeTime(alert.reportedAt),
                  if (alert.userReported) 'Reported by traveler',
                ];

                return GestureDetector(
                  onTap: () => _openAlertDetails(alert),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border(
                          left: BorderSide(color: severityColor, width: 4)),
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
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      alert.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: severityColor.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      _severityLabel(alert.severity),
                                      style: TextStyle(
                                        color: severityColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                metaParts.join(' • '),
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12),
                              ),
                              if (alert.description != null) ...[
                                const SizedBox(height: 4),
                                Text(alert.description!,
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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