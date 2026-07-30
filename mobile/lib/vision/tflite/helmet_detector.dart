import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// Result of a single detection from the helmet model.
class DetectionResult {
  const DetectionResult({
    required this.label,
    required this.confidence,
    required this.rect,
  });

  /// 'helmet' or 'no_helmet'
  final String label;

  /// Confidence score 0.0 - 1.0
  final double confidence;

  /// Bounding box in normalized coordinates (0-1 range relative to image).
  final ui.Rect rect;

  @override
  String toString() => '$label (${(confidence * 100).toStringAsFixed(1)}%)';
}

/// Runs YOLOv8n TFLite helmet detection model on camera frames.
///
/// Usage:
/// ```dart
/// final detector = HelmetDetector();
/// await detector.initialize();
/// final results = await detector.detectFromCameraImage(cameraImage);
/// detector.dispose();
/// ```
class HelmetDetector {
  static const String _modelPath = 'assets/models/helmet_detector.tflite';
  static const String _labelsPath = 'assets/models/helmet_labels.txt';

  static const int _inputSize = 320; // Must match training imgsz
  static const double _confidenceThreshold = 0.45;
  static const double _nmsIouThreshold = 0.5;

  Interpreter? _interpreter;
  List<String> _labels = [];
  bool _isReady = false;

  bool get isReady => _isReady;
  List<String> get labels => _labels;

  /// Load the TFLite model and labels. Call once at startup.
  Future<bool> initialize() async {
    try {
      // Load labels
      final labelsData = await rootBundle.loadString(_labelsPath);
      _labels = labelsData
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();

      // Load model with GPU delegate if available, else CPU
      final options = InterpreterOptions()..threads = 4;

      try {
        // Try GPU acceleration (Android)
        final gpuDelegate = GpuDelegateV2();
        options.addDelegate(gpuDelegate);
      } catch (_) {
        // GPU not available, CPU is fine
      }

      _interpreter = await Interpreter.fromAsset(_modelPath, options: options);

      _isReady = true;
      debugPrint('[HelmetDetector] Model loaded. Classes: $_labels');
      return true;
    } catch (e) {
      debugPrint('[HelmetDetector] Failed to load model: $e');
      _isReady = false;
      return false;
    }
  }

  /// Run detection on a CameraImage (YUV420 format from camera plugin).
  /// Returns list of detections above confidence threshold.
  Future<List<DetectionResult>> detectFromCameraImage(CameraImage image) async {
    if (!_isReady || _interpreter == null) return [];

    try {
      final inputData = _preprocessCameraImage(image);
      return _runInference(inputData);
    } catch (e) {
      debugPrint('[HelmetDetector] Inference error: $e');
      return [];
    }
  }

  /// Run detection on raw RGBA bytes (e.g. from an image file).
  Future<List<DetectionResult>> detectFromRgba(
    Uint8List rgbaBytes,
    int width,
    int height,
  ) async {
    if (!_isReady || _interpreter == null) return [];

    try {
      final inputData = _preprocessRgba(rgbaBytes, width, height);
      return _runInference(inputData);
    } catch (e) {
      debugPrint('[HelmetDetector] Inference error: $e');
      return [];
    }
  }

  /// Preprocess a YUV420 camera image to model input tensor.
  Float32List _preprocessCameraImage(CameraImage image) {
    final int imgWidth = image.width;
    final int imgHeight = image.height;

    // YUV420 -> RGB -> resize to 320x320 -> normalize to 0-1
    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;
    final yRowStride = image.planes[0].bytesPerRow;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final inputData = Float32List(1 * _inputSize * _inputSize * 3);
    int idx = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        // Map from input coords to source image coords
        final srcX = (x * imgWidth / _inputSize).round().clamp(0, imgWidth - 1);
        final srcY = (y * imgHeight / _inputSize).round().clamp(0, imgHeight - 1);

        // Get YUV values
        final yValue = yPlane[srcY * yRowStride + srcX];
        final uvX = (srcX / 2).floor();
        final uvY = (srcY / 2).floor();
        final uvIdx = uvY * uvRowStride + uvX * uvPixelStride;

        final uValue = (uvIdx < uPlane.length) ? uPlane[uvIdx] : 128;
        final vValue = (uvIdx < vPlane.length) ? vPlane[uvIdx] : 128;

        // YUV -> RGB
        final r = (yValue + 1.402 * (vValue - 128)).clamp(0, 255).toInt();
        final g = (yValue - 0.344136 * (uValue - 128) - 0.714136 * (vValue - 128))
            .clamp(0, 255)
            .toInt();
        final b = (yValue + 1.772 * (uValue - 128)).clamp(0, 255).toInt();

        // Normalize to 0-1 (YOLOv8 expects this)
        inputData[idx++] = r / 255.0;
        inputData[idx++] = g / 255.0;
        inputData[idx++] = b / 255.0;
      }
    }

    return inputData;
  }

  /// Preprocess RGBA bytes to model input tensor.
  Float32List _preprocessRgba(Uint8List rgbaBytes, int width, int height) {
    final inputData = Float32List(1 * _inputSize * _inputSize * 3);
    int idx = 0;

    for (int y = 0; y < _inputSize; y++) {
      for (int x = 0; x < _inputSize; x++) {
        final srcX = (x * width / _inputSize).round().clamp(0, width - 1);
        final srcY = (y * height / _inputSize).round().clamp(0, height - 1);
        final pixelIdx = (srcY * width + srcX) * 4;

        inputData[idx++] = rgbaBytes[pixelIdx] / 255.0; // R
        inputData[idx++] = rgbaBytes[pixelIdx + 1] / 255.0; // G
        inputData[idx++] = rgbaBytes[pixelIdx + 2] / 255.0; // B
      }
    }

    return inputData;
  }

  /// Run the TFLite model and decode YOLOv8 output.
  List<DetectionResult> _runInference(Float32List inputData) {
    final interpreter = _interpreter!;

    // Reshape input: [1, 320, 320, 3]
    final input = inputData.reshape([1, _inputSize, _inputSize, 3]);

    // YOLOv8 output shape: [1, num_classes+4, num_detections]
    // For 2 classes: [1, 6, 2100] (4 box coords + 2 class scores)
    final outputShape = interpreter.getOutputTensor(0).shape;
    final outputSize = outputShape.reduce((a, b) => a * b);
    final outputBuffer = Float32List(outputSize);
    final output = outputBuffer.reshape(outputShape);

    interpreter.run(input, output);

    // Decode detections
    return _decodeYoloOutput(outputBuffer, outputShape);
  }

  /// Decode YOLOv8 raw output tensor into DetectionResults.
  List<DetectionResult> _decodeYoloOutput(
    Float32List output,
    List<int> shape,
  ) {
    // YOLOv8 output: [1, 4+num_classes, num_boxes]
    // Transposed: each "column" is a detection
    final numClasses = _labels.length;
    final numBoxes = shape.last; // e.g., 2100
    final stride = 4 + numClasses; // 6 for 2 classes

    final List<DetectionResult> rawDetections = [];

    for (int i = 0; i < numBoxes; i++) {
      // Extract box coordinates (cx, cy, w, h normalized)
      final cx = output[0 * numBoxes + i];
      final cy = output[1 * numBoxes + i];
      final w = output[2 * numBoxes + i];
      final h = output[3 * numBoxes + i];

      // Find best class
      double maxScore = 0;
      int bestClass = 0;
      for (int c = 0; c < numClasses; c++) {
        final score = output[(4 + c) * numBoxes + i];
        if (score > maxScore) {
          maxScore = score;
          bestClass = c;
        }
      }

      if (maxScore < _confidenceThreshold) continue;

      // Convert from center format to corner format, clamped to [0, 1]
      final x1 = ((cx - w / 2) / _inputSize).clamp(0.0, 1.0);
      final y1 = ((cy - h / 2) / _inputSize).clamp(0.0, 1.0);
      final x2 = ((cx + w / 2) / _inputSize).clamp(0.0, 1.0);
      final y2 = ((cy + h / 2) / _inputSize).clamp(0.0, 1.0);

      rawDetections.add(DetectionResult(
        label: bestClass < _labels.length ? _labels[bestClass] : 'unknown',
        confidence: maxScore,
        rect: ui.Rect.fromLTRB(x1, y1, x2, y2),
      ));
    }

    // Apply Non-Maximum Suppression
    return _nms(rawDetections);
  }

  /// Non-Maximum Suppression to remove overlapping detections.
  List<DetectionResult> _nms(List<DetectionResult> detections) {
    if (detections.isEmpty) return [];

    // Sort by confidence descending
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));

    final List<DetectionResult> kept = [];
    final List<bool> suppressed = List.filled(detections.length, false);

    for (int i = 0; i < detections.length; i++) {
      if (suppressed[i]) continue;
      kept.add(detections[i]);

      for (int j = i + 1; j < detections.length; j++) {
        if (suppressed[j]) continue;
        if (_iou(detections[i].rect, detections[j].rect) > _nmsIouThreshold) {
          suppressed[j] = true;
        }
      }
    }

    return kept;
  }

  /// Intersection over Union for two rectangles.
  double _iou(ui.Rect a, ui.Rect b) {
    final interLeft = max(a.left, b.left);
    final interTop = max(a.top, b.top);
    final interRight = min(a.right, b.right);
    final interBottom = min(a.bottom, b.bottom);

    if (interRight <= interLeft || interBottom <= interTop) return 0.0;

    final interArea = (interRight - interLeft) * (interBottom - interTop);
    final aArea = a.width * a.height;
    final bArea = b.width * b.height;
    final unionArea = aArea + bArea - interArea;

    return unionArea > 0 ? interArea / unionArea : 0.0;
  }

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isReady = false;
  }
}
