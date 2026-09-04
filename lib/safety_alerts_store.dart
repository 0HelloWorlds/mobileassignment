import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:mob_ass/models/safety_alert.dart';

/// Simple in-memory, app-wide store of safety alerts.
///
/// There's no backend yet, so this holds both the seeded demo alerts and
/// anything the user reports during the session. It's a ChangeNotifier so
/// any screen (Home, Map, Safety Alerts) can listen and stay in sync the
/// moment a new alert is reported.
class SafetyAlertsStore extends ChangeNotifier {
  SafetyAlertsStore._internal() {
    _seedMockAlerts();
  }

  static final SafetyAlertsStore instance = SafetyAlertsStore._internal();

  static final Distance _distance = Distance();

  final List<SafetyAlert> _alerts = [];
  int _nextId = 1;

  /// All alerts, most recently reported first.
  List<SafetyAlert> get alerts => List.unmodifiable(_alerts);

  String _newId() => 'alert_${_nextId++}';

  void _seedMockAlerts() {
    final now = DateTime.now();
    _alerts.addAll([
      SafetyAlert(
        id: _newId(),
        typeId: 'accident',
        title: 'Accident - Jalan Genting Klang',
        position: const LatLng(3.1958, 101.7263),
        reportedAt: now.subtract(const Duration(minutes: 18)),
      ),
      SafetyAlert(
        id: _newId(),
        typeId: 'flood',
        title: 'Flood Warning - Wangsa Maju',
        position: const LatLng(3.2030, 101.7340),
        reportedAt: now.subtract(const Duration(hours: 2)),
      ),
    ]);
  }

  /// Adds a new user-submitted alert and notifies listeners.
  SafetyAlert reportAlert({
    required String typeId,
    required String title,
    String? description,
    required LatLng position,
  }) {
    final alert = SafetyAlert(
      id: _newId(),
      typeId: typeId,
      title: title,
      description: description,
      position: position,
      reportedAt: DateTime.now(),
      userReported: true,
    );
    _alerts.insert(0, alert);
    notifyListeners();
    return alert;
  }

  /// Alerts within [radiusMeters] of [from], sorted nearest first, paired
  /// with their distance in meters.
  List<MapEntry<SafetyAlert, double>> nearby(
      LatLng from, {
        double radiusMeters = 5000,
      }) {
    final results = _alerts
        .map((a) => MapEntry(a, _distance(from, a.position)))
        .where((e) => e.value <= radiusMeters)
        .toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return results;
  }

  double distanceFrom(LatLng from, SafetyAlert alert) =>
      _distance(from, alert.position);
}