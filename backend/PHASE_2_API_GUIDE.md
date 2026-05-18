# SafeRide Guardian - Phase 2 API Guide

This package adds the first real mobile-integration layer. The Django web app now has API endpoints that a Flutter/Android app can call later.

## Install new dependency

```bash
pip install -r requirements.txt
python manage.py migrate
python manage.py runserver
```

## API 1: Receive mobile trip/speed data

URL:

```text
POST /trips/api/receive/
```

Demo JSON body:

```json
{
  "username": "demo",
  "speed": 55,
  "speed_limit": 40,
  "location": "28.6139,77.2090",
  "road_type": "normal",
  "helmet_worn": true,
  "red_light_crossed": false,
  "harsh_braking": false,
  "sudden_acceleration": true,
  "notes": "Mobile GPS demo record"
}
```

What it does:
- creates a Trip row
- calculates overspeed
- calculates risk score
- returns JSON response

## API 2: Trip history API

URL:

```text
GET /trips/api/history/?username=demo
```

Returns latest trip records for that user.

## API 3: Receive accident sensor signal

URL:

```text
POST /alerts/api/accident-signal/
```

Demo JSON body:

```json
{
  "username": "demo",
  "location": "28.6139,77.2090",
  "impact_level": 8,
  "speed_before": 55,
  "speed_after": 0,
  "no_movement_seconds": 45,
  "user_confirmed": false
}
```

Logic:
- high impact + large speed drop + no movement = guardian alert sent
- low-confidence signal = stored but no guardian alert
- user_confirmed=true = confirmed emergency and parent call requested

## Important security note

For quick demo testing, the APIs accept a `username` field. In a production/mobile version, replace this with token authentication/JWT login.
