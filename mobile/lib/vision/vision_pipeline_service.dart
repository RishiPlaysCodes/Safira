import '../repositories/vision_repository.dart';
import 'vision_analyzer.dart';

class VisionPipelineService {
  VisionPipelineService({
    VisionAnalyzer? analyzer,
    VisionRepository? repository,
  })  : _analyzer = analyzer ?? _defaultAnalyzer(),
        _repository = repository ?? VisionRepository();

  static VisionAnalyzer _defaultAnalyzer() {
    const mode = String.fromEnvironment('VISION_MODE', defaultValue: 'manual');
    return mode == 'on_device' ? OnDeviceVisionAnalyzer() : ManualVisionAnalyzer();
  }

  final VisionAnalyzer _analyzer;
  final VisionRepository _repository;

  Future<void> reportHelmet({
    required String backendUrl,
    required String username,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _analyzer.analyzeHelmet();
    await _send(result.type, result.label, result.confidence, backendUrl, username, latitude, longitude);
  }

  Future<void> reportRedLight({
    required String backendUrl,
    required String username,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _analyzer.analyzeRedLight();
    await _send(result.type, result.label, result.confidence, backendUrl, username, latitude, longitude);
  }

  Future<void> reportTrafficDensity({
    required String backendUrl,
    required String username,
    required double latitude,
    required double longitude,
  }) async {
    final result = await _analyzer.analyzeTrafficDensity();
    await _send(result.type, result.label, result.confidence, backendUrl, username, latitude, longitude);
  }

  Future<void> _send(String type, String label, double confidence, String backendUrl, String username, double latitude, double longitude) {
    return _repository.sendObservation(
      backendUrl: backendUrl,
      username: username,
      type: type,
      label: label,
      confidence: confidence,
      latitude: latitude,
      longitude: longitude,
    );
  }
}

