import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class EmergencyLocationMapPage extends StatelessWidget {
  final double latitude;
  final double longitude;
  final String? address;

  const EmergencyLocationMapPage({
    super.key,
    required this.latitude,
    required this.longitude,
    this.address,
  });

  @override
  Widget build(BuildContext context) {
    final location = LatLng(latitude, longitude);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Emergency Location'),
      ),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: location,
          initialZoom: 16,
          interactionOptions: const InteractionOptions(
            flags: InteractiveFlag.all,
          ),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.mob_ass',
          ),
          MarkerLayer(
            markers: [
              Marker(
                point: location,
                width: 50,
                height: 50,
                child: const Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 45,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}