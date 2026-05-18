import 'dart:math';

import 'package:sensors_plus/sensors_plus.dart';

class SensorService {
  Stream<double> impactStream() {
    return accelerometerEventStream().map((event) {
      return sqrt(event.x * event.x + event.y * event.y + event.z * event.z) /
          9.81;
    });
  }
}
