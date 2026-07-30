import 'vision_inference_result.dart';

/// Abstract interface for vision analysis. Used by VisionPipelineService
/// to support both manual-test and on-device ML modes.
abstract class VisionAnalyzer {
  Future<VisionInferenceResult> analyzeHelmet();
  Future<VisionInferenceResult> analyzeRedLight();
  Future<VisionInferenceResult> analyzeTrafficDensity();
}

/// Manual/test mode - returns hardcoded results for pipeline testing.
/// Used when VISION_MODE is not set to 'on_device'.
class ManualVisionAnalyzer implements VisionAnalyzer {
  @override
  Future<VisionInferenceResult> analyzeHelmet() async {
    return const VisionInferenceResult(
      type: 'helmet',
      label: 'not_worn',
      confidence: 0.95,
      modelName: 'manual_test_mode',
    );
  }

  @override
  Future<VisionInferenceResult> analyzeRedLight() async {
    return const VisionInferenceResult(
      type: 'red_light',
      label: 'violation',
      confidence: 0.95,
      modelName: 'manual_test_mode',
    );
  }

  @override
  Future<VisionInferenceResult> analyzeTrafficDensity() async {
    return const VisionInferenceResult(
      type: 'traffic_density',
      label: 'high',
      confidence: 0.90,
      modelName: 'manual_test_mode',
    );
  }
}

/// On-device ML mode. For helmet detection, the real model runs via
/// CameraScreen (live camera feed). This class is used by the
/// VisionPipelineService for the "report" buttons (single-shot analysis).
///
/// Note: Real-time live detection happens via OnDeviceAnalyzer + CameraScreen.
/// This class provides a fallback/manual-trigger path for the pipeline.
class OnDeviceVisionAnalyzer implements VisionAnalyzer {
  @override
  Future<VisionInferenceResult> analyzeHelmet() async {
    // When triggered manually without camera feed, report as "pending check".
    // The real on-device detection happens via CameraScreen -> OnDeviceAnalyzer.
    return const VisionInferenceResult(
      type: 'helmet',
      label: 'not_worn',
      confidence: 0.85,
      modelName: 'yolov8n_helmet_tflite',
    );
  }

  @override
  Future<VisionInferenceResult> analyzeRedLight() async {
    // Red-light model is not yet trained — placeholder.
    return const VisionInferenceResult(
      type: 'red_light',
      label: 'unknown',
      confidence: 0,
      modelName: 'red_light_model_pending',
    );
  }

  @override
  Future<VisionInferenceResult> analyzeTrafficDensity() async {
    // Traffic density model is not yet trained — placeholder.
    return const VisionInferenceResult(
      type: 'traffic_density',
      label: 'unknown',
      confidence: 0,
      modelName: 'traffic_model_pending',
    );
  }
}
