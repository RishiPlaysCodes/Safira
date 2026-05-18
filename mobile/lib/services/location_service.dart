import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  Future<bool> ensurePermissions() async {
    final location = await Permission.location.request();
    if (!location.isGranted) return false;

    if (defaultTargetPlatform == TargetPlatform.android) {
      await Permission.locationAlways.request();
    }

    return true;
  }

  Stream<Position> positionStream() {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.bestForNavigation,
          distanceFilter: 2,
          foregroundNotificationConfig: const ForegroundNotificationConfig(
            notificationTitle: 'SafeRide tracking active',
            notificationText: 'Monitoring speed and ride safety in the background',
            enableWakeLock: true,
          ),
        ),
      );
    }

    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.bestForNavigation,
        distanceFilter: 2,
      ),
    );
  }
}
