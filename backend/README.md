# SafeRide Guardian

SafeRide Guardian is a Django-based road-safety and emergency-response MVP for beginner drivers, riders, and parents/guardians.

## What it does now

- User signup/login/logout
- Driver profile dashboard
- Trip and safety-event logging
- Overspeed detection
- Red-light crossing report flag
- Helmet-not-worn report flag
- Harsh braking / sudden acceleration flags
- Risk score and safety score
- Driver badges
- Emergency contact setup
- Accident-like event simulation
- False-alarm prevention countdown
- “I am safe” cancellation
- “Accident happened” confirmation
- Manual SOS simulation
- Parent alert/call-request simulation
- Emergency alert history
- Admin panel for all records

## What is simulated in this web MVP

This web version simulates features that will become real in the mobile version:

- GPS speed tracking
- Accident detection through accelerometer/gyroscope
- Real SMS/call/push notification
- Google Maps zones
- Helmet detection through camera/AI
- Red-light crossing using signal-zone logic/computer vision

## Future real-world architecture

- **Django:** backend, database, dashboard, reports, alerts history
- **Mobile app:** GPS, accelerometer, gyroscope, camera, background detection
- **Google Maps:** live location, routes, school/hospital zones, geofencing
- **Firebase/Twilio:** push notification, SMS, phone-call workflow
- **AI/Computer Vision:** helmet detection, risky behavior analysis

## Run locally

```bash
python -m venv venv
venv\Scripts\activate   # Windows
pip install -r requirements.txt
python manage.py migrate
python manage.py createsuperuser
python manage.py runserver
```

Open:

```text
http://127.0.0.1:8000/
```

## Demo flow

1. Signup
2. Add emergency contact
3. Log safe trip
4. Log risky trip with overspeed/red-light/helmet issue
5. View dashboard and safety report
6. Simulate accident
7. Cancel once with “I am safe”
8. Simulate again and let countdown finish
9. Check alert history and admin panel

## Safety note

This is a learning/demo MVP. It should not be used as a real emergency service until it is converted into a tested mobile application with reliable sensor handling, permissions, notification provider, and false-positive controls.

## Phase 4: Notification Layer

This version includes a simulated notification system for guardian alerts. Manual SOS, confirmed accident alerts, countdown-triggered alerts, and serious accident-signal API events can create SMS/push/call notification logs.

Open:

```text
/alerts/notifications/
```

to review notification history.

Real SMS/calls are intentionally not enabled in this web MVP. Production upgrades should use Firebase and Twilio.
