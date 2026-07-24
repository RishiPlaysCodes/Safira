import '../services/api_client.dart';

/// Repository for sending vision AI observations to the backend.
/// Uses token-based authentication.
class VisionRepository {
  VisionRepository({required this.apiClient});

  final ApiClient apiClient;

  /// Send a vision observation (helmet detection, red light, traffic density).
  Future<ApiResult> sendObservation({
    required String backendUrl,
    required String type,
    required String label,
    required double confidence,
    required double latitude,
    required double longitude,
    int? tripId,
  }) async {
    if (backendUrl.isEmpty) {
      return ApiResult.error('Backend URL not configured.');
    }

    return apiClient.postQuick(
      backendUrl,
      '/trips/api/vision-observation/',
      {
        'observation_type': type,
        'label': label,
        'confidence': confidence,
        'latitude': latitude,
        'longitude': longitude,
        if (tripId != null) 'trip': tripId,
      },
    );
  }
}
