import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Detects whether the user is driving based on speed patterns.
/// Uses GPS speed to infer driving activity without requiring
/// Google Activity Recognition API (works on all devices).
class ActivityRecognitionService {
  ActivityRecognitionService({
    this.drivingSpeedThresholdKmh = 12.0,
    this.stoppedSpeedThresholdKmh = 3.0,
    this.confirmationDuration = const Duration(seconds: 8),
    this.stopConfirmationDuration = const Duration(seconds: 60),
  });

  final double drivingSpeedThresholdKmh;
  final double stoppedSpeedThresholdKmh;
  final Duration confirmationDuration;
  final Duration stopConfirmationDuration;

  final StreamController<ActivityState> _controller =
      StreamController<ActivityState>.broadcast();

  Stream<ActivityState> get activityStream => _controller.stream;

  StreamSubscription<Position>? _positionSubscription;
  Timer? _confirmationTimer;
  Timer? _stopTimer;

  ActivityState _currentState = ActivityState.stationary;
  ActivityState get currentState => _currentState;

  int _consecutiveDrivingSamples = 0;
  int _consecutiveStoppedSamples = 0;

  static const int _samplesNeededToDrive = 3;
  static const int _samplesNeededToStop = 10;

  void startMonitoring() {
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
      ),
    ).listen(_onPosition);
  }

  void _onPosition(Position position) {
    final speedKmh = (position.speed < 0 ? 0 : position.speed) * 3.6;

    if (speedKmh >= drivingSpeedThresholdKmh) {
      _consecutiveDrivingSamples++;
      _consecutiveStoppedSamples = 0;

      if (_consecutiveDrivingSamples >= _samplesNeededToDrive &&
          _currentState != ActivityState.driving) {
        _currentState = ActivityState.driving;
        _controller.add(ActivityState.driving);
        _stopTimer?.cancel();
        debugPrint('[ActivityRecognition] Driving detected at ${speedKmh.toStringAsFixed(1)} km/h');
      }
    } else if (speedKmh <= stoppedSpeedThresholdKmh) {
      _consecutiveStoppedSamples++;
      _consecutiveDrivingSamples = 0;

      if (_consecutiveStoppedSamples >= _samplesNeededToStop &&
          _currentState == ActivityState.driving) {
        _currentState = ActivityState.stationary;
        _controller.add(ActivityState.stationary);
        debugPrint('[ActivityRecognition] Stopped — vehicle parked');
      }
    } else {
      // In-between speed — could be walking or slow traffic
      _consecutiveDrivingSamples = 0;
      _consecutiveStoppedSamples = 0;
    }
  }

  void stopMonitoring() {
    _positionSubscription?.cancel();
    _confirmationTimer?.cancel();
    _stopTimer?.cancel();
    _currentState = ActivityState.stationary;
  }

  void dispose() {
    stopMonitoring();
    _controller.close();
  }
}

enum ActivityState {
  stationary,
  driving,
  walking,
}
