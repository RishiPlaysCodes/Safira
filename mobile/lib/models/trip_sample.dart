class TripSample {
  const TripSample({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.recordedAt,
    this.destination = '',
  });

  final double latitude;
  final double longitude;
  final double speedKmh;
  final DateTime recordedAt;
  final String destination;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speedKmh.round(),
      'recorded_at': recordedAt.toIso8601String(),
      'destination': destination,
    };
  }
}
