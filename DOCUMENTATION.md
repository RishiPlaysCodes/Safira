# SafeRide Guardian - Complete Project Documentation

> **Ek single file me poora project samajhne ke liye — beginner to advanced level**

---

## TABLE OF CONTENTS

1. [Project Overview](#1-project-overview)
2. [Complete Architecture](#2-complete-architecture)
3. [File-by-File Explanation](#3-file-by-file-explanation)
4. [Line-by-Line Code Explanation](#4-line-by-line-code-explanation)
5. [Feature Implementation](#5-feature-implementation)
6. [Commands Documentation](#6-commands-documentation)
7. [Git Documentation](#7-git-documentation)
8. [Learning Roadmap](#8-learning-roadmap)
9. [Use Cases](#9-use-cases)
10. [Developer Guide](#10-developer-guide)
11. [Diagrams](#11-diagrams)
12. [Professional README](#12-professional-readme)

---

## 1. PROJECT OVERVIEW

### What This App Does
SafeRide Guardian ek **AI-powered road safety platform** hai jo:
- Rider ki driving ko **real-time monitor** karta hai (speed, location, impact)
- **Accident detect** karta hai automatically (using accelerometer + GPS + speed drop)
- **False alarms prevent** karta hai (pothole, bump ko accident nahi maanta)
- **Guardian/parents ko alert** bhejta hai (SMS + Call + Push + Live Location)
- **Helmet detection** karta hai camera se (AI model based)
- **Traffic signals** track karta hai
- **Weekly safety reports** generate karta hai
- **Zone-based speed limits** enforce karta hai (school/hospital ke paas slow)
- **Live location share** karta hai emergency me

### Main Objective
Beginner riders, students, aur young drivers ko safe rakhna aur unke parents/guardians ko **intelligent notifications** bhejta — bina false alarms ke.

### Real-World Use Case
- 18-saal ka college student bike pe jaa raha hai
- App background me GPS track kar rahi hai
- Agar student school zone me overspeed karta hai → alert
- Agar helmet nahi pehna → guardian notification
- Agar sudden impact + speed drop + no movement → accident suspicion
- 20-second countdown → "I Am Safe" button
- Agar no response → auto SMS + call + ambulance + live location share

### Target Users
| User Type | Use Case |
|-----------|----------|
| College Students | Self-monitoring while riding |
| Parents | Track child's riding safety remotely |
| Delivery Riders | Fleet safety monitoring |
| Schools/Colleges | Student safety programs |
| Insurance Companies | Safe driving data |

### Main Problem It Solves
1. **Accidents me help late milti hai** → Auto-detection + instant alert
2. **Parents ko pata nahi chalta** → Real-time notifications + weekly reports
3. **False alarms** → Multi-signal scoring (sirf ek signal se alert nahi)
4. **Helmet nahi pehnte** → AI camera detection
5. **Overspeed** → Zone-based monitoring + reports

### Why Each Major Feature Exists

| Feature | Why It Exists |
|---------|--------------|
| Auto-On | User bhool jaye start karna to bhi track ho |
| Multi-signal accident detection | Pothole/bump se false alarm na aaye |
| 20-sec countdown | User ko cancel karne ka mauka mile |
| Live location sharing | Emergency me guardian exact location dekh sake |
| Zone-based speed limits | School ke paas slow chale, highway pe fast ok |
| Weekly reports | Parents ko regular update mile |
| Helmet detection | Safety compliance ensure kare |
| Offline queue | Internet na ho to bhi data lose na ho |

---

## 2. COMPLETE ARCHITECTURE

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    SAFERIDE GUARDIAN                         │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────┐     REST API      ┌──────────────────┐   │
│  │   FLUTTER    │◄────────────────► │   DJANGO BACKEND  │   │
│  │  MOBILE APP  │    HTTP/JSON       │   (Python)        │   │
│  │  (Dart)      │                    │                    │   │
│  └──────┬───────┘                    └────────┬───────────┘   │
│         │                                      │             │
│   ┌─────┴─────┐                          ┌────┴────┐       │
│   │  SENSORS  │                          │ SQLite  │       │
│   │ GPS/Accel │                          │   DB    │       │
│   │ Camera    │                          └─────────┘       │
│   └───────────┘                                             │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │   FIREBASE   │  │   TWILIO     │  │  AI TRAINING     │   │
│  │  (Push)      │  │  (SMS/Call)  │  │  (TFLite Models) │   │
│  └──────────────┘  └──────────────┘  └──────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

### Frontend Architecture (Flutter Mobile App)

```
mobile/lib/
├── main.dart                    → App entry point
├── app/
│   ├── safe_ride_app.dart       → MaterialApp configuration
│   └── theme.dart               → Professional dark theme
├── features/
│   ├── home/
│   │   ├── home_screen.dart     → Main UI screen
│   │   └── home_controller.dart → Business logic (ChangeNotifier)
│   └── map/
│       └── map_screen.dart      → OpenStreetMap live ride map
├── services/
│   ├── location_service.dart         → GPS permissions + stream
│   ├── sensor_service.dart           → Accelerometer data
│   ├── emergency_service.dart        → SMS/Call intents
│   ├── notification_service.dart     → Firebase push + local notifications
│   ├── offline_queue_service.dart    → Offline data storage + sync
│   ├── activity_recognition_service.dart → Auto-on driving detection
│   ├── live_location_service.dart    → Real-time location sharing
│   ├── traffic_service.dart          → Traffic analysis + nearby places
│   └── camera_service.dart           → Camera frame capture for AI
├── detection/
│   └── accident_detector.dart   → Multi-signal accident algorithm
├── vision/
│   ├── vision_analyzer.dart          → Abstract interface
│   ├── vision_inference_result.dart  → Result model
│   ├── vision_pipeline_service.dart  → Orchestrator
│   └── tflite_vision_analyzer.dart   → TFLite model inference
├── repositories/
│   ├── trip_repository.dart     → Send trip data to backend
│   ├── alert_repository.dart    → Send accident signals to backend
│   ├── settings_repository.dart → SharedPreferences storage
│   └── vision_repository.dart   → Send vision observations to backend
└── models/
    ├── trip_sample.dart         → GPS data point model
    └── accident_event.dart      → Accident signal model
```

### Backend Architecture (Django)

```
backend/
├── manage.py                → Django management command
├── requirements.txt         → Python dependencies
├── saferide/               → Django project settings
│   ├── settings.py         → All configuration
│   ├── urls.py             → Root URL routing
│   ├── wsgi.py             → Production server interface
│   └── asgi.py             → Async server interface
├── users/                  → Authentication & profiles
│   ├── models.py           → DriverProfile model
│   ├── views.py            → Login/Signup/Dashboard views
│   ├── forms.py            → SignupForm
│   ├── urls.py             → /signup, /login, /dashboard, /logout
│   ├── admin.py            → Admin panel registration
│   └── templates/users/    → HTML templates
├── trips/                  → Trip management & safety analytics
│   ├── models.py           → Trip, SafetyZone, VisionObservation
│   ├── views.py            → Trip CRUD + API endpoints
│   ├── serializers.py      → DRF serializers
│   ├── forms.py            → TripForm for web
│   ├── urls.py             → Web + API routes
│   ├── admin.py            → Admin registration
│   └── templates/trips/    → HTML templates
├── alerts/                 → Emergency system
│   ├── models.py           → EmergencyAlert, Contact, LiveLocation...
│   ├── views.py            → Emergency workflow + API endpoints
│   ├── detection_engine.py → Accident risk calculation algorithm
│   ├── notification_service.py → Multi-channel notification sender
│   ├── serializers.py      → DRF serializers
│   ├── forms.py            → EmergencyContactForm
│   ├── urls.py             → Web + API routes
│   ├── admin.py            → Admin registration
│   └── templates/alerts/   → HTML templates
├── integrations/           → External service providers
│   ├── notifications.py    → Twilio / Free SMS provider
│   ├── ambulance.py        → Ambulance dispatch provider
│   ├── traffic.py          → Traffic assessment provider
│   └── vision.py           → Vision AI provider
└── templates/
    └── base.html           → Base template
```

### Database Architecture (SQLite)

```
┌─────────────────────────────────────────────────────────────┐
│                    DATABASE MODELS                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  auth_user (Django built-in)                                │
│  ├── id, username, email, password, is_active               │
│  │                                                          │
│  ├──► DriverProfile (1:1)                                   │
│  │    ├── phone_number, vehicle_type, license_number, role  │
│  │                                                          │
│  ├──► Trip (1:Many)                                         │
│  │    ├── speed, speed_limit, location, road_type           │
│  │    ├── helmet_worn, red_light_crossed                    │
│  │    ├── harsh_braking, sudden_acceleration                │
│  │    ├── alert_triggered, overspeed_count                  │
│  │    ├── risk_score, tags, created_at                      │
│  │    │                                                     │
│  │    └──► VisionObservation (1:Many)                       │
│  │         ├── observation_type, label, confidence          │
│  │         └── latitude, longitude                          │
│  │                                                          │
│  ├──► EmergencyContact (1:1)                                │
│  │    ├── contact_name, contact_phone, relationship         │
│  │                                                          │
│  ├──► EmergencyAlert (1:Many)                               │
│  │    ├── location, message, severity, source               │
│  │    ├── is_cancelled, alert_sent                          │
│  │    ├── parent_call_requested, ambulance_requested        │
│  │    │                                                     │
│  │    ├──► EscalationEvent (1:Many)                         │
│  │    │    ├── stage, status, message                       │
│  │    │                                                     │
│  │    └──► NotificationLog (1:Many)                         │
│  │         ├── channel, recipient, message, status          │
│  │                                                          │
│  ├──► DeviceRegistration (1:Many)                           │
│  │    ├── token, platform, is_active                        │
│  │                                                          │
│  ├──► LiveLocationSession (1:Many)                          │
│  │    ├── session_id, status, latitude, longitude           │
│  │    └── speed_kmh, last_updated                           │
│  │                                                          │
│  └──► SafetyZone (standalone)                               │
│       ├── name, zone_type, latitude, longitude              │
│       └── radius_meters, active                             │
└─────────────────────────────────────────────────────────────┘
```

### API Flow

```
Mobile App                          Django Backend
─────────                          ──────────────
    │                                    │
    │── POST /trips/api/receive/ ───────►│  Store trip + check zones
    │◄── {overspeed, risk_score, tags} ──│
    │                                    │
    │── POST /alerts/api/accident-signal/►│  Calculate accident risk
    │◄── {severity, guardian_alert_sent} ─│  → notify_guardian()
    │                                    │
    │── POST /alerts/api/live-location/ ─►│  Update LiveLocationSession
    │◄── {tracking_url} ─────────────────│
    │                                    │
    │── POST /trips/api/vision-obs/ ────►│  Store + check threshold
    │◄── {guardian_alert_sent} ──────────│  → notify if helmet missing
    │                                    │
    │── POST /alerts/api/register-device/►│  Save FCM token
    │◄── {device registered} ────────────│
    │                                    │
    │── GET /trips/api/weekly-summary/ ──►│  Calculate 7-day stats
    │◄── {total_trips, overspeed...} ────│
```

### Authentication Flow

```
1. User opens app → /signup/ page
2. Fills form → POST to signup_view()
3. Django creates User + DriverProfile
4. Auto-login with session cookie
5. Redirects to /dashboard/
6. Mobile app uses username field in API requests (demo mode)
7. Production: JWT tokens / session-based auth
```

### AI Automation Flow

```
Camera captures frame
       │
       ▼
TFLiteVisionAnalyzer.analyzeHelmet()
       │
       ▼
VisionPipelineService._send()
       │
       ▼
VisionRepository.sendObservation()  →  POST /trips/api/vision-observation/
       │                                         │
       ▼                                         ▼
Backend receives                        get_vision_provider().analyze()
       │                                         │
       ▼                                         ▼
VisionObservation saved                If helmet not_worn + conf >= 0.8
       │                                         │
       ▼                                         ▼
                                        EmergencyAlert created
                                                 │
                                                 ▼
                                        notify_guardian()
                                                 │
                                    ┌────────────┼────────────┐
                                    ▼            ▼            ▼
                                  SMS          Call         Push
                              (Twilio)      (Twilio)    (Firebase)
```



---

## 3. FILE-BY-FILE EXPLANATION

### BACKEND FILES

#### `backend/manage.py`
- **Purpose:** Django ka main management script
- **Why it exists:** Server run karne, migrations banane, admin create karne ke liye
- **Commands:** `python manage.py runserver`, `python manage.py migrate`

#### `backend/saferide/settings.py`
- **Purpose:** Poore project ki configuration — database, apps, middleware, external services
- **Key settings:**
  - `INSTALLED_APPS` — Django apps list (users, trips, alerts, rest_framework, corsheaders)
  - `DATABASES` — SQLite configuration
  - `NOTIFICATION_PROVIDER` — 'free' ya 'twilio'
  - `FIREBASE_CREDENTIALS_PATH` — Push notification ke liye
  - `CORS_ALLOW_ALL_ORIGINS` — Mobile app ko API access dene ke liye
  - `LOGGING` — Error tracking

#### `backend/saferide/urls.py`
- **Purpose:** Root URL router — sabhi app URLs ko connect karta hai
- **Logic:**
  - `''` → users app (home, login, signup, dashboard)
  - `'trips/'` → trips app (create, history, GPS, reports, APIs)
  - `'alerts/'` → alerts app (emergency, countdown, live-location, APIs)
  - `'admin/'` → Django admin panel

#### `backend/users/models.py` — DriverProfile
- **Purpose:** User ke extra data store karta hai (phone, vehicle, license, role)
- **Fields:**
  - `user` — OneToOneField to Django User
  - `phone_number` — Rider ka phone
  - `vehicle_type` — bike/car/scooter
  - `license_number` — DL number
  - `role` — driver/parent

#### `backend/users/views.py`
- **Purpose:** Authentication + Dashboard logic
- **Functions:**
  - `home()` — Landing page render
  - `signup_view()` — New user create + auto-login
  - `login_view()` — Authenticate + redirect to dashboard
  - `logout_view()` — Session destroy
  - `dashboard_view()` — MAIN dashboard with all stats:
    - Total trips, overspeed, red-light, helmet violations
    - Safety score calculation (100 - penalties)
    - Weekly summary (last 7 days)
    - Top risk tags
    - Latest alert status
    - Emergency contact info

#### `backend/trips/models.py`
- **3 Models:**
  1. **Trip** — Each ride data point
     - `calculate_risk()` — Score 0-100 based on violations
     - `calculate_tags()` — Auto-generates tags (overspeed, red-light, etc.)
     - `save()` override — Auto-calculates risk_score and tags on every save
  2. **SafetyZone** — Geographic safety areas (school, hospital)
     - `latitude/longitude/radius_meters` — Circular zone definition
  3. **VisionObservation** — AI camera detections (helmet, red-light, traffic)

#### `backend/trips/views.py`
- **Purpose:** Trip management + Zone detection + Vision processing + Weekly reports
- **Key functions:**
  - `receive_trip_data()` — API: Mobile sends GPS data → checks zones → stores trip
  - `api_vision_observation()` — API: Helmet/red-light detection → guardian alert if violation
  - `_build_weekly_summary()` — Calculates 7-day stats for reports
  - `send_weekly_report()` — Sends summary as guardian notification
  - `_maybe_send_zone_alert()` — Alerts guardian when entering safety zone
  - `_distance_meters()` — Haversine formula for GPS distance calculation

#### `backend/alerts/models.py`
- **6 Models:**
  1. **LiveLocationSession** — Real-time rider tracking
  2. **EmergencyContact** — Guardian phone/name/relationship
  3. **EmergencyAlert** — Every emergency event (severity, source, cancelled status)
  4. **NotificationLog** — Record of every SMS/call/push sent
  5. **DeviceRegistration** — FCM tokens for push notifications
  6. **EscalationEvent** — Step-by-step alert escalation trail

#### `backend/alerts/detection_engine.py`
- **Purpose:** CORE accident decision algorithm
- **Logic (conservative to prevent false alarms):**
  ```
  Score starts at 0
  
  Impact >= 8  → +35 points ("Strong impact")
  Impact >= 5  → +18 points ("Medium impact")
  Impact >= 3  → +6 points ("Small bump — not enough alone")
  
  Speed before >= 25 AND drop >= 25 AND after <= 8 → +35 ("Sudden near-stop")
  Speed drop >= 15 → +15 ("Moderate drop")
  
  No movement >= 45 sec → +20
  No movement >= 20 sec → +10
  
  Phone angle changed → +10
  
  User confirmed → Score = 100 (INSTANT alert)
  
  Score >= 75 → HIGH (guardian alerted + called)
  Score >= 45 → MEDIUM (show countdown, ask user)
  Score < 45  → LOW (logged only, no alert)
  ```
- **Why this approach:** Single signal alone is never enough. Pothole = impact only. Normal stop = speed drop only. Real accident = multiple signals together.

#### `backend/alerts/views.py`
- **Purpose:** Emergency workflow + All API endpoints
- **Key functions:**
  - `accident_simulation()` — Web demo: creates alert + shows countdown page
  - `manual_sos()` — Instant confirmed emergency (SMS + Call + Ambulance)
  - `cancel_alert()` — "I Am Safe" — marks cancelled
  - `confirm_accident()` — User confirms → full escalation
  - `receive_accident_signal()` — API: Mobile sends crash data → detection_engine → notify
  - `receive_live_location()` — API: Mobile sends GPS every 5 seconds
  - `get_live_location()` — API: Guardian fetches rider's current position
  - `live_track_page()` — Web page for guardian to see live map

#### `backend/alerts/notification_service.py`
- **Purpose:** Sends alerts through all channels
- **Flow:**
  1. Build message with location + live tracking link
  2. Send SMS via Twilio/Free provider
  3. Send Push via Firebase FCM
  4. Place phone call if severity = confirmed
  5. Dispatch ambulance if requested
  6. Log every notification in database

#### `backend/integrations/notifications.py`
- **Purpose:** Pluggable notification providers
- **Providers:**
  - `FreeNotificationProvider` — Logs notifications (testing/demo)
  - `TwilioNotificationProvider` — Real SMS + Voice calls via Twilio API
- **Pattern:** Strategy pattern — switch providers via environment variable

#### `backend/integrations/ambulance.py`
- **Purpose:** Ambulance dispatch abstraction
- **Providers:**
  - `FreeAmbulanceProvider` — Simulated (logs only)
  - `WebhookAmbulanceProvider` — Sends HTTP POST to ambulance service webhook

#### `backend/integrations/traffic.py`
- **Purpose:** Traffic level assessment
- **Providers:**
  - `FreeTrafficProvider` — Speed-based heuristic (no API needed)
  - `ExternalTrafficProvider` — HERE Maps API integration (optional)

#### `backend/integrations/vision.py`
- **Purpose:** Vision AI provider abstraction
- **Providers:**
  - `FreeManualVisionProvider` — Uses label/confidence from mobile request directly
  - `OnDeviceVisionProvider` — Same (inference happens on phone)

---

### MOBILE FILES

#### `mobile/lib/main.dart`
- **Purpose:** App entry point — initializes Firebase + runs SafeRideApp
- **Logic:** Try Firebase init, if fails (no config) app still works

#### `mobile/lib/app/safe_ride_app.dart`
- **Purpose:** MaterialApp with dark theme configuration
- **Sets:** Status bar transparent, dark navigation bar

#### `mobile/lib/app/theme.dart`
- **Purpose:** Professional dark glassmorphism theme
- **Contains:**
  - Color palette (primaryDark, accentBlue, neonGreen, dangerRed, etc.)
  - `glassCard()` — Reusable glass decoration with blur
  - `heroGradient()` — Gradient for speedometer
  - `neonGlow()` — Glowing shadow effect
  - Typography configuration

#### `mobile/lib/features/home/home_controller.dart`
- **Purpose:** BRAIN of the mobile app — all business logic
- **Manages:**
  - GPS tracking start/stop
  - Sensor data processing
  - Accident detection triggering
  - Auto-On monitoring
  - Live location sharing
  - Traffic detection
  - Zone-based speed limit adjustment
  - Emergency actions (SMS + Call)
  - Vision/AI reports
  - Settings persistence
  - Offline data sync

#### `mobile/lib/features/home/home_screen.dart`
- **Purpose:** Main UI — professional dark theme with glassmorphism
- **Sections:**
  - Header (brand + status chips + map button)
  - Speedometer (animated, glowing, responsive to overspeed)
  - Metrics row (GPS, Impact, Max Speed)
  - Accident alert card (countdown + safe/alert buttons)
  - Action buttons (Start/Stop, SOS, Share Location)
  - Traffic card (congestion level + nearby places)
  - Live Location card (toggle + link)
  - Ride Analysis (helmet, red-light, traffic buttons)
  - Settings (expandable — phone, username, backend URL, auto-on)

#### `mobile/lib/features/map/map_screen.dart`
- **Purpose:** Full-screen dark map with route polyline + live marker
- **Uses:** flutter_map + CartoDB dark tiles + Leaflet

#### `mobile/lib/services/location_service.dart`
- **Purpose:** GPS permission handling + position stream
- **Key:** `ForegroundNotificationConfig` for background tracking on Android

#### `mobile/lib/services/sensor_service.dart`
- **Purpose:** Accelerometer data → impact magnitude (in g-force)
- **Formula:** `sqrt(x² + y² + z²) / 9.81`

#### `mobile/lib/services/activity_recognition_service.dart`
- **Purpose:** AUTO-ON feature — detects when user starts driving
- **Logic:**
  - Speed >= 12 km/h for 3 consecutive samples → "Driving detected"
  - Speed <= 3 km/h for 10 consecutive samples → "Stopped"
  - Emits `ActivityState.driving` or `ActivityState.stationary`

#### `mobile/lib/services/live_location_service.dart`
- **Purpose:** Real-time location sharing with guardian
- **Features:**
  - Continuous GPS stream to backend
  - Generates shareable tracking link
  - Emergency message builder with coordinates
  - Auto-push every 5 seconds

#### `mobile/lib/services/traffic_service.dart`
- **Purpose:** Traffic detection + nearby place detection
- **Methods:**
  - `assessTraffic()` — Speed ratio analysis (free/moderate/heavy/severe)
  - `getNearbyPlaces()` — Overpass API query for schools/hospitals/signals
  - `getRecommendedSpeedLimit()` — Adjusts limit based on zone

#### `mobile/lib/services/camera_service.dart`
- **Purpose:** Camera frame capture interface for AI models
- **Pattern:** Stream-based — provides frames to TFLite analyzers

#### `mobile/lib/services/emergency_service.dart`
- **Purpose:** Launch SMS/Call intents on phone
- **Methods:**
  - `openSms()` — SMS with map link
  - `openSmsWithMessage()` — Custom emergency message
  - `openCall()` — Direct phone call
  - `callAmbulance()` — 108/911 call
  - `shareLocation()` — Full location share

#### `mobile/lib/services/notification_service.dart`
- **Purpose:** Firebase Cloud Messaging + local notifications
- **Handles:** Token generation, background messages, foreground display, token refresh

#### `mobile/lib/services/offline_queue_service.dart`
- **Purpose:** Store trips/alerts locally when backend unreachable
- **Storage:** SharedPreferences (JSON encoded lists)
- **Sync:** On reconnect, replays pending items

#### `mobile/lib/detection/accident_detector.dart`
- **Purpose:** Client-side accident detection algorithm
- **Algorithm:**
  ```
  Trigger conditions (ALL three must be true within 8-second window):
  1. Impact >= 3.2g (strong jolt)
  2. Speed drop >= 25 km/h (was going fast, suddenly stopped)
  3. Current speed <= 5 km/h (near-stationary after event)
  
  Cooldown: 30 seconds between alerts
  ```
- **Why 3 conditions:** Prevents false positives. Pothole = impact only. Traffic stop = speed drop only. Real crash = all three.

#### `mobile/lib/vision/vision_analyzer.dart`
- **Purpose:** Abstract interface for vision AI
- **Implementations:**
  - `ManualVisionAnalyzer` — Returns hardcoded test results
  - `OnDeviceVisionAnalyzer` — Placeholder for real TFLite models

#### `mobile/lib/vision/tflite_vision_analyzer.dart`
- **Purpose:** Production TFLite model inference (when models are loaded)
- **Models expected:**
  - `helmet_detector.tflite` → worn/not_worn classification
  - `traffic_signal.tflite` → red/green detection
  - `vehicle_counter.tflite` → traffic density estimation

#### `mobile/lib/vision/vision_pipeline_service.dart`
- **Purpose:** Orchestrates vision analysis → backend upload
- **Flow:** Analyzer.analyze() → Repository.sendObservation()

#### `mobile/lib/repositories/trip_repository.dart`
- **Purpose:** Sends trip data to Django backend
- **Offline handling:** If request fails → OfflineQueueService stores it

#### `mobile/lib/repositories/alert_repository.dart`
- **Purpose:** Sends accident signals to backend
- **Same offline pattern** as trip_repository

#### `mobile/lib/repositories/settings_repository.dart`
- **Purpose:** SharedPreferences wrapper for all user settings
- **Stores:** parentPhone, backendUrl, username, destination, autoOn

#### `mobile/lib/repositories/vision_repository.dart`
- **Purpose:** Sends vision observations (helmet/red-light/traffic) to backend

---

### AI TRAINING FILES

#### `ai_training/helmet_training_notebook.py`
- **Purpose:** Training script for helmet detection model
- **Output:** `helmet_detector.tflite`

#### `ai_training/train_object_detectors.py`
- **Purpose:** Generic object detection training pipeline
- **Supports:** Helmet, red-light, vehicle counting models

---

## 4. LINE-BY-LINE CODE EXPLANATION (Key Files)

### `detection_engine.py` — Accident Risk Calculator

```python
def calculate_accident_risk(
    impact_level=0,        # G-force from accelerometer (0-10 scale)
    speed_before=0,        # Speed before event (km/h)
    speed_after=0,         # Speed after event (km/h)
    no_movement_seconds=0, # How long rider didn't move
    phone_angle_changed=False,  # Phone flew/rotated?
    user_confirmed=False,  # Did user press "confirm accident"?
):
```
- **Input:** Sensor data from mobile app
- **Output:** Dictionary with score, severity, decision, reasons

```python
    # Type safety — convert any string/None to proper types
    impact_level = int(float(impact_level or 0))
    speed_before = float(speed_before or 0)
    # ...

    speed_drop = max(speed_before - speed_after, 0)  # Can't be negative
    score = 0
    reasons = []
```

```python
    # INSTANT OVERRIDE: User confirmed manually
    if user_confirmed:
        return {"score": 100, "severity": "confirmed", ...}
```
- User ne khud bola "yes accident hai" → Full alert, no questions

```python
    # IMPACT SCORING (accelerometer jolt)
    if impact_level >= 8:     # Very strong hit
        score += 35
    elif impact_level >= 5:   # Medium hit
        score += 18
    elif impact_level >= 3:   # Small bump (pothole level)
        score += 6            # Only 6 points — NOT enough alone to alert
```
- **Key insight:** impact_level 3 (pothole) + nothing else = score 6 = "Low" = NO alert

```python
    # SPEED DROP SCORING
    if speed_before >= 25 and speed_drop >= 25 and speed_after <= 8:
        score += 35   # Was going fast, suddenly near-stopped
    elif speed_drop >= 15:
        score += 15   # Moderate slowdown
```

```python
    # NO MOVEMENT (after crash, rider likely unconscious)
    if no_movement_seconds >= 45:
        score += 20
    elif no_movement_seconds >= 20:
        score += 10
```

```python
    # FINAL DECISION
    if score >= 75:  # Multiple strong signals
        severity = "high"
        guardian_alert_sent = True      # AUTO notify
        parent_call_requested = True    # AUTO call
    elif score >= 45:
        severity = "medium"
        guardian_alert_sent = False     # Show countdown first
    else:
        severity = "low"
        guardian_alert_sent = False     # Just log it
```

### `accident_detector.dart` — Mobile-Side Detection

```dart
class AccidentDetector {
  // Thresholds (tuned to avoid false alarms)
  final double impactThresholdG = 3.2;       // Strong hit (not pothole)
  final double speedDropThresholdKmh = 25;   // Major speed drop
  final double lowSpeedThresholdKmh = 5;     // Near-stopped
  final Duration signalWindow = Duration(seconds: 8);  // All must happen within 8s
  final Duration cooldown = Duration(seconds: 30);     // Min gap between alerts
```

```dart
  bool _shouldTrigger(TripSample sample) {
    // ALL THREE must be true:
    final hasRecentImpact = _lastImpactAt != null && 
        now.difference(_lastImpactAt!) <= signalWindow;
    final hasRecentSpeedDrop = _lastSpeedDropAt != null && 
        now.difference(_lastSpeedDropAt!) <= signalWindow;
    final hasLowPostImpactSpeed = sample.speedKmh <= lowSpeedThresholdKmh;

    return hasRecentImpact && hasRecentSpeedDrop && hasLowPostImpactSpeed;
  }
```
- **Triple-check system:** Impact alone = no trigger. Speed drop alone = no trigger. Only ALL THREE together = accident suspicion.

### `home_controller.dart` — App Brain

```dart
  // AUTO-ON: Detects driving without user pressing anything
  void _startAutoOnMonitoring() {
    _activityService.startMonitoring();
    _activitySubscription = _activityService.activityStream.listen((state) {
      if (state == ActivityState.driving && !tracking) {
        startTracking();  // Auto-start when driving detected
      } else if (state == ActivityState.stationary && tracking) {
        stopTracking();   // Auto-stop when parked
      }
    });
  }
```

```dart
  // EMERGENCY: Called when countdown reaches 0 OR user confirms
  Future<void> confirmAccidentNow() async {
    _countdownTimer?.cancel();
    accidentSuspicion = false;
    
    await startLiveLocationSharing();     // Start sharing location FIRST
    await _sendAlert('confirmed_no_response');  // Tell backend
    await _launchEmergencyActions();       // SMS + Call guardian
    _accidentDetector.resetTransientSignals();
  }
```

```dart
  // EMERGENCY ACTIONS: SMS with live location + auto-call
  Future<void> _launchEmergencyActions() async {
    final liveLink = liveLocationSharing
        ? liveTrackingLink
        : 'https://maps.google.com/?q=$latitude,$longitude';

    final message = 'SafeRide Guardian EMERGENCY!\n'
        'Rider: $username\n'
        'Possible accident detected.\n'
        'Live Location: $liveLink\n'
        'Speed: ${speedKmh.toStringAsFixed(1)} km/h\n'
        'Impact: ${impactG.toStringAsFixed(2)}g';

    await _emergencyService.openSmsWithMessage(phone: parentPhone, message: message);
    await _emergencyService.openCall(phone: parentPhone);  // AUTO CALL
  }
```

### `notify_guardian()` — Backend Notification

```python
def notify_guardian(alert, request_call=False, request_ambulance=False):
    # 1. Get guardian contact
    contact = EmergencyContact.objects.filter(user=user).first()
    
    # 2. Build message WITH live location link
    message = build_emergency_message(alert, contact)
    
    # 3. Send SMS
    sms_result = notification_provider.send_sms(recipient, message)
    
    # 4. Send Push Notification (if Firebase configured)
    if active_tokens and _firebase_app():
        # FCM multicast to all registered devices
        
    # 5. Phone Call (if confirmed/high severity)
    if request_call or alert.severity == 'confirmed':
        call_result = notification_provider.place_call(recipient, message)
        
    # 6. Ambulance (if requested)
    if request_ambulance:
        ambulance_provider.request_dispatch(location=alert.location)
    
    # 7. Log everything
    return logs
```



---

## 5. FEATURE IMPLEMENTATION

### Feature 1: User Authentication

| Aspect | Detail |
|--------|--------|
| **Objective** | User signup/login/logout with driver profile |
| **User Flow** | Home → Signup → Fill form → Auto-login → Dashboard |
| **Backend Flow** | `signup_view()` → Create User → Create DriverProfile → Login session |
| **Database** | `auth_user` + `users_driverprofile` |
| **APIs** | None (web-only, session-based) |
| **Files** | `users/views.py`, `users/forms.py`, `users/models.py` |
| **Edge Cases** | Duplicate username, weak password, empty phone |

### Feature 2: Trip Tracking + Overspeed Detection

| Aspect | Detail |
|--------|--------|
| **Objective** | Record ride data + auto-detect overspeed |
| **Mobile Flow** | GPS stream → TripSample → POST to backend every 2 meters |
| **Backend Flow** | `receive_trip_data()` → check zones → save → calculate risk/tags |
| **Database** | `trips_trip`, `trips_safetyzone` |
| **API** | `POST /trips/api/receive/` |
| **Key Logic** | `Trip.save()` auto-calculates: `alert_triggered = speed > speed_limit` |
| **Zone Detection** | Haversine distance to all active SafetyZones |

### Feature 3: Accident Detection (MAIN FEATURE)

| Aspect | Detail |
|--------|--------|
| **Objective** | Detect real accidents, prevent false alarms |
| **Mobile Flow** | Sensors → AccidentDetector → if triggered → countdown → alert |
| **Backend Flow** | `receive_accident_signal()` → `calculate_accident_risk()` → `notify_guardian()` |
| **Database** | `alerts_emergencyalert`, `alerts_escalationevent`, `alerts_notificationlog` |
| **API** | `POST /alerts/api/accident-signal/` |
| **Multi-signal** | Impact + Speed Drop + No Movement + Phone Angle = Real accident |
| **False alarm prevention** | Single signal = LOW severity = no alert |

### Feature 4: Guardian Notification System

| Aspect | Detail |
|--------|--------|
| **Objective** | Alert parents via SMS + Call + Push when emergency |
| **Channels** | SMS (Twilio), Phone Call (Twilio TwiML), Push (Firebase), Ambulance (webhook) |
| **Flow** | `notify_guardian()` → all channels → log each attempt |
| **Live Location** | Message includes Google Maps link + live tracking URL |
| **Files** | `alerts/notification_service.py`, `integrations/notifications.py` |

### Feature 5: Live Location Sharing (NEW)

| Aspect | Detail |
|--------|--------|
| **Objective** | Guardian sees rider's real-time location on map |
| **Mobile Flow** | `LiveLocationService` → GPS every 5 sec → POST to backend |
| **Backend Flow** | `receive_live_location()` → update LiveLocationSession |
| **Guardian View** | Opens `/alerts/live-track/{session_id}/` in browser → Leaflet map auto-updates |
| **API** | `POST /alerts/api/live-location/`, `GET /alerts/api/live-location/{id}/` |
| **Emergency** | Auto-starts when accident confirmed |

### Feature 6: Auto-On (Driving Detection)

| Aspect | Detail |
|--------|--------|
| **Objective** | App auto-starts tracking when user starts driving |
| **Logic** | GPS speed >= 12 km/h for 3 samples → "Driving" → auto start |
| **Stop Logic** | Speed <= 3 km/h for 10 samples → "Stationary" → auto stop |
| **Toggle** | User can enable/disable in settings |
| **File** | `services/activity_recognition_service.dart` |

### Feature 7: Helmet Detection (AI)

| Aspect | Detail |
|--------|--------|
| **Objective** | Detect if rider is wearing helmet using camera |
| **Pipeline** | Camera → TFLite model → VisionPipelineService → Backend API |
| **Backend** | If `label='not_worn'` + `confidence >= 0.8` → guardian alert |
| **Current status** | Pipeline complete, model placeholder (train with ai_training scripts) |
| **Files** | `vision/tflite_vision_analyzer.dart`, `vision/vision_pipeline_service.dart` |

### Feature 8: Zone-Based Speed Limits

| Aspect | Detail |
|--------|--------|
| **Objective** | Auto-adjust speed limit near schools/hospitals |
| **Backend** | `SafetyZone` model with lat/lng/radius |
| **Mobile** | `TrafficService.getRecommendedSpeedLimit()` queries Overpass API |
| **Limits** | School=20, Hospital=25, Traffic Signal=30, Normal=40 km/h |
| **Alert** | If rider enters zone → guardian notification |

### Feature 9: Weekly Safety Reports

| Aspect | Detail |
|--------|--------|
| **Objective** | Parents get 7-day driving summary |
| **Data** | Total trips, overspeed, red-light, helmet, zone visits, risk score |
| **Send** | Web button OR API call → creates alert → notify_guardian() |
| **API** | `GET /trips/api/weekly-summary/` |
| **Template** | `trips/weekly_report.html` (professional dark UI) |

### Feature 10: Driver Badge System

| Aspect | Detail |
|--------|--------|
| **Objective** | Gamify safe driving with badges |
| **Logic** | `safety_score = 100 - (overspeed*10 + red_light*15 + helmet*10)` |
| **Badges** | >= 80: Safe Driver, >= 60: Responsible, >= 40: Needs Improvement, < 40: Risky |
| **Display** | Dashboard shows colored badge + score ring |

### Feature 11: Traffic Detection

| Aspect | Detail |
|--------|--------|
| **Objective** | Detect traffic congestion around rider |
| **Method 1** | Speed ratio: current_speed / expected_speed → free/moderate/heavy/severe |
| **Method 2** | Overpass API: Query nearby schools/hospitals/traffic signals |
| **Display** | Traffic card in mobile UI shows level + percentage + nearby places |

### Feature 12: Offline Support

| Aspect | Detail |
|--------|--------|
| **Objective** | Don't lose data if internet is down |
| **How** | `OfflineQueueService` stores failed requests in SharedPreferences |
| **Sync** | On next successful connection, replays all pending items |
| **Applies to** | Trip data + Accident signals |

---

## 6. COMMANDS DOCUMENTATION

### Backend Setup

```bash
# Clone repository
git clone https://github.com/RishiPlaysCodes/Safira.git
cd Safira/backend

# Create virtual environment
python -m venv venv
source venv/bin/activate       # Linux/Mac
venv\Scripts\activate          # Windows

# Install dependencies
pip install -r requirements.txt

# Run migrations (create database tables)
python manage.py makemigrations
python manage.py migrate

# Create admin user
python manage.py createsuperuser

# Run development server
python manage.py runserver

# Run on specific port (for mobile testing)
python manage.py runserver 0.0.0.0:8000
```

### Mobile (Flutter) Setup

```bash
cd Safira/mobile

# Get dependencies
flutter pub get

# Run on connected device
flutter run

# Run on specific device
flutter devices              # List devices
flutter run -d <device_id>

# Build APK
flutter build apk --release

# Build App Bundle (Play Store)
flutter build appbundle --release

# Analyze code
flutter analyze

# Format code
dart format .
```

### Environment Variables

```bash
# Copy example to actual .env
cp backend/.env.example backend/.env

# Edit with your values:
NOTIFICATION_PROVIDER=free          # or 'twilio' for real SMS
TWILIO_ACCOUNT_SID=ACxxxxxxxxxx    # From Twilio console
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxx
TWILIO_FROM_NUMBER=+1234567890
FIREBASE_CREDENTIALS_PATH=/path/to/firebase-key.json
AMBULANCE_PROVIDER=free             # or 'webhook'
```

### Database Commands

```bash
# Create new migration after model changes
python manage.py makemigrations

# Apply migrations
python manage.py migrate

# Reset database (development only!)
rm db.sqlite3
python manage.py migrate
python manage.py createsuperuser

# Open database shell
python manage.py dbshell

# Django shell (test queries)
python manage.py shell
```

### Testing Commands

```bash
# Run all tests
python manage.py test

# Run specific app tests
python manage.py test alerts
python manage.py test trips
python manage.py test users

# Flutter tests
cd mobile
flutter test
```

### Production Deployment

```bash
# Collect static files
python manage.py collectstatic

# Run with gunicorn (production)
gunicorn saferide.wsgi:application --bind 0.0.0.0:8000

# Docker (if containerized)
docker build -t saferide .
docker run -p 8000:8000 saferide
```

---

## 7. GIT DOCUMENTATION

### Repository Structure

```
main branch → Stable production code
feature/* branches → New features in development
```

### Common Git Commands

```bash
# Clone the repo
git clone https://github.com/RishiPlaysCodes/Safira.git

# Create feature branch
git checkout -b feature/new-feature-name

# Check status
git status

# Stage all changes
git add .

# Stage specific file
git add backend/alerts/views.py

# Commit with message
git commit -m "Add live location sharing feature"

# Push to GitHub
git push origin feature/new-feature-name

# Pull latest changes
git pull origin main

# Merge main into your branch
git checkout feature/my-branch
git merge main

# View log
git log --oneline -10
```

### Good Commit Messages

```
✅ Good:
- "Add auto-on driving detection using GPS speed"
- "Fix false alarm when pothole impact detected"
- "Implement live location sharing with guardian tracking page"

❌ Bad:
- "update"
- "fix bug"
- "changes"
```

### .gitignore (Important files to exclude)

```
# Python
*.pyc
__pycache__/
venv/
db.sqlite3
.env

# Flutter
.dart_tool/
build/
*.apk
*.aab

# IDE
.idea/
.vscode/
*.iml

# OS
.DS_Store
Thumbs.db

# Credentials (NEVER commit!)
*.json (firebase keys)
```

---

## 8. LEARNING ROADMAP

### Python (Backend Language)

| Topic | Why Needed | Where Used | Study Order |
|-------|-----------|-----------|-------------|
| Variables, types, functions | Foundation | Everywhere | 1st |
| Classes & OOP | Models, providers | models.py, integrations/ | 2nd |
| Decorators | `@login_required`, `@api_view` | views.py | 3rd |
| Exception handling | Error resilience | notification_service.py | 4th |
| List comprehension | Data processing | views.py calculations | 5th |
| Dataclasses | Result objects | integrations/*.py | 6th |

### Django (Backend Framework)

| Topic | Why Needed | Where Used |
|-------|-----------|-----------|
| Models & ORM | Database operations | All models.py |
| Views & URL routing | API endpoints | All views.py, urls.py |
| Forms & validation | User input | forms.py |
| Templates & context | HTML rendering | All templates/ |
| Authentication | Login/signup | users/views.py |
| Admin panel | Data management | admin.py |
| Migrations | DB schema changes | migrations/ |
| REST Framework | Mobile API | serializers.py, api_view |

### Flutter/Dart (Mobile)

| Topic | Why Needed | Where Used |
|-------|-----------|-----------|
| Dart basics | Language foundation | All .dart files |
| Widgets & State | UI building | home_screen.dart |
| ChangeNotifier | State management | home_controller.dart |
| Streams & async | Sensor/GPS data | All services |
| HTTP requests | Backend communication | All repositories |
| Platform channels | Native features | Sensors, GPS |
| SharedPreferences | Local storage | settings_repository.dart |
| Firebase SDK | Push notifications | notification_service.dart |

### Machine Learning / AI

| Topic | Why Needed | Where Used |
|-------|-----------|-----------|
| TensorFlow basics | Model training | ai_training/ |
| Object detection | Helmet/traffic | train_object_detectors.py |
| TFLite conversion | Mobile inference | Model export |
| Image preprocessing | Frame normalization | tflite_vision_analyzer.dart |
| Dataset annotation | Training data | HELMET_DATASET_INTAKE.md |

### Other Essential Topics

| Topic | Why Needed |
|-------|-----------|
| REST API design | Mobile-backend communication |
| GPS/Geolocation | Core tracking feature |
| Accelerometer physics | Accident detection |
| Firebase Cloud Messaging | Push notifications |
| Twilio API | SMS/Call automation |
| SQLite/databases | Data persistence |
| Git/GitHub | Version control |
| Linux commands | Server deployment |

### Practice Tasks (Beginner → Advanced)

1. **Week 1:** Create Django project with login/signup
2. **Week 2:** Add Trip model + CRUD views
3. **Week 3:** Build REST API for Trip (POST/GET)
4. **Week 4:** Create Flutter app + call Django API
5. **Week 5:** Add GPS tracking in Flutter
6. **Week 6:** Implement overspeed detection
7. **Week 7:** Add accelerometer + accident logic
8. **Week 8:** Implement countdown + cancel flow
9. **Week 9:** Add SMS notification (Twilio trial)
10. **Week 10:** Build weekly report + dashboard

---

## 9. USE CASES

### Use Case 1: Normal Daily Ride

```
1. Student picks up phone, gets on bike
2. Auto-On detects driving → tracking starts automatically
3. Speed monitored — stays within 40 km/h → all green
4. Passes school zone → speed limit drops to 20 km/h
5. Trip data sent to backend every 2 meters
6. Ride ends, parks → Auto-On detects stationary → stops
7. Trip logged with tags: "school-zone" — risk score: 5
```

### Use Case 2: Overspeed Event

```
1. Rider goes 55 km/h in 40 km/h zone
2. App shows red speedometer + "OVERSPEED - SLOW DOWN!"
3. Trip data sent: alert_triggered = True
4. Backend calculates risk_score: 30
5. Tag added: "overspeed"
6. Shows in weekly report to guardian
```

### Use Case 3: Real Accident

```
1. Rider going 45 km/h
2. Sudden impact: 4.5g detected (bike hits car)
3. Speed drops: 45 → 2 km/h instantly
4. Rider not moving for 8+ seconds
5. AccidentDetector triggers (all 3 conditions met)
6. Countdown starts: 20... 19... 18...
7. Rider unconscious — no response
8. Countdown reaches 0
9. Live location sharing starts
10. Backend notified: severity = "confirmed"
11. SMS sent to parent: "Emergency! Live Location: [link]"
12. Auto-call to parent's phone
13. Ambulance webhook triggered
14. Guardian opens live tracking page in browser → sees rider on map
```

### Use Case 4: False Alarm Prevention

```
1. Rider hits pothole: impact 3.5g detected
2. But speed stays at 30 km/h (no drop!)
3. AccidentDetector: impact ✓ BUT speed_drop ✗
4. Result: NO trigger — riding continues normally
5. Backend log: risk_score = 6 (low), no alert sent
```

### Use Case 5: Helmet Not Worn

```
1. Camera detects: helmet = "not_worn", confidence = 0.92
2. VisionPipelineService sends to backend
3. Backend: confidence >= 0.8 → create alert
4. notify_guardian() called
5. Parent receives: "Helmet not detected during ride"
6. Shows in weekly report
```

### Use Case 6: Weekly Report

```
1. Saturday morning: system calculates 7-day summary
2. Trips: 12, Overspeed: 3, Red-light: 1, Helmet issues: 0
3. Average risk: 22/100
4. Badge: "Responsible Driver"
5. Rider clicks "Send to Guardian"
6. Parent receives summary via SMS + push notification
```

---

## 10. DEVELOPER GUIDE

### How to Add a New Safety Zone

```python
# In Django admin (/admin/) or shell:
from trips.models import SafetyZone
SafetyZone.objects.create(
    name="Delhi Public School, Rohini",
    zone_type="school",
    latitude=28.7041,
    longitude=77.1025,
    radius_meters=300,
    active=True
)
```

### How to Add a New API Endpoint

```python
# 1. Add view in views.py
@api_view(['POST'])
def my_new_endpoint(request):
    # logic here
    return Response({'status': 'ok'})

# 2. Add URL in urls.py
path('api/my-endpoint/', views.my_new_endpoint, name='my_endpoint'),

# 3. Call from Flutter
http.post(Uri.parse('$backendUrl/trips/api/my-endpoint/'), ...)
```

### How to Add a New Notification Channel

```python
# In integrations/notifications.py:
class WhatsAppNotificationProvider(BaseNotificationProvider):
    name = 'whatsapp'
    
    def send_sms(self, phone, message):
        # WhatsApp Business API call
        return DeliveryResult(self.name, 'sent', 'WhatsApp sent')
```

### How to Debug Backend Errors

```bash
# Check Django logs
python manage.py runserver  # Shows errors in terminal

# Django shell for testing
python manage.py shell
>>> from alerts.detection_engine import calculate_accident_risk
>>> result = calculate_accident_risk(impact_level=8, speed_before=50, speed_after=3)
>>> print(result)

# Check database
python manage.py shell
>>> from alerts.models import EmergencyAlert
>>> EmergencyAlert.objects.all()
```

### How to Debug Flutter Errors

```bash
# Run with verbose logging
flutter run --verbose

# Check print statements
debugPrint('[MyService] Data: $value');

# Hot reload (save file = instant update)
# Hot restart (R in terminal)
```

### How to Test Accident Detection Safely

```bash
# Option 1: Web demo at /alerts/detector-demo/
# Fill form with test values: impact=8, speed_before=50, speed_after=2

# Option 2: API call
curl -X POST http://localhost:8000/alerts/api/accident-signal/ \
  -H "Content-Type: application/json" \
  -d '{"username":"testuser", "impact_g":8, "speed_before":50, "speed_after":2, "no_movement_seconds":30}'

# Option 3: Flutter app manual SOS button (safe to test)
```

---

## 11. DIAGRAMS

### Complete Request Flow

```
┌──────────┐       ┌──────────────┐       ┌──────────────┐
│  RIDER   │       │ FLUTTER APP  │       │    DJANGO    │
│  (Human) │       │  (Phone)     │       │   BACKEND    │
└────┬─────┘       └──────┬───────┘       └──────┬───────┘
     │                     │                      │
     │  Rides bike         │                      │
     │─────────────────────►                      │
     │                     │                      │
     │              GPS + Sensors                  │
     │              ─────────────►                 │
     │                     │                      │
     │              Process data                   │
     │              Check thresholds               │
     │                     │                      │
     │                     │── POST /trips/api/ ──►│
     │                     │                      │ Store + Check zones
     │                     │◄── {risk, tags} ─────│
     │                     │                      │
     │  [ACCIDENT HAPPENS] │                      │
     │                     │                      │
     │              Impact 4.5g detected           │
     │              Speed drop 45→2                │
     │              No movement 10s                │
     │                     │                      │
     │              ★ TRIGGER ★                    │
     │                     │                      │
     │  ◄── COUNTDOWN 20s ─│                      │
     │                     │                      │
     │  [NO RESPONSE]      │                      │
     │                     │                      │
     │                     │── POST /accident/ ───►│
     │                     │                      │ calculate_risk()
     │                     │                      │ → score = 100
     │                     │                      │ notify_guardian()
     │                     │                      │   ├── SMS ──► Parent
     │                     │                      │   ├── CALL ─► Parent
     │                     │                      │   ├── PUSH ─► Parent Phone
     │                     │                      │   └── AMBULANCE webhook
     │                     │                      │
     │                     │── POST /live-loc/ ───►│ Store position
     │                     │                      │
     │                     │         PARENT opens live-track page
     │                     │              │
     │                     │              ▼
     │                     │      ┌───────────────┐
     │                     │      │ LIVE MAP PAGE │
     │                     │      │ (Leaflet.js)  │
     │                     │      │ Auto-refreshes│
     │                     │      └───────────────┘
```

### Database Relationships

```
User ─────┬──── 1:1 ────── DriverProfile
           │
           ├──── 1:1 ────── EmergencyContact
           │
           ├──── 1:Many ─── Trip
           │                  └── 1:Many ── VisionObservation
           │
           ├──── 1:Many ─── EmergencyAlert
           │                  ├── 1:Many ── EscalationEvent
           │                  └── 1:Many ── NotificationLog
           │
           ├──── 1:Many ─── DeviceRegistration
           │
           └──── 1:Many ─── LiveLocationSession
           
SafetyZone (standalone — no user relation)
```

---

## 12. PROFESSIONAL README

# SafeRide Guardian

> AI-Powered Road Safety, Accident Detection & Emergency Alert Platform

### Features

- Smart Accident Detection (multi-signal, false-alarm proof)
- Auto-On Driving Detection
- Live Location Sharing with Guardian
- Zone-Based Speed Monitoring (school/hospital/market)
- AI Helmet Detection (TFLite camera)
- Guardian Auto-Alert (SMS + Call + Push + Ambulance)
- Weekly Safety Reports
- Driver Badge System
- Offline Support
- Professional Dark UI

### Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile | Flutter (Dart) |
| Backend | Django (Python) + DRF |
| Database | SQLite |
| Maps | OpenStreetMap + Leaflet |
| AI/ML | TensorFlow Lite |
| Notifications | Firebase + Twilio |
| GPS | Geolocator plugin |
| Sensors | sensors_plus (accelerometer) |

### Installation

```bash
# Backend
cd backend && pip install -r requirements.txt
python manage.py migrate && python manage.py runserver

# Mobile
cd mobile && flutter pub get && flutter run
```

### Roadmap

- [x] MVP with accident detection
- [x] Live location sharing
- [x] Auto-on driving detection
- [x] Professional dark UI
- [x] Zone-based speed limits
- [ ] Trained helmet AI model
- [ ] Real Twilio integration
- [ ] Play Store deployment
- [ ] Insurance API partnership

### Disclaimer

This project is designed for **road safety education and protection**. All emergency features are configurable and require user consent. Always follow local traffic laws.

---

**Built with passion for road safety by RishiPlaysCodes**

*SafeRide Guardian &copy; 2025*
