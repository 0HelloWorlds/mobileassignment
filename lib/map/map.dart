import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/map/live_location.dart';
import 'package:mob_ass/models/safety_alert.dart';
import 'package:mob_ass/alerts/safety_alerts_store.dart';
import 'package:mob_ass/alerts/alert_detail_page.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  Set<String> _activeLayers = mapLayerOptions.map((o) => o.id).toSet();
  final SafetyAlertsStore _store = SafetyAlertsStore.instance;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    _store.loadAlerts();
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _openLayersPage() async {
    final result = await Navigator.push<Set<String>>(
      context,
      MaterialPageRoute(
        builder: (context) => MapLayersPage(initialSelected: _activeLayers),
      ),
    );
    if (result != null) {
      setState(() {
        _activeLayers = result;
      });
    }
  }

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

  void _openAlertDetail(SafetyAlert alert) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AlertDetailPage(alert: alert)),
    );
  }

  List<Marker> _buildAlertMarkers() {
    final visibleAlerts =
    _store.alerts.where((a) => _activeLayers.contains(a.typeId));

    return visibleAlerts.map((alert) {
      final option = mapLayerOptions.firstWhere((o) => o.id == alert.typeId);
      final severityColor = _severityColor(alert.severity);
      return Marker(
        point: alert.position,
        width: 36,
        height: 36,
        child: GestureDetector(
          onTap: () => _openAlertDetail(alert),
          child: Tooltip(
            message: alert.title,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: severityColor, width: 3),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 3),
                ],
              ),
              child: Icon(option.icon, color: option.color, size: 18),
            ),
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: LiveLocationMap(
              height: null,
              borderRadius: 0,
              interactive: true,
              extraMarkers: _buildAlertMarkers(),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.topRight,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  elevation: 4,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _openLayersPage,
                    child: const Padding(
                      padding: EdgeInsets.all(12),
                      child: Icon(Icons.menu, color: Colors.black87),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}