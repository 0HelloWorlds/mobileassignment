import 'package:latlong2/latlong.dart';

/// How urgent/dangerous a safety alert is.
enum AlertSeverity { low, medium, high }

AlertSeverity _severityFromString(String? value) {
  switch (value) {
    case 'low':
      return AlertSeverity.low;
    case 'high':
      return AlertSeverity.high;
    case 'medium':
    default:
      return AlertSeverity.medium;
  }
}

/// A single safety alert, backed by the `safetyalerts` table in Supabase.
class SafetyAlert {
  final String id;
  final String typeId;
  final String title;
  final String? description;
  final LatLng position;
  final DateTime reportedAt;
  final String? reportedBy;
  final String status;
  final AlertSeverity severity;

  const SafetyAlert({
    required this.id,
    required this.typeId,
    required this.title,
    this.description,
    required this.position,
    required this.reportedAt,
    this.reportedBy,
    this.status = 'active',
    this.severity = AlertSeverity.medium,
  });

  /// True if this alert was submitted by a real user (has a reporter id),
  /// as opposed to being seeded by an admin/system process.
  bool get userReported => reportedBy != null;

  /// Converts this alert into the column shape Supabase expects for an
  /// insert/update. `id` and `created_at` are left out — Supabase fills
  /// those in automatically on insert.
  Map<String, dynamic> toInsertJson() => {
    'type': typeId,
    'title': title,
    'description': description,
    'latitude': position.latitude,
    'longitude': position.longitude,
    'status': status,
    'severity': severity.name,
    'reported_by': reportedBy,
  };

  /// Rebuilds a [SafetyAlert] from a row returned by Supabase.
  factory SafetyAlert.fromJson(Map<String, dynamic> json) => SafetyAlert(
    id: json['id'] as String,
    typeId: json['type'] as String,
    title: json['title'] as String,
    description: json['description'] as String?,
    position: LatLng(
      (json['latitude'] as num).toDouble(),
      (json['longitude'] as num).toDouble(),
    ),
    reportedAt: DateTime.parse(json['created_at'] as String),
    reportedBy: json['reported_by'] as String?,
    status: json['status'] as String? ?? 'active',
    severity: _severityFromString(json['severity'] as String?),
  );
}