import '../models/trip_sample.dart';
import '../services/api_client.dart';
import '../services/offline_queue_service.dart';

/// Repository for sending trip telemetry data to the backend.
/// Uses token-based authentication and queues failed requests for retry.
class TripRepository {
  TripRepository({
    required this.apiClient,
    OfflineQueueService? queueService,
  }) : _queueService = queueService ?? OfflineQueueService();

  final ApiClient apiClient;
  final OfflineQueueService _queueService;

  /// Send a trip data sample to the backend.
  /// Queues the payload locally if the request fails (offline support).
  Future<ApiResult> sendSample({
    required String backendUrl,
    required TripSample sample,
  }) async {
    if (backendUrl.isEmpty) {
      return ApiResult.error('Backend URL not configured.');
    }

    final payload = {
      ...sample.toJson(),
      'location': '${sample.latitude},${sample.longitude}',
      'latitude': sample.latitude,
      'longitude': sample.longitude,
    };

    final result = await apiClient.postQuick(
      backendUrl,
      '/trips/api/receive/',
      payload,
    );

    if (!result.success) {
      await _queueService.addTrip(payload);
    }

    return result;
  }

  /// Retry sending queued trip samples that failed previously.
  Future<int> syncPending({required String backendUrl}) async {
    if (backendUrl.isEmpty) return 0;

    final pending = await _queueService.loadTrips();
    if (pending.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    int synced = 0;

    for (final payload in pending) {
      final result = await apiClient.postQuick(
        backendUrl,
        '/trips/api/receive/',
        payload,
      );

      if (result.success) {
        synced++;
      } else {
        remaining.add(payload);
      }
    }

    await _queueService.replaceTrips(remaining);
    return synced;
  }

  /// Get trip history for the authenticated user.
  Future<ApiResult> getTripHistory({required String backendUrl}) async {
    return apiClient.get(backendUrl, '/trips/api/history/');
  }

  /// Get weekly safety summary.
  Future<ApiResult> getWeeklySummary({required String backendUrl}) async {
    return apiClient.get(backendUrl, '/trips/api/weekly-summary/');
  }

  /// Get active safety zones (public endpoint).
  Future<ApiResult> getSafetyZones({required String backendUrl}) async {
    return apiClient.get(backendUrl, '/trips/api/zones/');
  }
}
