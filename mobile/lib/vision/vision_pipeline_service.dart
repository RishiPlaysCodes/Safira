import '../repositories/vision_repository.dart';
import '../services/api_client.dart';
import 'vision_analyzer.dart';

/// Runs a vision analyzer (manual or on-device) and reports the result to the
/// backend using token-authenticated requests.
class VisionPipelineService {
  VisionPipelineService({
    required ApiClient apiClient,
    VisionAnalyzer? analyzer,
    VisionRepository? repository,
  })  : _analyzer = analyzer ?? _defaultAnalyzer(),
        _repository = repository ?? VisionRepository(apiClient: apiClient);

  static VisionAnalyzer _defaultAnalyzer() {
    const mode = String.fromEnvironment('VISION_MODE', defaultValue: 'manual');
    return mode == 'on_device'
        ? OnDeviceVisionAnalyzer()
        : ManualVisionAnalyzer();
  }

  final VisionAnalyzer _analyzer;
  final VisionRepository _repository;

  Future<void> reportHelmet({
    required String backendUrl,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _analyzer.analyzeHelmet();
    await _send(result.type, result.label, result.confidence, backendUrl,
        latitude, longitude);
  }

  Future<void> reportRedLight({
    required String backendUrl,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _analyzer.analyzeRedLight();
    await _send(result.type, result.label, result.confidence, backendUrl,
        latitude, longitude);
  }

  Future<void> reportTrafficDensity({
    required String backendUrl,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _analyzer.analyzeTrafficDensity();
    await _send(result.type, result.label, result.confidence, backendUrl,
        latitude, longitude);
  }

  Future<void> _send(String type, String label, double confidence,
      String backendUrl, double latitude, double longitude) {
    return _repository.sendObservation(
      backendUrl: backendUrl,
      type: type,
      label: label,
      confidence: confidence,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
