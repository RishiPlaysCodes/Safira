# Safira (SafeRide Guardian) - Complete Technical Documentation

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture](#architecture)
3. [Technology Stack](#technology-stack)
4. [Features Deep Dive](#features-deep-dive)
5. [Backend Code Walkthrough](#backend-code-walkthrough)
6. [Mobile App Code Walkthrough](#mobile-app-code-walkthrough)
7. [AI/ML Pipeline](#aiml-pipeline)
8. [Security Architecture](#security-architecture)
9. [Deployment Infrastructure](#deployment-infrastructure)
10. [API Reference](#api-reference)

---

## Project Overview

**Safira (SafeRide Guardian)** is a real-time motorcycle safety platform that:
- Monitors rider speed via GPS and alerts on overspeed
- Detects accidents using phone sensors (accelerometer + gyroscope + GPS)
- Automatically notifies guardian/parents via SMS, call, and push notification
- Detects helmet usage via on-device AI (camera + TFLite model)
- Tracks rides with safety scoring and weekly reports
- Shows live route on OpenStreetMap
- Works offline (queues data when no network, syncs later)

### Who Is It For?
- Young riders whose parents want safety monitoring
- Fleet management for delivery companies
- Anyone who wants accident detection + emergency alerts

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        MOBILE APP (Flutter)                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │
│  │   GPS    │  │ Sensors  │  │  Camera  │  │   Firebase   │   │
│  │ Service  │  │ Service  │  │  Screen  │  │   Messaging  │   │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘  └──────┬───────┘   │
│       │              │              │               │            │
│  ┌────▼──────────────▼──────────────▼───────────────▼────────┐  │
│  │              HOME CONTROLLER (Business Logic)              │  │
│  │  - Speed monitoring + overspeed detection                 │  │
│  │  - Accident detection (impact + speed drop + no movement) │  │
│  │  - Helmet AI inference (on-device TFLite)                 │  │
│  │  - Emergency countdown + guardian alert                   │  │
│  └────┬──────────────────────────────────────────────────────┘  │
│       │                                                          │
│  ┌────▼──────────────────────────────────────────────────────┐  │
│  │              REPOSITORIES (API Communication)              │  │
│  │  - TripRepository (send ride data)                        │  │
│  │  - AlertRepository (send accident signals)                │  │
│  │  - VisionRepository (send helmet observations)            │  │
│  │  - OfflineQueueService (store when offline, sync later)   │  │
│  └────┬──────────────────────────────────────────────────────┘  │
│       │                                                          │
│  ┌────▼──────────────────────────────────────────────────────┐  │
│  │              API CLIENT (Token Auth + HTTPS)               │  │
│  │  - Authorization: Token <key> on every request            │  │
│  │  - HTTPS enforcement for non-local URLs                   │  │
│  │  - Error handling, retry, timeout                         │  │
│  └────┬──────────────────────────────────────────────────────┘  │
│       │                                                          │
└───────┼──────────────────────────────────────────────────────────┘
        │ HTTPS
        ▼
┌─────────────────────────────────────────────────────────────────┐
│                     NGINX (Reverse Proxy)                         │
│  - TLS 1.2/1.3 termination                                      │
│  - Rate limiting (30r/s API, 5r/m auth)                          │
│  - Security headers (HSTS, X-Frame-Options, CSP)                 │
│  - Static file serving                                           │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
┌─────────────────────────────────────────────────────────────────┐
│                   DJANGO REST API (Gunicorn)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌───────────┐  ┌───────────┐  ┌───────────┐  ┌────────────┐  │
│  │   users   │  │   trips   │  │  alerts   │  │integrations│  │
│  │  app      │  │  app      │  │  app      │  │  module    │  │
│  ├───────────┤  ├───────────┤  ├───────────┤  ├────────────┤  │
│  │- Auth API │  │- Trip data│  │- Accident │  │- Twilio    │  │
│  │- Profile  │  │- Zones    │  │- Detection│  │- Firebase  │  │
│  │- Token    │  │- Vision   │  │- Escalate │  │- Ambulance │  │
│  │  mgmt     │  │- Reports  │  │- Notify   │  │- Webhook   │  │
│  └───────────┘  └───────────┘  └───────────┘  └────────────┘  │
│                                                                   │
└──────────┬───────────────────────────────┬──────────────────────┘
           │                               │
           ▼                               ▼
┌──────────────────┐           ┌──────────────────────┐
│  PostgreSQL 16   │           │      Redis 7         │
│  - All app data  │           │  - Cache             │
│  - User accounts │           │  - Rate limit store  │
│  - Trip history  │           │  - Session store     │
│  - Alert logs    │           │  - Celery broker     │
└──────────────────┘           └──────────────────────┘
```

---

## Technology Stack


### Backend

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Python** | 3.11+ | Primary backend language |
| **Django** | 5.1.4 | Web framework - ORM, admin, auth, middleware |
| **Django REST Framework** | 3.15.2 | RESTful API with serialization, validation, throttling |
| **PostgreSQL** | 16 | Production database (ACID, relations, indexes) |
| **Redis** | 7 | Caching, rate limiting, Celery task broker |
| **Gunicorn** | 23.0 | Production WSGI server (multi-worker, gthread) |
| **Nginx** | Alpine | Reverse proxy, TLS termination, static files |
| **Celery** | 5.4 | Async task queue (notifications, email) |
| **WhiteNoise** | 6.8 | Static file serving without separate server |
| **Sentry** | 2.19 | Error tracking and performance monitoring |
| **Firebase Admin** | 6.6 | Push notification delivery (FCM) |
| **Twilio** | 9.4 | SMS and voice call notifications |

### Mobile App

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Flutter** | 3.x | Cross-platform UI framework (Android + iOS) |
| **Dart** | >=3.3 | Programming language for Flutter |
| **Geolocator** | 13.0 | GPS location tracking with background support |
| **Sensors Plus** | 6.1 | Accelerometer/gyroscope for impact detection |
| **Camera** | 0.11 | Camera access for helmet detection |
| **TFLite Flutter** | 0.11 | On-device ML model inference |
| **Flutter Map** | 8.2 | OpenStreetMap live route display |
| **Firebase Messaging** | 15.2 | Push notification receiving |
| **Flutter Local Notifications** | 19.4 | On-device warning notifications |
| **SharedPreferences** | 2.3 | Local key-value storage (token, settings) |
| **HTTP** | 1.2 | REST API communication |

### AI/ML

| Technology | Purpose |
|-----------|---------|
| **YOLOv8-nano** | Object detection model (helmet/no-helmet) |
| **Ultralytics** | Training framework |
| **TensorFlow Lite** | On-device inference runtime |
| **Google Colab** | Free GPU training (T4) |

### Infrastructure

| Technology | Purpose |
|-----------|---------|
| **Docker** | Containerization (multi-stage build) |
| **Docker Compose** | Multi-service orchestration |
| **Google Cloud Run** | Serverless container hosting (free tier) |
| **Cloud SQL** | Managed PostgreSQL |
| **Secret Manager** | Secure credential storage |
| **Artifact Registry** | Docker image storage |

---

## Features Deep Dive

### 1. Real-Time GPS Speed Tracking

**How it works:**
- `LocationService` requests GPS permission and starts a position stream
- Position updates every 2 meters (high accuracy, `bestForNavigation`)
- Speed is calculated from GPS data (`position.speed * 3.6` → km/h)
- On Android, uses foreground service notification to keep tracking in background

**Files involved:**
- `mobile/lib/services/location_service.dart` — GPS stream setup
- `mobile/lib/features/home/home_controller.dart` — speed processing
- `mobile/lib/features/home/home_screen.dart` — speed display UI

### 2. Overspeed Detection + Guardian Warning

**How it works:**
- Every GPS update, `_checkOverspeed()` compares current speed to limit (40 km/h default)
- Two trigger conditions:
  - **Sustained:** Speed above limit for 10+ continuous seconds
  - **Severe:** Speed exceeds 125% of limit (50+ km/h) immediately
- On trigger:
  - Shows local notification on rider's phone ("Overspeed warning")
  - Records an 'overspeed' event on backend (guardian sees in history)
- **Debounced:** Maximum one alert every 3 minutes (prevents spam)

**Files involved:**
- `mobile/lib/features/home/home_controller.dart` → `_checkOverspeed()`
- `mobile/lib/services/notification_service.dart` → `showLocalWarning()`
- `backend/alerts/views.py` → `receive_accident_signal()` accepts 'overspeed' status

### 3. Accident Detection

**How it works (multi-signal fusion):**
1. **Impact detection:** Accelerometer measures G-force continuously
   - Threshold: 3.2G (normal pothole = ~1.5G, crash = 4-10G)
2. **Speed drop:** GPS shows sudden deceleration (25+ km/h drop)
3. **No movement:** After impact, rider doesn't move for several seconds

**All three must occur within an 8-second window** to trigger (reduces false positives).

**Countdown flow:**
1. Accident suspected → 20-second countdown starts
2. Local notification: "Possible accident detected"
3. If rider taps "I am safe" → cancelled, no alert
4. If countdown reaches 0 (no response) → confirmed accident:
   - SMS sent to guardian with Google Maps location link
   - Phone dialer opens to call guardian
   - Backend records confirmed accident
   - Ambulance webhook triggered (if configured)

**Backend risk scoring:**
| Signal | Points |
|--------|--------|
| Strong impact (≥8G) | +35 |
| High speed → sudden stop | +35 |
| No movement 45+ seconds | +20 |
| Phone orientation changed | +10 |
| User confirmed | 100 (instant) |

- Score ≥ 75: HIGH → guardian notified + called
- Score 45-74: MEDIUM → countdown shown
- Score < 45: LOW → logged only

**Files involved:**
- `mobile/lib/detection/accident_detector.dart` — client-side trigger logic
- `mobile/lib/services/sensor_service.dart` — accelerometer stream
- `backend/alerts/detection_engine.py` — server-side risk scoring
- `backend/alerts/notification_service.py` — SMS/call/push dispatch

### 4. On-Device Helmet Detection (AI)

**How it works:**
1. User taps "Live Helmet Detection" → camera opens
2. Camera streams YUV420 frames at ~30 FPS
3. Every 3rd frame is sent to the TFLite model (prevents UI lag)
4. Model (YOLOv8-nano, 320x320 input):
   - Preprocesses frame: YUV→RGB, resize, normalize to 0-1
   - Runs inference on phone GPU/CPU (~30ms per frame)
   - Decodes YOLO output: bounding boxes + class scores
   - Non-Maximum Suppression removes duplicate detections
5. Result: `helmet` (green box) or `no_helmet` (red box + red border flash)
6. If `no_helmet` confidence ≥ 60% → guardian alert sent (30s cooldown)

**Works 100% offline — no internet needed for detection.**

**Files involved:**
- `mobile/lib/vision/tflite/helmet_detector.dart` — TFLite inference engine
- `mobile/lib/vision/on_device_analyzer.dart` — frame→result wrapper
- `mobile/lib/features/camera/camera_screen.dart` — camera UI + overlay
- `ai_training/helmet_detection_colab.ipynb` — model training notebook
- `mobile/assets/models/helmet_detector.tflite` — trained model file

### 5. Live Map (OpenStreetMap)

**How it works:**
- Uses `flutter_map` package with OpenStreetMap tile server (free, no API key)
- Route drawn as blue polyline from recorded `TripSample` GPS points
- Current position shown as red location pin
- Samples capped at 500 (rolling window)

**Files:** `mobile/lib/features/map/map_screen.dart`

### 6. Safety Zones (Geofencing)

**How it works:**
- Admin creates zones via Django admin (school, hospital, market, danger)
- Each zone: name + latitude + longitude + radius (meters)
- When trip data includes lat/lon, backend calculates haversine distance
- If rider enters a zone → low-severity guardian alert + road_type tag updated
- Debounced: max one zone alert per 15 minutes

**Files:**
- `backend/trips/models.py` → `SafetyZone` model
- `backend/trips/views.py` → `_distance_meters()`, `_maybe_send_zone_alert()`

### 7. Weekly Safety Reports

**How it works:**
- Aggregates last 7 days of trips:
  - Total trips, overspeed events, red-light violations
  - Helmet issues, zone visits, average risk score
  - Vision observations count
- Available via API (`/trips/api/weekly-summary/`) and web UI

### 8. Emergency SMS + Call (Free, No API needed)

**How it works:**
- On confirmed accident/manual SOS:
  - Opens phone's native SMS app with pre-filled message + Google Maps link
  - Opens phone's native dialer with guardian's number
- Uses `url_launcher` package (no Twilio needed for this)
- Twilio is optional for **server-side** SMS (when rider can't open their phone)

**Files:** `mobile/lib/services/emergency_service.dart`

### 9. Offline Queue + Sync

**How it works:**
- When API call fails (no network, timeout, server down):
  - Payload saved to `SharedPreferences` (local storage)
- When network returns (next trip start, settings save):
  - Queued payloads retried one by one
  - Successfully sent items removed from queue
  - Failed items stay for next retry

**Files:** `mobile/lib/services/offline_queue_service.dart`

### 10. Push Notifications (Firebase Cloud Messaging)

**How it works (optional, requires Firebase setup):**
- App registers device FCM token with backend on login
- When guardian alert triggered, backend sends multicast push
- App shows high-priority notification even when in background
- Token auto-refreshes and re-registers

**Files:**
- `mobile/lib/services/notification_service.dart` — FCM init + local notifications
- `backend/alerts/notification_service.py` → `notify_guardian()` — sends push via firebase-admin

---


## Backend Code Walkthrough

### Project Structure

```
backend/
├── saferide/                  # Django project config
│   ├── settings.py            # All configuration (env-based)
│   ├── urls.py                # Root URL routing
│   ├── wsgi.py                # WSGI entry point (Gunicorn)
│   ├── middleware.py          # Request logging + correlation IDs
│   ├── exception_handler.py   # Consistent JSON error responses
│   └── health.py              # Health check endpoints
├── users/                     # Authentication + profiles
│   ├── models.py              # DriverProfile (phone, vehicle, role)
│   ├── api_views.py           # Token auth API (login/signup/logout)
│   ├── views.py               # Web views (login page, dashboard)
│   └── urls.py                # Route mapping
├── trips/                     # Ride tracking + safety zones
│   ├── models.py              # Trip, SafetyZone, VisionObservation
│   ├── views.py               # Trip data API + zone detection
│   ├── serializers.py         # DRF serializers (validation)
│   └── urls.py                # Route mapping
├── alerts/                    # Emergency alert system
│   ├── models.py              # EmergencyAlert, EscalationEvent, NotificationLog
│   ├── views.py               # Accident signal API + alert management
│   ├── detection_engine.py    # Risk scoring algorithm
│   ├── notification_service.py # Multi-channel notification dispatch
│   ├── serializers.py         # DRF serializers
│   └── urls.py                # Route mapping
├── integrations/              # External service adapters
│   ├── notifications.py       # Twilio SMS/call (pluggable)
│   ├── ambulance.py           # Webhook ambulance dispatch
│   ├── vision.py              # Vision provider interface
│   └── traffic.py             # Traffic data provider
├── Dockerfile                 # Multi-stage production build
├── docker-entrypoint.sh       # DB wait + migrate + collectstatic
├── requirements.txt           # Pinned production dependencies
└── requirements-dev.txt       # Dev/test dependencies
```

### Key File Explanations

#### `saferide/settings.py` — Configuration Hub
```python
SECRET_KEY = os.environ.get('DJANGO_SECRET_KEY', '')
# Why: Never hardcode secrets. Load from environment variable.
# In production, stored in Google Cloud Secret Manager.

DEBUG = os.environ.get('DJANGO_DEBUG', 'False').lower() in ('true', '1', 'yes')
# Why: DEBUG=True shows error details to users — security risk in production.
# Defaults to False so forgetting to set it doesn't expose data.

REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': ['rest_framework.authentication.TokenAuthentication', ...],
    'DEFAULT_PERMISSION_CLASSES': ['rest_framework.permissions.IsAuthenticated'],
    'DEFAULT_THROTTLE_RATES': {'anon': '20/minute', 'user': '120/minute', ...},
}
# Why: Every API endpoint requires a valid token by default.
# Rate limiting prevents brute-force attacks and API abuse.
```

#### `alerts/detection_engine.py` — Accident Risk Algorithm
```python
def calculate_accident_risk(impact_level, speed_before, speed_after, ...):
    # Multi-signal scoring: each signal adds points
    # Strong impact (>=8G) = +35 points
    # Speed 60→0 = +35 points
    # No movement 45s = +20 points
    # Phone angle changed = +10 points
    # User confirmed = 100 (immediate)
    #
    # Score >= 75: HIGH severity → notify guardian + call
    # Score 45-74: MEDIUM → show countdown on phone
    # Score < 45: LOW → log only, no action
    #
    # WHY these thresholds: Prevents false alarms from potholes (small
    # impact alone = only +6-18 points, never reaches 45).
```

#### `users/api_views.py` — Authentication Flow
```python
@api_view(['POST'])
@permission_classes([AllowAny])          # Anyone can attempt login
@throttle_classes([AuthRateThrottle])    # But only 5 attempts per minute
def api_login(request):
    # 1. Validate input (username + password required)
    # 2. Authenticate against Django's auth system
    # 3. If failed: log the attempt (IP address) for security monitoring
    # 4. If success: get or create a Token, return it with user profile
    # Token is used in all subsequent requests: Authorization: Token <key>
```

#### `saferide/middleware.py` — Request Logging
```python
class RequestLoggingMiddleware:
    # Every request gets:
    # 1. A unique 8-char request ID (for tracing issues across logs)
    # 2. Timing measurement (how long the request took)
    # 3. Log entry: [abc12345] POST /trips/api/receive/ -> 201 (45.2ms) user=rishi
    # 4. X-Request-ID header in response (for debugging)
```

---

## Mobile App Code Walkthrough

### Project Structure

```
mobile/lib/
├── main.dart                          # App entry point
├── app/
│   └── safe_ride_app.dart             # MaterialApp + AuthGate
├── features/
│   ├── auth/
│   │   └── login_screen.dart          # Login/Signup UI
│   ├── home/
│   │   ├── home_screen.dart           # Main dashboard UI
│   │   └── home_controller.dart       # All business logic
│   ├── camera/
│   │   └── camera_screen.dart         # Live helmet detection UI
│   └── map/
│       └── map_screen.dart            # Route visualization
├── services/
│   ├── auth_service.dart              # Token management (login/logout/storage)
│   ├── api_client.dart                # HTTP client (auth headers, HTTPS, errors)
│   ├── location_service.dart          # GPS stream
│   ├── sensor_service.dart            # Accelerometer stream
│   ├── notification_service.dart      # FCM + local notifications
│   ├── emergency_service.dart         # Native SMS/call intents
│   └── offline_queue_service.dart     # Failed request storage
├── repositories/
│   ├── trip_repository.dart           # Trip data API calls
│   ├── alert_repository.dart          # Accident signal API calls
│   ├── vision_repository.dart         # Vision observation API calls
│   └── settings_repository.dart       # Local settings persistence
├── models/
│   ├── trip_sample.dart               # GPS data point model
│   └── accident_event.dart            # Accident event model
├── detection/
│   └── accident_detector.dart         # Client-side accident trigger logic
└── vision/
    ├── vision_analyzer.dart           # Analyzer interface (manual/on-device)
    ├── vision_pipeline_service.dart   # Orchestrates analysis + reporting
    ├── vision_inference_result.dart   # Result data class
    ├── on_device_analyzer.dart        # Camera frame → detection result
    └── tflite/
        └── helmet_detector.dart       # Raw TFLite model inference
```

### Key File Explanations

#### `main.dart` — App Bootstrap
```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 1. Create AuthService (manages login state + token)
  final authService = AuthService();
  await authService.initialize();  // Load saved token from storage
  // 2. Create ApiClient (attaches token to every HTTP request)
  final apiClient = ApiClient(authService: authService);
  // 3. Firebase is OPTIONAL - if google-services.json missing, skipped
  // 4. Local notifications ALWAYS initialized (overspeed warnings work without Firebase)
  await NotificationService().initialize();
  // 5. Start the app with AuthGate (shows login or home based on token)
  runApp(SafeRideApp(authService: authService, apiClient: apiClient));
}
```

#### `services/auth_service.dart` — Token Authentication
```dart
class AuthService extends ChangeNotifier {
  // Stores: token, username, userId in SharedPreferences
  // login() → POST /api/auth/login/ → saves token → notifyListeners()
  // signup() → POST /api/auth/signup/ → saves token → notifyListeners()
  // logout() → POST /api/auth/logout/ → deletes token → notifyListeners()
  //
  // AuthGate listens to this. When token appears → shows HomeScreen.
  // When token disappears → shows LoginScreen. Automatic.
  //
  // WHY ChangeNotifier: Flutter rebuilds UI automatically when state changes.
}
```

#### `services/api_client.dart` — Secure HTTP Client
```dart
class ApiClient {
  // Every request gets:
  // 1. Authorization: Token <key> header (from AuthService)
  // 2. Content-Type: application/json header
  // 3. HTTPS enforcement (non-local URLs upgraded to https://)
  // 4. 15-second timeout (5s for quick fire-and-forget calls)
  // 5. Error handling: 401=session expired, 429=rate limited, 5xx=server error
  //
  // WHY centralized: One place to change auth logic, error handling, base URL.
  // WHY HTTPS enforcement: Prevents token theft via network sniffing.
}
```

#### `detection/accident_detector.dart` — Client-Side Trigger
```dart
class AccidentDetector {
  // Three signals must ALL occur within 8 seconds:
  // 1. impactThresholdG = 3.2G (accelerometer spike)
  // 2. speedDropThresholdKmh = 25 km/h (GPS speed drop)
  // 3. lowSpeedThresholdKmh = 5 km/h (current speed near zero)
  //
  // Also has a 30-second cooldown to prevent multiple triggers.
  //
  // WHY 3 signals together: Single signals cause false positives:
  // - Impact alone: potholes, phone dropped
  // - Speed drop alone: red light, traffic
  // - Low speed alone: parked
  // All three together = very likely a crash.
}
```

#### `vision/tflite/helmet_detector.dart` — ML Inference
```dart
class HelmetDetector {
  // 1. initialize(): Load .tflite model + labels from assets
  //    - Tries GPU delegate first (faster), falls back to CPU
  // 2. detectFromCameraImage(CameraImage):
  //    - Preprocess: YUV420 → RGB → resize 320x320 → normalize 0-1
  //    - Run inference: model produces [1, 6, 2100] tensor
  //    - Decode: extract boxes (cx,cy,w,h) + class scores
  //    - NMS: remove overlapping boxes (IoU > 0.5)
  //    - Return: List<DetectionResult> above 0.45 confidence
  //
  // WHY YOLOv8-nano: Smallest YOLO variant, ~6MB, 20-30 FPS on phone.
  // WHY 320x320: Smaller than default 640 = 4x faster, still accurate for 2 classes.
}
```

---


## AI/ML Pipeline

### Training Process

```
Kaggle Dataset (5000 images, VOC XML annotations)
    ↓ Convert to YOLO format (class cx cy w h normalized)
    ↓ Split: 70% train, 20% validation, 10% test
    ↓
YOLOv8-nano (pretrained on COCO → transfer learning)
    ↓ Fine-tune 50 epochs, 320x320, batch 16, T4 GPU
    ↓ Augmentations: horizontal flip, mosaic, mixup
    ↓
Best weights (best.pt) → evaluate on test set
    ↓ mAP50 should be > 0.7 for production use
    ↓
Export to TFLite (FP16 quantization)
    ↓ ~6 MB file, optimized for mobile
    ↓
Place in: mobile/assets/models/helmet_detector.tflite
```

### Model Architecture (YOLOv8-nano)

- **Backbone:** CSPDarknet (feature extraction from image)
- **Neck:** PANet (multi-scale feature fusion)
- **Head:** Decoupled head (separate box + class prediction)
- **Parameters:** 3.2 million (tiny compared to full YOLO)
- **Input:** 320×320×3 (RGB normalized to 0-1)
- **Output:** [1, 6, 2100] tensor (4 box coords + 2 class scores × 2100 anchors)

### On-Device Inference Pipeline

```dart
// Frame arrives from camera (YUV420, ~1920×1080)
//     ↓
// Resize to 320×320 (bilinear interpolation)
//     ↓
// Convert YUV→RGB, normalize pixel values / 255.0
//     ↓
// Run TFLite interpreter (GPU delegate if available)
//     ↓ ~30ms on Snapdragon 600+
// Decode output: 2100 potential detections
//     ↓
// Filter by confidence threshold (> 0.45)
//     ↓
// Non-Maximum Suppression (remove overlapping boxes, IoU > 0.5)
//     ↓
// Result: 0-5 DetectionResult objects with label + confidence + rect
```

---

## Security Architecture

### Authentication Flow

```
┌──────────┐          ┌──────────┐          ┌──────────┐
│  Mobile  │          │  Backend │          │ Database │
│   App    │          │  (Django)│          │ (Postgres)│
└────┬─────┘          └────┬─────┘          └────┬─────┘
     │                     │                      │
     │ POST /api/auth/login/                      │
     │ {username, password}│                      │
     ├────────────────────►│                      │
     │                     │ Check credentials    │
     │                     ├─────────────────────►│
     │                     │◄─────────────────────┤
     │                     │                      │
     │ 200 {token: "abc"}  │                      │
     │◄────────────────────┤                      │
     │                     │                      │
     │ GET /trips/api/history/                    │
     │ Authorization: Token abc                   │
     ├────────────────────►│                      │
     │                     │ Validate token       │
     │                     ├─────────────────────►│
     │                     │◄─────────────────────┤
     │                     │                      │
     │ 200 {trips: [...]}  │                      │
     │◄────────────────────┤                      │
```

### Security Layers

| Layer | Protection |
|-------|-----------|
| **HTTPS** | Encrypts all traffic (TLS 1.2/1.3) |
| **Token Auth** | Every request authenticated (no anonymous access to data) |
| **Rate Limiting** | 5/min for auth, 20/min anonymous, 120/min user |
| **Input Validation** | DRF serializers validate all fields (type, range, format) |
| **CORS** | Only allowed origins can make cross-origin requests |
| **HSTS** | Browser forced to use HTTPS for 1 year |
| **Secure Cookies** | HttpOnly, SameSite, Secure flags |
| **Password Validation** | Min 10 chars, not common, not numeric-only |
| **Android Network Security** | Blocks HTTP (cleartext) for non-local URLs |
| **Secret Manager** | Credentials never in code or environment files |

---

## Deployment Infrastructure

### Docker Architecture

```
┌─────────────────────────────────────────────────┐
│              docker-compose.yml                   │
├─────────────────────────────────────────────────┤
│                                                   │
│  ┌─────────┐  ┌───────┐  ┌────────┐  ┌───────┐ │
│  │  nginx  │  │backend│  │ celery │  │  db   │ │
│  │  :80    │──│ :8000 │  │ worker │  │ :5432 │ │
│  │  :443   │  │       │  │        │  │       │ │
│  └─────────┘  └───┬───┘  └────┬───┘  └───────┘ │
│                    │           │                  │
│                    └─────┬─────┘                  │
│                          ▼                        │
│                    ┌───────────┐                  │
│                    │   redis   │                  │
│                    │   :6379   │                  │
│                    └───────────┘                  │
└─────────────────────────────────────────────────┘
```

### Dockerfile (Multi-Stage Build)

```dockerfile
# Stage 1: Install dependencies (build tools needed)
FROM python:3.12-slim AS builder
# Install gcc, libpq-dev for compiling psycopg2
# pip install into /install prefix

# Stage 2: Production image (minimal)
FROM python:3.12-slim AS production
# Copy only compiled packages from builder (no gcc/dev tools)
# Run as non-root user 'saferide'
# HEALTHCHECK: curl /api/health/ every 30s
# CMD: gunicorn with 4 workers, gthread, max-requests 1000
```

**Why multi-stage:** Final image is ~200MB instead of ~800MB. No build tools in production = smaller attack surface.

### Google Cloud Run Deployment

```
Source Code → Cloud Build (free, builds Docker image)
    ↓
Artifact Registry (stores the image)
    ↓
Cloud Run (runs container, scales 0→2 instances)
    ↓
Cloud SQL (managed PostgreSQL, auto-backups)
    ↓
Secret Manager (stores DJANGO_SECRET_KEY, DB_PASSWORD)
```

**Cost: $0 for personal use** (free tier covers all needs).

---

## API Reference

### Authentication

| Endpoint | Method | Auth | Body | Response |
|----------|--------|------|------|----------|
| `/api/auth/signup/` | POST | None | `{username, email, password, phone_number, vehicle_type, role}` | `{token, user}` |
| `/api/auth/login/` | POST | None | `{username, password}` | `{token, user}` |
| `/api/auth/logout/` | POST | Token | — | `{message}` |
| `/api/auth/profile/` | GET | Token | — | `{user}` |
| `/api/auth/change-password/` | POST | Token | `{current_password, new_password}` | `{message, token}` |
| `/api/auth/refresh-token/` | POST | Token | — | `{token}` |

### Trips

| Endpoint | Method | Auth | Body | Response |
|----------|--------|------|------|----------|
| `/trips/api/receive/` | POST | Token | `{speed, speed_limit, latitude, longitude, helmet_worn, ...}` | `{trip, overspeed, risk_score, tags}` |
| `/trips/api/history/` | GET | Token | — | `{username, trips[]}` |
| `/trips/api/zones/` | GET | None | — | `{zones[]}` |
| `/trips/api/weekly-summary/` | GET | Token | — | `{total_trips, overspeed_events, ...}` |
| `/trips/api/vision-observation/` | POST | Token | `{observation_type, label, confidence, latitude, longitude}` | `{observation, guardian_alert_sent}` |

### Alerts

| Endpoint | Method | Auth | Body | Response |
|----------|--------|------|------|----------|
| `/alerts/api/accident-signal/` | POST | Token | `{impact_level, speed_before, speed_after, no_movement_seconds, ...}` | `{risk_score, severity, guardian_alert_sent, alert}` |
| `/alerts/api/register-device/` | POST | Token | `{token, platform}` | `{token, platform, is_active}` |
| `/alerts/api/history/` | GET | Token | — | `{username, alerts[]}` |
| `/alerts/api/test-notification/` | POST | Token | `{location, message, request_call}` | `{message, logs_created}` |

### Health

| Endpoint | Method | Auth | Response |
|----------|--------|------|----------|
| `/api/health/` | GET | None | `{status: "ok"}` |
| `/api/health/ready/` | GET | None | `{status, checks: {database, cache}}` |
| `/api/health/detail/` | GET | Admin | `{version, django_version, checks, stats}` |

---

## How Everything Connects (End-to-End Flow)

### Scenario: Rider starts a trip

```
1. User opens app → AuthGate checks token → shows HomeScreen
2. User taps "Start Tracking"
3. LocationService requests GPS permission → starts position stream
4. SensorService starts accelerometer stream
5. Every GPS update:
   a. Speed displayed on UI (SpeedHero widget)
   b. _checkOverspeed() checks if above 40 km/h for 10s
   c. TripRepository.sendSample() → POST /trips/api/receive/ (with auth token)
   d. Backend calculates risk_score, detects safety zones
   e. AccidentDetector.addTripSample() checks for speed drop
6. Every accelerometer reading:
   a. impactG displayed on UI (MetricCard)
   b. AccidentDetector.addImpact() checks if > 3.2G
7. If impact + speed_drop + low_speed within 8s:
   a. Accident countdown starts (20 seconds)
   b. Local notification: "Possible accident detected"
   c. AlertRepository.sendEvent(status='suspicious') → backend logs it
   d. If user doesn't respond in 20s:
      - AlertRepository.sendEvent(status='confirmed_no_response')
      - Backend: risk_score=100, notify guardian
      - EmergencyService: open SMS + call on phone
      - Backend: send push notification to all registered devices
      - Backend: trigger ambulance webhook if configured
```

---

*Last updated: July 2026*
*Author: RishiPlaysCodes*
