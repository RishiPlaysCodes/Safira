import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/trip_sample.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.routeSamples,
  });

  final double latitude;
  final double longitude;
  final List<TripSample> routeSamples;

  @override
  Widget build(BuildContext context) {
    final current = latitude == 0 && longitude == 0
        ? const LatLng(20.5937, 78.9629)
        : LatLng(latitude, longitude);

    final routePoints = routeSamples
        .map((sample) => LatLng(sample.latitude, sample.longitude))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Live Ride Map')),
      body: FlutterMap(
        options: MapOptions(
          initialCenter: current,
          initialZoom: latitude == 0 && longitude == 0 ? 4 : 16,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.example.saferide_mobile',
          ),
          if (routePoints.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(
                  points: routePoints,
                  strokeWidth: 5,
                  color: Colors.blue,
                ),
              ],
            ),
          MarkerLayer(
            markers: [
              Marker(
                point: current,
                width: 44,
                height: 44,
                child: const Icon(
                  Icons.location_pin,
                  color: Colors.red,
                  size: 44,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
