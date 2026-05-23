import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Real-time traffic detection service.
/// Uses OpenStreetMap Overpass API (free) to detect nearby road features
/// and speed-based congestion analysis.
class TrafficService {
  TrafficService();

  TrafficLevel _currentLevel = TrafficLevel.unknown;
  TrafficLevel get currentLevel => _currentLevel;

  String _congestionReason = '';
  String get congestionReason => _congestionReason;

  /// Analyze traffic based on current speed vs expected speed
  TrafficAssessment assessTraffic({
    required double currentSpeedKmh,
    required double expectedSpeedKmh,
    required double latitude,
    required double longitude,
  }) {
    if (currentSpeedKmh <= 0) {
      return TrafficAssessment(
        level: TrafficLevel.unknown,
        congestionPercent: 0,
        reason: 'Vehicle stationary',
      );
    }

    final speedRatio = currentSpeedKmh / expectedSpeedKmh;

    TrafficLevel level;
    String reason;

    if (speedRatio >= 0.8) {
      level = TrafficLevel.free;
      reason = 'Traffic flowing freely';
    } else if (speedRatio >= 0.5) {
      level = TrafficLevel.moderate;
      reason = 'Moderate traffic — speed reduced';
    } else if (speedRatio >= 0.25) {
      level = TrafficLevel.heavy;
      reason = 'Heavy traffic detected';
    } else {
      level = TrafficLevel.severe;
      reason = 'Severe congestion — near standstill';
    }

    _currentLevel = level;
    _congestionReason = reason;

    return TrafficAssessment(
      level: level,
      congestionPercent: ((1 - speedRatio) * 100).clamp(0, 100).round(),
      reason: reason,
    );
  }

  /// Query nearby road features from Overpass API (schools, hospitals, etc.)
  Future<List<NearbyPlace>> getNearbyPlaces({
    required double latitude,
    required double longitude,
    int radiusMeters = 500,
  }) async {
    final places = <NearbyPlace>[];

    try {
      // Query Overpass API for nearby amenities
      final query = '''
[out:json][timeout:5];
(
  node["amenity"="school"](around:$radiusMeters,$latitude,$longitude);
  node["amenity"="hospital"](around:$radiusMeters,$latitude,$longitude);
  node["amenity"="clinic"](around:$radiusMeters,$latitude,$longitude);
  node["highway"="traffic_signals"](around:200,$latitude,$longitude);
);
out body;
''';

      final response = await http.post(
        Uri.parse('https://overpass-api.de/api/interpreter'),
        body: {'data': query},
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final elements = data['elements'] as List? ?? [];

        for (final element in elements) {
          final tags = element['tags'] as Map<String, dynamic>? ?? {};
          final amenity = tags['amenity'] ?? tags['highway'] ?? 'unknown';
          final name = tags['name'] ?? amenity;

          places.add(NearbyPlace(
            name: name.toString(),
            type: amenity.toString(),
            latitude: (element['lat'] as num).toDouble(),
            longitude: (element['lon'] as num).toDouble(),
          ));
        }
      }
    } catch (e) {
      debugPrint('[TrafficService] Overpass query failed: $e');
    }

    return places;
  }

  /// Get recommended speed limit based on nearby zones
  double getRecommendedSpeedLimit(List<NearbyPlace> nearbyPlaces) {
    for (final place in nearbyPlaces) {
      if (place.type == 'school') return 20.0;
      if (place.type == 'hospital' || place.type == 'clinic') return 25.0;
      if (place.type == 'traffic_signals') return 30.0;
    }
    return 40.0; // Default speed limit
  }
}

enum TrafficLevel {
  unknown,
  free,
  moderate,
  heavy,
  severe,
}

class TrafficAssessment {
  const TrafficAssessment({
    required this.level,
    required this.congestionPercent,
    required this.reason,
  });

  final TrafficLevel level;
  final int congestionPercent;
  final String reason;
}

class NearbyPlace {
  const NearbyPlace({
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String type;
  final double latitude;
  final double longitude;
}
