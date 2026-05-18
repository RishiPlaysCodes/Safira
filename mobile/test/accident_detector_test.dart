import 'package:flutter_test/flutter_test.dart';
import 'package:saferide_mobile/detection/accident_detector.dart';
import 'package:saferide_mobile/models/trip_sample.dart';

void main() {
  test('requires recent impact, speed drop, and low speed together', () {
    final detector = AccidentDetector();
    final start = DateTime(2026, 5, 15, 10);

    detector.addImpact(3.5, start);
    detector.addTripSample(
      TripSample(
        latitude: 0,
        longitude: 0,
        speedKmh: 45,
        recordedAt: start,
      ),
    );

    final triggered = detector.addTripSample(
      TripSample(
        latitude: 0,
        longitude: 0,
        speedKmh: 3,
        recordedAt: start.add(const Duration(seconds: 2)),
      ),
    );

    expect(triggered, isTrue);
  });

  test('does not reuse stale speed-drop evidence forever', () {
    final detector = AccidentDetector();
    final start = DateTime(2026, 5, 15, 10);

    detector.addTripSample(
      TripSample(
        latitude: 0,
        longitude: 0,
        speedKmh: 45,
        recordedAt: start,
      ),
    );
    detector.addTripSample(
      TripSample(
        latitude: 0,
        longitude: 0,
        speedKmh: 3,
        recordedAt: start.add(const Duration(seconds: 2)),
      ),
    );
    detector.addImpact(3.5, start.add(const Duration(seconds: 20)));

    final triggered = detector.addTripSample(
      TripSample(
        latitude: 0,
        longitude: 0,
        speedKmh: 2,
        recordedAt: start.add(const Duration(seconds: 21)),
      ),
    );

    expect(triggered, isFalse);
  });
}
