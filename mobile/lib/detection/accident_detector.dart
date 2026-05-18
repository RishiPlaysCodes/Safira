import '../models/trip_sample.dart';

class AccidentDetector {
  AccidentDetector({
    this.impactThresholdG = 3.2,
    this.speedDropThresholdKmh = 25,
    this.lowSpeedThresholdKmh = 5,
    this.signalWindow = const Duration(seconds: 8),
    this.cooldown = const Duration(seconds: 30),
  });

  final double impactThresholdG;
  final double speedDropThresholdKmh;
  final double lowSpeedThresholdKmh;
  final Duration signalWindow;
  final Duration cooldown;

  DateTime? _lastImpactAt;
  DateTime? _lastSpeedDropAt;
  DateTime? _lastAlertAt;
  double _latestImpactG = 0;
  TripSample? _previousSample;

  double get latestImpactG => _latestImpactG;

  void addImpact(double gForce, DateTime now) {
    _latestImpactG = gForce;
    if (gForce >= impactThresholdG) {
      _lastImpactAt = now;
    }
  }

  bool addTripSample(TripSample sample) {
    final previous = _previousSample;
    _previousSample = sample;

    if (previous != null) {
      final speedDrop = previous.speedKmh - sample.speedKmh;
      if (previous.speedKmh >= speedDropThresholdKmh &&
          speedDrop >= speedDropThresholdKmh) {
        _lastSpeedDropAt = sample.recordedAt;
      }
    }

    return _shouldTrigger(sample);
  }

  bool _shouldTrigger(TripSample sample) {
    final now = sample.recordedAt;

    if (_lastAlertAt != null && now.difference(_lastAlertAt!) < cooldown) {
      return false;
    }

    final hasRecentImpact =
        _lastImpactAt != null && now.difference(_lastImpactAt!) <= signalWindow;
    final hasRecentSpeedDrop = _lastSpeedDropAt != null &&
        now.difference(_lastSpeedDropAt!) <= signalWindow;
    final hasLowPostImpactSpeed = sample.speedKmh <= lowSpeedThresholdKmh;

    final shouldTrigger =
        hasRecentImpact && hasRecentSpeedDrop && hasLowPostImpactSpeed;

    if (shouldTrigger) {
      _lastAlertAt = now;
    }

    return shouldTrigger;
  }

  void resetTransientSignals() {
    _lastImpactAt = null;
    _lastSpeedDropAt = null;
  }
}
