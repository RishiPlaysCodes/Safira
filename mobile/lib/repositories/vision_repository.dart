import 'dart:convert';

import 'package:http/http.dart' as http;

class VisionRepository {
  Future<void> sendObservation({
    required String backendUrl,
    required String username,
    required String type,
    required String label,
    required double confidence,
    required double latitude,
    required double longitude,
  }) async {
    if (backendUrl.isEmpty) return;
    final uri = Uri.tryParse('$backendUrl/trips/api/vision-observation/');
    if (uri == null) return;

    await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'username': username,
            'observation_type': type,
            'label': label,
            'confidence': confidence,
            'latitude': latitude,
            'longitude': longitude,
          }),
        )
        .timeout(const Duration(seconds: 3));
  }
}
