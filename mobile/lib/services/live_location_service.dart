import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

/// Live Location Sharing Service
/// Shares real-time location with emergency contacts and backend.
/// Generates a shareable tracking link that guardians can open in browser.
class LiveLocationService {
  LiveLocationService();

  StreamSubscription<Position>? _subscription;
  Timer? _shareTimer;
  bool _isSharing = false;
  String _sessionId = '';
  String _shareableLink = '';

  bool get isSharing => _isSharing;
  String get sessionId => _sessionId;
  String get shareableLink => _shareableLink;

  double _lastLatitude = 0;
  double _lastLongitude = 0;
  double _lastSpeedKmh = 0;
  DateTime _lastUpdate = DateTime.now();

  double get lastLatitude => _lastLatitude;
  double get lastLongitude => _lastLongitude;
  double get lastSpeedKmh => _lastSpeedKmh;

  /// Start sharing live location
  Future<String> startSharing({
    required String backendUrl,
    required String username,
    required String guardianPhone,
  }) async {
    if (_isSharing) return _shareableLink;

    _sessionId = '${username}_${DateTime.now().millisecondsSinceEpoch}';
    _isSharing = true;

    // Generate shareable link
    if (backendUrl.isNotEmpty) {
      _shareableLink = '$backendUrl/alerts/live-track/$_sessionId/';
    } else {
      _shareableLink = 'https://maps.google.com/?q=$_lastLatitude,$_lastLongitude';
    }

    // Start continuous location updates to backend
    _subscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 5,
      ),
    ).listen((position) {
      _lastLatitude = position.latitude;
      _lastLongitude = position.longitude;
      _lastSpeedKmh = (position.speed < 0 ? 0 : position.speed) * 3.6;
      _lastUpdate = DateTime.now();

      _pushLocationToBackend(backendUrl, username);
    });

    // Also push periodically (every 5 seconds even if no movement)
    _shareTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _pushLocationToBackend(backendUrl, username);
    });

    // Initial push
    try {
      final currentPosition = await Geolocator.getCurrentPosition();
      _lastLatitude = currentPosition.latitude;
      _lastLongitude = currentPosition.longitude;
      _lastSpeedKmh = (currentPosition.speed < 0 ? 0 : currentPosition.speed) * 3.6;
      _pushLocationToBackend(backendUrl, username);
    } catch (_) {}

    debugPrint('[LiveLocation] Sharing started: $_shareableLink');
    return _shareableLink;
  }

  /// Stop sharing live location
  Future<void> stopSharing({
    required String backendUrl,
    required String username,
  }) async {
    _isSharing = false;
    _subscription?.cancel();
    _shareTimer?.cancel();

    // Notify backend that sharing stopped
    if (backendUrl.isNotEmpty) {
      final uri = Uri.tryParse('$backendUrl/alerts/api/live-location/');
      if (uri != null) {
        try {
          await http.post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'session_id': _sessionId,
              'status': 'stopped',
              'latitude': _lastLatitude,
              'longitude': _lastLongitude,
            }),
          ).timeout(const Duration(seconds: 3));
        } catch (_) {}
      }
    }

    debugPrint('[LiveLocation] Sharing stopped');
  }

  /// Push current location to backend
  Future<void> _pushLocationToBackend(String backendUrl, String username) async {
    if (backendUrl.isEmpty) return;

    final uri = Uri.tryParse('$backendUrl/alerts/api/live-location/');
    if (uri == null) return;

    try {
      await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'session_id': _sessionId,
          'status': 'active',
          'latitude': _lastLatitude,
          'longitude': _lastLongitude,
          'speed_kmh': _lastSpeedKmh,
          'timestamp': _lastUpdate.toIso8601String(),
        }),
      ).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('[LiveLocation] Push failed: $e');
    }
  }

  /// Generate Google Maps link with current location
  String getGoogleMapsLink() {
    return 'https://maps.google.com/?q=$_lastLatitude,$_lastLongitude';
  }

  /// Generate emergency message with live location
  String getEmergencyMessage({required String riderName}) {
    return 'SafeRide Guardian Emergency Alert!\n'
        'Rider: $riderName\n'
        'Live Location: ${getGoogleMapsLink()}\n'
        'Speed: ${_lastSpeedKmh.toStringAsFixed(1)} km/h\n'
        'Track live: $_shareableLink\n'
        'Time: ${DateTime.now().toString().substring(0, 19)}';
  }

  void dispose() {
    _subscription?.cancel();
    _shareTimer?.cancel();
  }
}
