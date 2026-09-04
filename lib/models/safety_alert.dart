import 'package:latlong2/latlong.dart';

/// A single safety alert — either seeded/mock data or submitted by a user.
///
/// [typeId] matches one of the ids in mapLayerOptions (accident, flood,
/// weather, road_closed, construction) so we can reuse the same icon/color
/// styling everywhere an alert is shown.
class SafetyAlert {
  final String id;
  final String typeId;
  final String title;
  final String? description;
  final LatLng position;
  final DateTime reportedAt;
  final bool userReported;

  const SafetyAlert({
    required this.id,
    required this.typeId,
    required this.title,
    this.description,
    required this.position,
    required this.reportedAt,
    this.userReported = false,
  });
}