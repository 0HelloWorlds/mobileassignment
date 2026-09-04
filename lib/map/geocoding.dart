import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

Future<String?> reverseGeocode(LatLng position) async {
  final uri = Uri.parse(
    'https://nominatim.openstreetmap.org/reverse'
        '?format=json'
        '&lat=${position.latitude}'
        '&lon=${position.longitude}'
        '&zoom=14'
        '&addressdetails=1',
  );

  try {
    final response = await http.get(
      uri,
      headers: {'User-Agent': 'com.example.mob_ass (Safe Route Planner)'},
    );

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final address = data['address'] as Map<String, dynamic>?;
    if (address == null) return data['display_name'] as String?;

    final area = address['suburb'] ??
        address['neighbourhood'] ??
        address['town'] ??
        address['village'];
    final city = address['city'] ?? address['state'];

    if (area != null && city != null) return '$area, $city';
    return (area ?? city ?? data['display_name']) as String?;
  } catch (_) {
    return null;
  }
}