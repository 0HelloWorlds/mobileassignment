import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:mob_ass/auth/auth_service.dart';
import 'package:mob_ass/models/safety_alert.dart';

class SafetyAlertsStore extends ChangeNotifier {
  SafetyAlertsStore._internal();

  static final SafetyAlertsStore instance = SafetyAlertsStore._internal();

  static final Distance _distance = Distance();

  List<SafetyAlert> _alerts = [];
  bool _isLoading = false;
  String? _error;

  List<SafetyAlert> get alerts => List.unmodifiable(_alerts);
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadAlerts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await supabase
          .from('safetyalerts')
          .select()
          .order('created_at', ascending: false);

      _alerts = (data as List)
          .map((row) => SafetyAlert.fromJson(row as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _error = 'Failed to load alerts: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reportAlert({
    required String typeId,
    required String title,
    String? description,
    required LatLng position,
    AlertSeverity severity = AlertSeverity.medium,
  }) async {
    final draft = SafetyAlert(
      id: '',
      typeId: typeId,
      title: title,
      description: description,
      position: position,
      reportedAt: DateTime.now(),
      reportedBy: supabase.auth.currentUser?.id,
      severity: severity,
    );

    await supabase.from('safetyalerts').insert(draft.toInsertJson());
    await loadAlerts();
  }

  Future<void> updateAlert(
      String id, {
        String? typeId,
        String? title,
        String? description,
        AlertSeverity? severity,
        String? status,
      }) async {


    final alertData = await supabase
        .from('safetyalerts')
        .select()
        .eq('id', id)
        .single();

    final oldAlert =
    SafetyAlert.fromJson(alertData as Map<String, dynamic>);

    final updates = <String, dynamic>{};

    if (typeId != null) {
      updates['type'] = typeId;
    }

    if (title != null) {
      updates['title'] = title;
    }

    if (description != null) {
      updates['description'] = description;
    }

    if (severity != null) {
      updates['severity'] = severity.name;
    }

    if (status != null) {
      updates['status'] = status;
    }

    if (updates.isEmpty) return;


    // Update the alert
    await supabase
        .from('safetyalerts')
        .update(updates)
        .eq('id', id);



    if (status == 'resolved' &&
        oldAlert.status != 'resolved' &&
        oldAlert.reportedBy != null) {

      await supabase
          .from('notifications')
          .insert({
        'user_id': oldAlert.reportedBy,
        'title': 'Safety Alert Resolved',
        'message':
        'Your reported safety alert "${oldAlert.title}" has been marked as resolved.',
        'type': 'alert_resolved',
        'is_read': false,
      });
    }


    await loadAlerts();
  }

  Future<void> deleteAlert(String id) async {
    final userId = supabase.auth.currentUser?.id;

    if (userId == null) {
      throw Exception('User is not logged in.');
    }

    await supabase
        .from('safetyalerts')
        .delete()
        .eq('id', id)
        .eq('reported_by', userId);

    await loadAlerts();
  }

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