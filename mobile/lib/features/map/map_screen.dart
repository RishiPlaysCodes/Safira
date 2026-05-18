import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
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
      backgroundColor: SafeRideTheme.primaryDark,
      body: Stack(
        children: [
          // Full-screen map
          FlutterMap(
            options: MapOptions(
              initialCenter: current,
              initialZoom: latitude == 0 && longitude == 0 ? 4 : 16,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.saferide.guardian',
              ),
              if (routePoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4,
                      color: SafeRideTheme.accentCyan,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: current,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SafeRideTheme.accentBlue.withValues(alpha: 0.3),
                        border: Border.all(color: SafeRideTheme.accentBlue, width: 2),
                        boxShadow: SafeRideTheme.neonGlow(SafeRideTheme.accentBlue, intensity: 0.3),
                      ),
                      child: const Icon(
                        Icons.my_location,
                        color: SafeRideTheme.accentCyan,
                        size: 24,
                      ),
                    ),
                  ),
                  // Start point marker
                  if (routePoints.isNotEmpty)
                    Marker(
                      point: routePoints.first,
                      width: 30,
                      height: 30,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: SafeRideTheme.neonGreen.withValues(alpha: 0.8),
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(Icons.flag, color: Colors.white, size: 14),
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Top overlay
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: SafeRideTheme.glassCard(opacity: 0.8, borderRadius: 14),
                      child: const Icon(Icons.arrow_back, color: SafeRideTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: SafeRideTheme.glassCard(opacity: 0.8, borderRadius: 14),
                      child: Row(
                        children: [
                          const Icon(Icons.route, color: SafeRideTheme.accentBlue, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Live Ride Map',
                            style: const TextStyle(
                              color: SafeRideTheme.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${routeSamples.length} pts',
                            style: const TextStyle(
                              color: SafeRideTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom info overlay
          if (latitude != 0)
            Positioned(
              bottom: 20,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: SafeRideTheme.glassCard(opacity: 0.85, borderRadius: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _infoItem('LAT', latitude.toStringAsFixed(4), SafeRideTheme.accentBlue),
                    _infoItem('LNG', longitude.toStringAsFixed(4), SafeRideTheme.accentCyan),
                    _infoItem('POINTS', '${routeSamples.length}', SafeRideTheme.neonGreen),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoItem(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(color: SafeRideTheme.textSecondary, fontSize: 10, letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w700)),
      ],
    );
  }
}
