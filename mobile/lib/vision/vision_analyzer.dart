import 'vision_inference_result.dart';

abstract class VisionAnalyzer {
  Future<VisionInferenceResult> analyzeHelmet();
  Future<VisionInferenceResult> analyzeRedLight();
  Future<VisionInferenceResult> analyzeTrafficDensity();
}

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

class OnDeviceVisionAnalyzer implements VisionAnalyzer {
  @override
  Future<VisionInferenceResult> analyzeHelmet() async {
    // Replace with TFLite inference once a helmet model is added.
    return const VisionInferenceResult(
      type: 'helmet',
      label: 'unknown',
      confidence: 0,
      modelName: 'helmet_model_pending',
    );
  }

  @override
  Future<VisionInferenceResult> analyzeRedLight() async {
    // Replace with TFLite inference once a red-light model is added.
    return const VisionInferenceResult(
      type: 'red_light',
      label: 'unknown',
      confidence: 0,
      modelName: 'red_light_model_pending',
    );
  }

  @override
  Future<VisionInferenceResult> analyzeTrafficDensity() async {
    // Replace with TFLite inference once a vehicle model is added.
    return const VisionInferenceResult(
      type: 'traffic_density',
      label: 'unknown',
      confidence: 0,
      modelName: 'traffic_model_pending',
    );
  }
}
