import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/trip_sample.dart';
import '../services/offline_queue_service.dart';

class TripRepository {
  TripRepository({OfflineQueueService? queueService})
      : _queueService = queueService ?? OfflineQueueService();

  final OfflineQueueService _queueService;

  Future<void> sendSample({
    required String backendUrl,
    required String username,
    required TripSample sample,
  }) async {
    if (backendUrl.isEmpty) return;

    final uri = Uri.tryParse('$backendUrl/trips/api/receive/');
    if (uri == null) return;

    final payload = {
      'username': username,
      ...sample.toJson(),
      'location': '${sample.latitude},${sample.longitude}',
    };

    try {
      await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      await _queueService.addTrip(payload);
    }
  }

  Future<void> syncPending({required String backendUrl}) async {
    if (backendUrl.isEmpty) return;
    final uri = Uri.tryParse('$backendUrl/trips/api/receive/');
    if (uri == null) return;

    final pending = await _queueService.loadTrips();
    final remaining = <Map<String, dynamic>>[];

    for (final payload in pending) {
      try {
        await http
            .post(
              uri,
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(payload),
            )
            .timeout(const Duration(seconds: 3));
      } catch (_) {
        remaining.add(payload);
      }
    }

    await _queueService.replaceTrips(remaining);
  }
}
