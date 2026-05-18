import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/accident_event.dart';
import '../services/offline_queue_service.dart';

class AlertRepository {
  AlertRepository({OfflineQueueService? queueService})
      : _queueService = queueService ?? OfflineQueueService();

  final OfflineQueueService _queueService;

  Future<void> sendEvent({
    required String backendUrl,
    required String username,
    required AccidentEvent event,
  }) async {
    if (backendUrl.isEmpty) return;

    final uri = Uri.tryParse('$backendUrl/alerts/api/accident-signal/');
    if (uri == null) return;

    final payload = {
      'username': username,
      ...event.toJson(),
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
      await _queueService.addAlert(payload);
    }
  }

  Future<void> syncPending({required String backendUrl}) async {
    if (backendUrl.isEmpty) return;
    final uri = Uri.tryParse('$backendUrl/alerts/api/accident-signal/');
    if (uri == null) return;

    final pending = await _queueService.loadAlerts();
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

    await _queueService.replaceAlerts(remaining);
  }
}
