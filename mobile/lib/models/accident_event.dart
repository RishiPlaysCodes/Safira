import 'trip_sample.dart';

class AccidentEvent {
  const AccidentEvent({
    required this.status,
    required this.impactG,
    required this.sample,
  });

  final String status;
  final double impactG;
  final TripSample sample;

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'impact_g': impactG,
      ...sample.toJson(),
      'location': 'https://maps.google.com/?q=${sample.latitude},${sample.longitude}',
    };
  }
}
