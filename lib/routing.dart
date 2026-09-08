import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:mob_ass/models/safety_alert.dart';

const _userAgent = 'com.example.mob_ass (Safe Route Planner)';

class PlaceResult {
  final String displayName;
  final LatLng position;

  const PlaceResult({required this.displayName, required this.position});
}

Future<List<PlaceResult>> searchPlaces(String query) async {
  if (query.trim().isEmpty) return [];

  final uri = Uri.parse(
    'https://nominatim.openstreetmap.org/search'
        '?format=json'
        '&q=${Uri.encodeQueryComponent(query)}'
        '&limit=5'
        '&addressdetails=0'
        '&countrycodes=my',
  );

  try {
    final response = await http.get(uri, headers: {'User-Agent': _userAgent});
    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body) as List<dynamic>;
    return data.map((item) {
      final map = item as Map<String, dynamic>;
      return PlaceResult(
        displayName: map['display_name'] as String,
        position: LatLng(
          double.parse(map['lat'] as String),
          double.parse(map['lon'] as String),
        ),
      );
    }).toList();
  } catch (_) {
    return [];
  }
}

class RouteOption {
  final String label;
  final double distanceKm;
  final int durationMin;

  final int safetyScore;

  final List<LatLng> points;

  const RouteOption({
    required this.label,
    required this.distanceKm,
    required this.durationMin,
    required this.safetyScore,
    required this.points,
  });
}

class _ParsedRoute {
  final double distanceKm;
  final int durationMin;
  final List<LatLng> points;

  const _ParsedRoute({
    required this.distanceKm,
    required this.durationMin,
    required this.points,
  });
}

Future<List<_ParsedRoute>> _fetchOsrmSingle(
    List<LatLng> waypoints, {
      bool alternatives = false,
    }) async {
  final coords =
  waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
  final uri = Uri.parse(
    'https://router.project-osrm.org/route/v1/driving/$coords'
        '?alternatives=$alternatives&overview=full&geometries=geojson',
  );

  final response = await http.get(uri);
  if (response.statusCode != 200) return [];

  final data = jsonDecode(response.body) as Map<String, dynamic>;
  final routesJson = data['routes'] as List<dynamic>?;
  if (routesJson == null) return [];

  return routesJson.map((r) {
    final route = r as Map<String, dynamic>;
    final distanceKm = (route['distance'] as num) / 1000;
    final durationMin = ((route['duration'] as num) / 60).round();
    final coords = (route['geometry']['coordinates'] as List<dynamic>)
        .map((c) => LatLng((c as List<dynamic>)[1] as double,
        (c[0] as num).toDouble()))
        .toList();
    return _ParsedRoute(
        distanceKm: distanceKm, durationMin: durationMin, points: coords);
  }).toList();
}

LatLng _detourWaypoint(LatLng origin, LatLng destination, {required bool left}) {
  const distanceCalc = Distance();
  final totalKm = distanceCalc.as(LengthUnit.Kilometer, origin, destination);

  final offsetKm = (totalKm * 0.15).clamp(0.5, 3.0);

  final bearing = distanceCalc.bearing(origin, destination);
  final perpendicularBearing = left ? (bearing - 90) : (bearing + 90);

  final midpoint = LatLng(
    (origin.latitude + destination.latitude) / 2,
    (origin.longitude + destination.longitude) / 2,
  );

  return distanceCalc.offset(midpoint, offsetKm * 1000, perpendicularBearing);
}

double _severityWeight(AlertSeverity severity) {
  switch (severity) {
    case AlertSeverity.low:
      return 1;
    case AlertSeverity.medium:
      return 2;
    case AlertSeverity.high:
      return 3;
  }
}

int _computeSafetyScore(List<LatLng> routePoints, List<SafetyAlert> alerts) {
  if (alerts.isEmpty || routePoints.isEmpty) return 100;

  const distanceCalc = Distance();
  const bufferMeters = 300.0;

  final sampleStep = (routePoints.length / 60).ceil().clamp(1, 20);
  final sampled = [
    for (var i = 0; i < routePoints.length; i += sampleStep) routePoints[i],
  ];

  double penalty = 0;
  for (final alert in alerts) {
    for (final point in sampled) {
      if (distanceCalc(point, alert.position) <= bufferMeters) {
        penalty += _severityWeight(alert.severity) * 6;
        break;
      }
    }
  }

  return (100 - penalty).clamp(0, 100).round();
}

Future<List<RouteOption>> fetchRoutes(
    LatLng origin,
    LatLng destination, {
      List<SafetyAlert> alerts = const [],
    }) async {
  final parsed = await _fetchOsrmSingle([origin, destination], alternatives: true);
  if (parsed.isEmpty) {
    throw Exception('No route found');
  }

  if (parsed.length < 3) {
    final leftVia = _detourWaypoint(origin, destination, left: true);
    final rightVia = _detourWaypoint(origin, destination, left: false);

    final detourResults = await Future.wait([
      _fetchOsrmSingle([origin, leftVia, destination]),
      _fetchOsrmSingle([origin, rightVia, destination]),
    ]);

    for (final detour in detourResults) {
      parsed.addAll(detour);
    }
  }

  final scored = parsed
      .map((route) => (
  route: route,
  score: _computeSafetyScore(route.points, alerts),
  ))
      .toList();

  scored.sort((a, b) => b.score.compareTo(a.score));
  final safest = scored.first;

  final afterSafest = scored.length > 1 ? scored.sublist(1) : scored;

  final fastest = afterSafest.reduce(
          (a, b) => a.route.durationMin <= b.route.durationMin ? a : b);

  final afterFastest = afterSafest.length > 1
      ? afterSafest.where((e) => e != fastest).toList()
      : afterSafest;

  final shortest = afterFastest.reduce(
          (a, b) => a.route.distanceKm <= b.route.distanceKm ? a : b);

  return [
    RouteOption(
      label: 'Safest Route',
      distanceKm: safest.route.distanceKm,
      durationMin: safest.route.durationMin,
      safetyScore: safest.score,
      points: safest.route.points,
    ),
    RouteOption(
      label: 'Fastest Route',
      distanceKm: fastest.route.distanceKm,
      durationMin: fastest.route.durationMin,
      safetyScore: fastest.score,
      points: fastest.route.points,
    ),
    RouteOption(
      label: 'Shortest Route',
      distanceKm: shortest.route.distanceKm,
      durationMin: shortest.route.durationMin,
      safetyScore: shortest.score,
      points: shortest.route.points,
    ),
  ];
}