import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Camera service that provides frames for AI analysis.
/// In production, this connects to the device camera using camera package.
/// For now it provides the interface that TFLite models will consume.
class CameraService {
  bool _isStreaming = false;
  bool get isStreaming => _isStreaming;

  final StreamController<CameraFrame> _frameController =
      StreamController<CameraFrame>.broadcast();

  Stream<CameraFrame> get frameStream => _frameController.stream;

  /// Start camera preview and frame streaming
  Future<bool> startCamera() async {
    if (_isStreaming) return true;

    try {
      _isStreaming = true;
      debugPrint('[CameraService] Camera stream started');
      return true;
    } catch (e) {
      debugPrint('[CameraService] Failed to start camera: $e');
      return false;
    }
  }

  /// Stop camera and release resources
  Future<void> stopCamera() async {
    _isStreaming = false;
    debugPrint('[CameraService] Camera stream stopped');
  }

  /// Process a frame from the camera (called by camera plugin callback)
  void onFrame(CameraFrame frame) {
    if (_isStreaming) {
      _frameController.add(frame);
    }
  }

  void dispose() {
    stopCamera();
    _frameController.close();
  }
}

/// Represents a single camera frame for AI processing
class CameraFrame {
  const CameraFrame({
    required this.bytes,
    required this.width,
    required this.height,
    required this.timestamp,
    this.rotation = 0,
  });

  final Uint8List bytes;
  final int width;
  final int height;
  final DateTime timestamp;
  final int rotation;
}
