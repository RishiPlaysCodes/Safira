# Phase 3: Accident Detection Decision Engine

This phase adds a reusable accident-risk engine for SafeRide Guardian.

## What was added

- `alerts/detection_engine.py`
- Web demo page: `/alerts/detector-demo/`
- Improved API: `/alerts/api/accident-signal/`
- False-alarm prevention logic
- Dashboard link to accident detector

## Detection inputs

The engine accepts:

- impact_level: 0-10 jerk/impact strength
- speed_before: speed before suspicious event
- speed_after: speed after event
- no_movement_seconds: stillness after impact
- phone_angle_changed: whether phone orientation changed suddenly
- user_confirmed: whether user manually confirmed accident

## Decision logic

The system does NOT alert guardians for every small bump.

Low risk examples:
- small bump only
- normal stopping only
- pothole jerk without speed drop/no movement

High risk example:
- strong impact
- sudden speed drop
- no movement after event
- user does not respond

Confirmed accident:
- if user confirms accident, parent call/message request is generated immediately.

## API test JSON

POST to `/alerts/api/accident-signal/`:

```json
{
  "username": "demo",
  "location": "28.6139,77.2090",
  "impact_level": 8,
  "speed_before": 55,
  "speed_after": 0,
  "no_movement_seconds": 45,
  "phone_angle_changed": true,
  "user_confirmed": false
}
```

## Why this matters

The app is no longer only a speed/alert prototype. It now has a conservative accident-decision engine designed to reduce false positives.
