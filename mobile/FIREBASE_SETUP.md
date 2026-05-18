# Firebase setup for SafeRide Guardian

The Flutter code is already prepared for Firebase Cloud Messaging. You now only need to connect your own Firebase project.

## What to do

1. Create a Firebase project.
2. Register an Android app in that project using your Android package name.
3. Download `google-services.json`.
4. Place it here:

```text
android/app/google-services.json
```

5. Configure FlutterFire for the project so Firebase options are generated for your app.
6. Run the app once on a real Android phone so it can request notification permission and obtain an FCM token.

## What is already prepared in code

- Firebase initialization
- Notification permission request
- FCM token retrieval
- Foreground message listener
- Background message handler
- Notification-open listener

## What still needs backend work

- Send the device token to Django
- Store guardian/rider device relationships
- Trigger parent notifications from confirmed accident events

## Files related to Firebase

- `lib/main.dart`
- `lib/services/notification_service.dart`

## Important

Do not commit private credentials publicly.
