# SafeRide Guardian — Phase 2 Real-World Mobile Plan

This Django project is the backend/dashboard MVP. To make SafeRide usable in real life, the next phase must add a mobile detection layer.

## Why Django alone is not enough
Django runs on a server/browser. Real accident detection needs a phone because the phone has:
- GPS for live location and speed
- accelerometer/gyroscope for impact and motion
- background service capability
- push notification support
- phone-call/SMS integration through native APIs or providers

## Final real-world architecture

```text
Mobile App
  - GPS speed
  - accelerometer impact
  - background tracking
  - accident countdown
  - user confirmation
  - location capture
        ↓
Django Backend
  - users
  - emergency contacts
  - trip history
  - accident alerts
  - safety reports
  - dashboard/admin
        ↓
Notification Layer
  - Firebase push notifications
  - Twilio/SMS/call later
```

## Phase 2 features

### 1. Mobile login
Mobile app will authenticate user and connect to Django backend.

### 2. Live tracking screen
- current speed
- current latitude/longitude
- tracking status
- start/stop ride

### 3. Accident suspicion logic
Do not trigger alert on normal stop or small pothole.

Recommended rule:

```text
IF speed was moving
AND sudden impact spike detected
AND speed drops sharply
AND phone stays still or user does not respond
THEN show accident countdown
```

### 4. Countdown safety flow
```text
Accident-like event detected
↓
30-second countdown
↓
User taps “I am safe” → cancel alert
User taps “Accident happened” → alert parent immediately
No response → alert parent
```

### 5. Guardian notification
Alert should include:
- driver name
- time
- location link
- alert type
- contact/call action

### 6. Do not auto-call ambulance in MVP
Because false positives are possible. Parent/guardian should be notified first.

## Suggested mobile stack

Recommended first mobile stack:
- Flutter
- Firebase Cloud Messaging
- Django REST API
- Google Maps SDK later

Alternative:
- Native Android Kotlin for better background/sensor control

## API endpoints needed in Django later

```text
POST /api/auth/login/
POST /api/trips/start/
POST /api/trips/location-update/
POST /api/alerts/create/
POST /api/alerts/cancel/
POST /api/alerts/confirm-accident/
GET  /api/dashboard/summary/
```

## Next build order

1. Convert Django views to APIs using Django REST Framework
2. Create Flutter app basic screens
3. Connect login API
4. Send location/speed data to backend
5. Add accident countdown in Flutter
6. Add Firebase push notification
7. Add Google Maps
8. Add stronger accident-detection algorithm
