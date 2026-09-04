import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:mob_ass/map/live_location.dart';
import 'package:mob_ass/routing.dart';

class NavigationPage extends StatelessWidget {
  final RouteOption route;
  final LatLng destination;

  const NavigationPage({
    super.key,
    required this.route,
    required this.destination,
  });

  @override
  Widget build(BuildContext context) {
    final arrivalTime = DateTime.now().add(Duration(minutes: route.durationMin));
    final arrivalLabel = TimeOfDay.fromDateTime(arrivalTime).format(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Navigation'),
      ),
      body: Column(
        children: [
          Expanded(
            child: LiveLocationMap(
              height: null, // fill all space Expanded gives it
              borderRadius: 0,
              interactive: true,
              polylines: [
                Polyline(
                  points: route.points,
                  strokeWidth: 6,
                  color: Colors.green,
                ),
              ],
              extraMarkers: [
                Marker(
                  point: destination,
                  width: 34,
                  height: 34,
                  child: const Icon(Icons.location_on, color: Colors.red, size: 34),
                ),
              ],
            ),
          ),

          // Fixed bottom bar: ETA, distance, predicted arrival clock time.
          SafeArea(
            top: false,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, -2)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStat('${route.durationMin} mins', 'ETA'),
                  _buildStat('${route.distanceKm.toStringAsFixed(1)} km', 'Distance'),
                  _buildStat(arrivalLabel, 'Arrive by'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}