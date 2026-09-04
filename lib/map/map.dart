import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
//import 'package:latlong2/latlong.dart';
import 'package:mob_ass/map/map_layer.dart';
import 'package:mob_ass/map/live_location.dart';
import 'package:mob_ass/safety_alerts_store.dart';

/*class _MockAlert {
  final String type;
  final String title;
  final LatLng position;

  const _MockAlert({
    required this.type,
    required this.title,
    required this.position,
  });
}

final List<_MockAlert> _mockAlerts = [
  const _MockAlert(
    type: 'accident',
    title: 'Accident - Jalan Genting Klang',
    position: LatLng(3.1958, 101.7263),
  ),
  const _MockAlert(
    type: 'accident',
    title: 'Accident - Jalan Setapak',
    position: LatLng(3.1885, 101.7180),
  ),
  const _MockAlert(
    type: 'flood',
    title: 'Flood Warning - Wangsa Maju',
    position: LatLng(3.2030, 101.7340),
  ),
  const _MockAlert(
    type: 'weather',
    title: 'Heavy Rain Expected',
    position: LatLng(3.1900, 101.7300),
  ),
  const _MockAlert(
    type: 'road_closed',
    title: 'Road Closed - Jalan Danau',
    position: LatLng(3.1990, 101.7200),
  ),
  const _MockAlert(
    type: 'construction',
    title: 'Construction Zone - Jalan Genting Kelang',
    position: LatLng(3.1930, 101.7230),
  ),
];
*/
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

  List<Marker> _buildAlertMarkers() {
    final visibleAlerts =
    _store.alerts.where((a) => _activeLayers.contains(a.typeId));

    return visibleAlerts.map((alert) {
      final option = mapLayerOptions.firstWhere((o) => o.id == alert.typeId);
      return Marker(
        point: alert.position,
        width: 36,
        height: 36,
        child: Tooltip(
          message: alert.title,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: option.color, width: 2),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 3),
              ],
            ),
            child: Icon(option.icon, color: option.color, size: 18),
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