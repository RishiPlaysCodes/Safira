# Safira - SafeRide Guardian

Real-time motorcycle safety platform with accident detection, GPS tracking, emergency alerts, and AI-powered vision analysis.

## Architecture

```
Mobile App (Flutter)  <-->  Django REST API  <-->  PostgreSQL
     |                          |
     |-- GPS + Sensors          |-- Firebase Push Notifications
     |-- Camera (Vision AI)     |-- Twilio SMS/Call
     |-- Offline Queue          |-- Ambulance Webhook
                                |-- Redis Cache
```

## Features

- **Real-time GPS Tracking** — Speed monitoring, route recording, safety zone detection
- **Accident Detection** — Impact sensor + speed drop + no-movement analysis
- **Emergency Alerts** — Auto-notify guardian via SMS, call, push notification
- **Vision AI** — Helmet detection, red-light violation, traffic density
- **Safety Zones** — Geofenced school/hospital/market zones with auto-warnings
- **Weekly Reports** — Safety score, violation stats, risk analysis
- **Ambulance Integration** — Webhook-based dispatch for confirmed accidents

## Tech Stack

| Component | Technology |
|-----------|-----------|
| Backend | Django 5.1 + Django REST Framework |
| Database | PostgreSQL 16 (SQLite for dev) |
| Cache | Redis 7 |
| Mobile | Flutter 3.x (Android + iOS) |
| Push Notifications | Firebase Cloud Messaging |
| SMS/Call | Twilio (optional) |
| Deployment | Docker + Nginx + Gunicorn |
| Monitoring | Sentry + structured logging |

---

## Quick Start (Local Development)

### Prerequisites

- Python 3.11+ 
- Flutter 3.x SDK
- Git

### Backend Setup

```bash
# 1. Clone the repo
git clone https://github.com/RishiPlaysCodes/Safira.git
cd Safira/backend

# 2. Create virtual environment
python -m venv venv

# On Windows:
venv\Scripts\activate
# On Mac/Linux:
source venv/bin/activate

# 3. Install dependencies
pip install -r requirements.txt

# 4. Setup environment
cp .env.example .env
# The .env.example has SQLite + DEBUG mode defaults, works out of the box

# 5. Run migrations
python manage.py migrate

# 6. Create admin user
python manage.py createsuperuser

# 7. Start development server
python manage.py runserver
```

Backend will be running at: `http://127.0.0.1:8000`

### Mobile App Setup

```bash
cd Safira/mobile

# 1. Get dependencies
flutter pub get

# 2. Run on connected device/emulator
flutter run

# 3. For release build
flutter build apk --release
```

### Test the API

```bash
# 1. Register a user
curl -X POST http://127.0.0.1:8000/api/auth/signup/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "email": "test@example.com",
    "password": "MySecure123!",
    "phone_number": "+911234567890",
    "vehicle_type": "bike",
    "role": "driver"
  }'

# Response: {"token": "abc123...", "user": {...}}

# 2. Use the token for authenticated requests
curl -X POST http://127.0.0.1:8000/trips/api/receive/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token abc123..." \
  -d '{
    "speed": 45,
    "speed_limit": 40,
    "latitude": 28.6139,
    "longitude": 77.2090,
    "helmet_worn": true
  }'

# 3. Check health
curl http://127.0.0.1:8000/api/health/
# Response: {"status": "ok"}
```

---

## API Documentation

### Authentication

All API endpoints (except health + safety zones) require token authentication:

```
Authorization: Token <your-token-here>
```

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/auth/signup/` | Register new user |
| POST | `/api/auth/login/` | Login, get token |
| POST | `/api/auth/logout/` | Invalidate token |
| GET | `/api/auth/profile/` | Get user profile |
| POST | `/api/auth/change-password/` | Change password |
| POST | `/api/auth/refresh-token/` | Rotate token |

### Trips

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/trips/api/receive/` | Send trip telemetry |
| GET | `/trips/api/history/` | Get trip history |
| GET | `/trips/api/zones/` | Get safety zones (public) |
| GET | `/trips/api/weekly-summary/` | Weekly safety summary |
| POST | `/trips/api/vision-observation/` | Submit vision AI result |

### Alerts

| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/alerts/api/accident-signal/` | Send accident signal |
| POST | `/alerts/api/register-device/` | Register FCM device |
| GET | `/alerts/api/history/` | Get alert history |
| POST | `/alerts/api/test-notification/` | Test notification |

### Health

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/api/health/` | Liveness probe |
| GET | `/api/health/ready/` | Readiness (DB+cache check) |
| GET | `/api/health/detail/` | Detailed stats (admin) |

---

## Deployment

See **[DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)** for complete Google Cloud deployment instructions (free tier).

### Quick Docker Deployment

```bash
# 1. Configure environment
cp .env.example .env
# Edit .env with your production values

# 2. Start all services
docker compose up -d

# 3. Create admin user
docker compose exec backend python manage.py createsuperuser

# 4. Check health
curl http://localhost/api/health/ready/
```

---

## Project Structure

```
Safira/
├── backend/                    # Django REST API
│   ├── alerts/                 # Emergency alert system
│   ├── trips/                  # Trip tracking & safety zones
│   ├── users/                  # Authentication & profiles
│   ├── integrations/           # External services (Twilio, Firebase)
│   ├── saferide/               # Django project settings
│   ├── Dockerfile              # Production container
│   └── requirements.txt        # Python dependencies
├── mobile/                     # Flutter mobile app
│   ├── lib/
│   │   ├── features/           # UI screens
│   │   ├── models/             # Data models
│   │   ├── repositories/       # API communication layer
│   │   └── services/           # Business logic services
│   └── pubspec.yaml
├── nginx/                      # Nginx reverse proxy config
├── docker-compose.yml          # Full stack orchestration
└── DEPLOYMENT_GUIDE.md         # Google Cloud deployment
```

---

## Environment Variables

See `.env.example` for all variables. Key ones:

| Variable | Required | Description |
|----------|----------|-------------|
| `DJANGO_SECRET_KEY` | Yes | Django secret key (generate unique) |
| `DJANGO_DEBUG` | No | `True` for dev, `False` for prod |
| `DB_ENGINE` | No | `sqlite3` for dev, `postgresql` for prod |
| `FIREBASE_CREDENTIALS_PATH` | No | Path to Firebase JSON key |
| `NOTIFICATION_PROVIDER` | No | `free` (simulated) or `twilio` |

---

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-feature`)
3. Commit changes (`git commit -m "feat: add my feature"`)
4. Push to branch (`git push origin feat/my-feature`)
5. Open a Pull Request

---

## License

This project is for educational and personal use.
