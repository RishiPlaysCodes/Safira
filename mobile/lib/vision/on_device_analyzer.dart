import 'package:camera/camera.dart';

import 'tflite/helmet_detector.dart';
import 'vision_inference_result.dart';

/// On-device vision analyzer using TFLite. Provides real-time helmet detection
/// without any network connection. The model runs entirely on the phone's CPU/GPU.
///
/// Lifecycle:
/// 1. Call [initialize] once at startup.
/// 2. Call [analyzeFrame] on each camera frame during a ride.
/// 3. Call [dispose] when done.
class OnDeviceAnalyzer {
  OnDeviceAnalyzer();

  final HelmetDetector _helmetDetector = HelmetDetector();

  bool _initialized = false;
  bool get isReady => _initialized && _helmetDetector.isReady;

  /// The most recent detection results (useful for UI overlays).
  List<DetectionResult> lastDetections = [];

  /// Initialize the TFLite model. Returns false if model file is missing.
  Future<bool> initialize() async {
    _initialized = await _helmetDetector.initialize();
    return _initialized;
  }

  /// Run helmet detection on a camera frame.
  /// Returns a [VisionInferenceResult] summarizing what was found.
  ///
  /// Logic:
  /// - If any `no_helmet` detection with confidence >= 0.6 → reports 'not_worn'
  /// - If any `helmet` detection with confidence >= 0.6 → reports 'worn'
  /// - Otherwise → reports 'unknown' (e.g., no person in frame)
  Future<VisionInferenceResult> analyzeFrame(CameraImage image) async {
    if (!isReady) {
      return const VisionInferenceResult(
        type: 'helmet',
        label: 'unknown',
        confidence: 0,
        modelName: 'model_not_loaded',
      );
    }

    final detections = await _helmetDetector.detectFromCameraImage(image);
    lastDetections = detections;

    // Find the highest-confidence detection
    DetectionResult? bestNoHelmet;
    DetectionResult? bestHelmet;

    for (final d in detections) {
      if (d.label == 'no_helmet' && d.confidence >= 0.6) {
        if (bestNoHelmet == null || d.confidence > bestNoHelmet.confidence) {
          bestNoHelmet = d;
        }
      } else if (d.label == 'helmet' && d.confidence >= 0.6) {
        if (bestHelmet == null || d.confidence > bestHelmet.confidence) {
          bestHelmet = d;
        }
      }
    }

    // Priority: no_helmet is more critical to report
    if (bestNoHelmet != null) {
      return VisionInferenceResult(
        type: 'helmet',
        label: 'not_worn',
        confidence: bestNoHelmet.confidence,
        modelName: 'yolov8n_helmet_tflite',
      );
    }

    if (bestHelmet != null) {
      return VisionInferenceResult(
        type: 'helmet',
        label: 'worn',
        confidence: bestHelmet.confidence,
        modelName: 'yolov8n_helmet_tflite',
      );
    }

    return const VisionInferenceResult(
      type: 'helmet',
      label: 'unknown',
      confidence: 0,
      modelName: 'yolov8n_helmet_tflite',
    );
  }

  void dispose() {
    _helmetDetector.dispose();
    _initialized = false;
  }
}
