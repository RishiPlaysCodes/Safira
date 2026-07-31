import '../models/accident_event.dart';
import '../services/api_client.dart';
import '../services/offline_queue_service.dart';

/// Repository for sending accident/emergency alerts to the backend.
/// Uses token-based authentication and queues failed requests for retry.
class AlertRepository {
  AlertRepository({
    required this.apiClient,
    OfflineQueueService? queueService,
  }) : _queueService = queueService ?? OfflineQueueService();

  final ApiClient apiClient;
  final OfflineQueueService _queueService;

  /// Send an accident event to the backend.
  /// Queues the payload locally if the request fails (offline support).
  Future<ApiResult> sendEvent({
    required String backendUrl,
    required AccidentEvent event,
  }) async {
    if (backendUrl.isEmpty) {
      return ApiResult.error('Backend URL not configured.');
    }

    final payload = event.toJson();
    final result = await apiClient.postQuick(
      backendUrl,
      '/alerts/api/accident-signal/',
      payload,
    );

    if (!result.success) {
      // Queue for later sync if network failed
      await _queueService.addAlert(payload);
    }

    return result;
  }

  /// Retry sending queued alerts that failed previously.
  Future<int> syncPending({required String backendUrl}) async {
    if (backendUrl.isEmpty) return 0;

    final pending = await _queueService.loadAlerts();
    if (pending.isEmpty) return 0;

    final remaining = <Map<String, dynamic>>[];
    int synced = 0;

    for (final payload in pending) {
      final result = await apiClient.postQuick(
        backendUrl,
        '/alerts/api/accident-signal/',
        payload,
      );

      if (result.success) {
        synced++;
      } else {
        remaining.add(payload);
      }
    }

    await _queueService.replaceAlerts(remaining);
    return synced;
  }

  /// Register device for push notifications.
  Future<ApiResult> registerDevice({
    required String backendUrl,
    required String fcmToken,
    String platform = 'android',
  }) async {
    return apiClient.post(
      backendUrl,
      '/alerts/api/register-device/',
      {'token': fcmToken, 'platform': platform},
    );
  }

  /// Get alert history for the authenticated user.
  Future<ApiResult> getAlertHistory({required String backendUrl}) async {
    return apiClient.get(backendUrl, '/alerts/api/history/');
  }
}
