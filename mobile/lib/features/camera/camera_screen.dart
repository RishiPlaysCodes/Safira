import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../vision/on_device_analyzer.dart';
import '../../vision/tflite/helmet_detector.dart';

/// Live camera screen with real-time helmet detection overlay.
/// Shows bounding boxes around detected helmets/no-helmets and a status banner.
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key, this.onHelmetViolation});

  /// Callback fired when a confident "no_helmet" detection is made.
  /// The parent can use this to trigger guardian alerts.
  final VoidCallback? onHelmetViolation;

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  final OnDeviceAnalyzer _analyzer = OnDeviceAnalyzer();

  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _modelLoaded = false;
  String _statusText = 'Initializing camera...';
  Color _statusColor = Colors.grey;
  List<DetectionResult> _detections = [];
  int _frameCount = 0;
  DateTime? _lastViolationTime;

  // Process every Nth frame to avoid overloading (adjust for phone speed)
  static const int _processEveryNFrames = 3;
  // Minimum seconds between violation callbacks
  static const int _violationCooldownSeconds = 30;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _analyzer.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      controller.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _statusText = 'No camera available';
          _statusColor = Colors.red;
        });
        return;
      }

      // Prefer back camera for rider-facing detection
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        camera,
        ResolutionPreset.medium, // Balance between quality and speed
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Load the ML model
      _modelLoaded = await _analyzer.initialize();

      if (!_modelLoaded) {
        setState(() {
          _statusText = 'Model not found. Add helmet_detector.tflite to assets.';
          _statusColor = Colors.orange;
        });
      }

      // Start processing camera frames
      await _cameraController!.startImageStream(_onCameraFrame);

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _statusText = _modelLoaded ? 'Scanning for helmet...' : 'Camera ready (no model)';
          _statusColor = _modelLoaded ? Colors.blue : Colors.orange;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _statusText = 'Camera error: ${e.toString().split('\n').first}';
          _statusColor = Colors.red;
        });
      }
    }
  }

  void _onCameraFrame(CameraImage image) {
    _frameCount++;
    // Skip frames to maintain smooth UI
    if (_isProcessing || _frameCount % _processEveryNFrames != 0) return;
    if (!_modelLoaded) return;

    _isProcessing = true;
    _processFrame(image).then((_) {
      _isProcessing = false;
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    final result = await _analyzer.analyzeFrame(image);
    final detections = _analyzer.lastDetections;

    if (!mounted) return;

    setState(() {
      _detections = detections;

      if (result.label == 'not_worn' && result.confidence >= 0.6) {
        _statusText = 'NO HELMET DETECTED (${(result.confidence * 100).toStringAsFixed(0)}%)';
        _statusColor = Colors.red;
        _triggerViolation();
      } else if (result.label == 'worn' && result.confidence >= 0.6) {
        _statusText = 'Helmet detected (${(result.confidence * 100).toStringAsFixed(0)}%)';
        _statusColor = Colors.green;
      } else {
        _statusText = 'Scanning...';
        _statusColor = Colors.blue;
      }
    });
  }

  void _triggerViolation() {
    final now = DateTime.now();
    if (_lastViolationTime != null &&
        now.difference(_lastViolationTime!).inSeconds < _violationCooldownSeconds) {
      return; // Cooldown active
    }
    _lastViolationTime = now;
    widget.onHelmetViolation?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Helmet Detection'),
        backgroundColor: _statusColor.withValues(alpha: 0.8),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Camera preview
          if (_isInitialized && _cameraController != null)
            CameraPreview(_cameraController!)
          else
            const Center(child: CircularProgressIndicator()),

          // Detection bounding boxes overlay
          if (_isInitialized)
            CustomPaint(
              painter: _DetectionOverlayPainter(detections: _detections),
            ),

          // Status banner at bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    _statusColor.withValues(alpha: 0.9),
                    _statusColor.withValues(alpha: 0.0),
                  ],
                ),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _statusText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _modelLoaded
                          ? '${_detections.length} detection(s) • Processing every ${_processEveryNFrames}rd frame'
                          : 'Train the model first (see HELMET_TRAINING_GUIDE.md)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // "No helmet" full-screen flash warning
          if (_statusColor == Colors.red)
            Positioned.fill(
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 6),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Paints bounding boxes and labels over the camera preview.
class _DetectionOverlayPainter extends CustomPainter {
  _DetectionOverlayPainter({required this.detections});

  final List<DetectionResult> detections;

  @override
  void paint(Canvas canvas, Size size) {
    for (final detection in detections) {
      final color = detection.label == 'no_helmet' ? Colors.red : Colors.green;

      // Scale normalized rect to canvas size
      final rect = Rect.fromLTRB(
        detection.rect.left * size.width,
        detection.rect.top * size.height,
        detection.rect.right * size.width,
        detection.rect.bottom * size.height,
      );

      // Draw box
      final boxPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0;
      canvas.drawRect(rect, boxPaint);

      // Draw label background
      final labelText = '${detection.label} ${(detection.confidence * 100).toStringAsFixed(0)}%';
      final textSpan = TextSpan(
        text: labelText,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final bgRect = Rect.fromLTWH(
        rect.left,
        rect.top - textPainter.height - 4,
        textPainter.width + 8,
        textPainter.height + 4,
      );
      canvas.drawRect(bgRect, Paint()..color = color.withValues(alpha: 0.8));
      textPainter.paint(canvas, Offset(rect.left + 4, rect.top - textPainter.height - 2));
    }
  }

  @override
  bool shouldRepaint(_DetectionOverlayPainter oldDelegate) =>
      detections != oldDelegate.detections;
}
