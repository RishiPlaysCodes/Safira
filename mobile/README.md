# SafeRide Guardian — Android-first real-world upgrade

This Flutter app is now organized as a small production-shaped mobile project instead of a single-file prototype.

## Implemented in this upgrade

- Real GPS speed tracking
- Accelerometer-based accident signal input
- Safer accident detection with short rolling windows and cooldown
- Google Maps screen with current marker and route polyline
- Firebase initialization hook for push notification setup
- Android foreground tracking configuration for ride monitoring
- Cleaner separation between UI, services, repositories, models, and detection logic

## Important setup still required

1. Create a Firebase project and add Android config files.
2. Replace `YOUR_GOOGLE_MAPS_API_KEY_HERE` in `android/app/src/main/AndroidManifest.xml`.
3. Enable the Google Maps SDK for Android in Google Cloud.
4. Connect the Django backend endpoints used by the app:
   - `POST /trips/api/receive/`
   - `POST /alerts/api/accident-signal/`
5. Test on a real Android phone. GPS, sensors, maps, and background tracking are not reliable on desktop.

## Code layout

- `lib/features/` — screens and feature controllers
- `lib/services/` — phone integrations such as GPS, sensors, notifications, emergency actions
- `lib/repositories/` — backend and saved settings access
- `lib/models/` — plain data objects
- `lib/detection/` — accident detection rules

## Still recommended for later phases

- Offline queue + retry for trip samples and alerts
- Authenticated backend APIs
- Real FCM token registration with your Django backend
- Full background/terminated-state notification handling
- Crash reporting and analytics
- Automated tests for detector behavior
