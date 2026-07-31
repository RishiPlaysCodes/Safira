# Safira — Complete Setup, Development & Production Guide

Ye guide me **SAARI commands** hain jo tujhe chahiye — laptop pe test karna ho, phone me build karna ho, ya production me deploy karna ho. Copy-paste karo aur chala do.

---

## Table of Contents

1. [Prerequisites (Ek Baar Install)](#1-prerequisites-ek-baar-install)
2. [Backend — Laptop Pe Test Karna](#2-backend--laptop-pe-test-karna)
3. [Mobile App — Phone Me Build + Install](#3-mobile-app--phone-me-build--install)
4. [Backend + Mobile Together (Full Flow Test)](#4-backend--mobile-together-full-flow-test)
5. [Helmet AI Model Train Karna (Colab)](#5-helmet-ai-model-train-karna-colab)
6. [Production Deployment (Google Cloud — FREE)](#6-production-deployment-google-cloud--free)
7. [All Commands Cheat Sheet](#7-all-commands-cheat-sheet)

---

## 1. Prerequisites (Ek Baar Install)

### Windows PC

| Software | Download Link | Command to Verify |
|----------|--------------|-------------------|
| **Python 3.11+** | https://python.org/downloads | `python --version` |
| **Git** | https://git-scm.com/downloads | `git --version` |
| **Flutter SDK** | https://docs.flutter.dev/get-started/install/windows | `flutter --version` |
| **Android Studio** | https://developer.android.com/studio | (for Android SDK) |
| **VS Code** | https://code.visualstudio.com | (code editor) |

### VS Code Extensions (Install Karo)
- **Flutter** (by Dart Code)
- **Python** (by Microsoft)
- **REST Client** (by Huachao Mao) — API testing ke liye

### After Installing Flutter

```powershell
# Check everything is installed correctly
flutter doctor

# Accept Android licenses (one time)
flutter doctor --android-licenses
# Type 'y' for each prompt

# Verify all green checkmarks
flutter doctor
```

### After Installing Python

```powershell
# Verify Python
python --version
# Should show: Python 3.11.x or higher

# Verify pip
pip --version
```

---

## 2. Backend — Laptop Pe Test Karna

### 2.1 First Time Setup

```powershell
# Open VS Code terminal: Ctrl + `

# Go to project folder (wherever you cloned it)
cd Safira\backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# WINDOWS POWERSHELL:
.\venv\Scripts\Activate.ps1
# WINDOWS CMD:
.\venv\Scripts\activate.bat
# MAC / LINUX:
source venv/bin/activate

# You should see (venv) at the start of your terminal line

# Install all Python packages
pip install -r requirements.txt

# Copy environment file
copy .env.example .env
# MAC/LINUX: cp .env.example .env

# Create database tables
python manage.py migrate

# Create admin user (remember these credentials!)
python manage.py createsuperuser
# Enter: username, email, password (anything you want)
```

### 2.2 Start the Backend (Every Time)

```powershell
# Go to backend folder
cd Safira\backend

# Activate virtual environment
.\venv\Scripts\Activate.ps1

# Start server
python manage.py runserver
```

**Server running at:** http://127.0.0.1:8000

**To stop:** Press `Ctrl + C`

### 2.3 Test Backend APIs (PowerShell)

Open a NEW terminal (keep the server running in the first one):

```powershell
# =============================================
# STEP 1: Create a user (Signup)
# =============================================
$response = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/signup/" -Method POST -ContentType "application/json" -Body '{
  "username": "rishi",
  "email": "rishi@test.com",
  "password": "MyPassword123!",
  "phone_number": "+919876543210",
  "vehicle_type": "bike",
  "role": "driver"
}'
$token = $response.token
Write-Host "YOUR TOKEN: $token"
# COPY THIS TOKEN! You need it for all other requests.

# =============================================
# STEP 2: Login (if you already signed up)
# =============================================
$response = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/login/" -Method POST -ContentType "application/json" -Body '{
  "username": "rishi",
  "password": "MyPassword123!"
}'
$token = $response.token
Write-Host "YOUR TOKEN: $token"

# =============================================
# STEP 3: Set auth headers (use for all requests below)
# =============================================
$headers = @{
  "Authorization" = "Token $token"
  "Content-Type" = "application/json"
}

# =============================================
# STEP 4: Health Check (no auth needed)
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/health/"
# Returns: status = ok

Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/health/ready/"
# Returns: status = healthy

# =============================================
# STEP 5: Send Trip Data (simulate riding at 55 km/h)
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/receive/" -Method POST -Headers $headers -Body '{
  "speed": 55,
  "speed_limit": 40,
  "latitude": 28.6139,
  "longitude": 77.2090,
  "helmet_worn": true,
  "road_type": "normal"
}'
# Returns: overspeed=True, risk_score=30, tags=["overspeed"]

# =============================================
# STEP 6: Send Trip Data (no helmet, red light)
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/receive/" -Method POST -Headers $headers -Body '{
  "speed": 45,
  "speed_limit": 40,
  "latitude": 28.6140,
  "longitude": 77.2091,
  "helmet_worn": false,
  "red_light_crossed": true,
  "harsh_braking": true
}'
# Returns: risk_score=80, tags=["overspeed","helmet-missing","red-light","harsh-braking"]

# =============================================
# STEP 7: Simulate Accident (HIGH severity)
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/accident-signal/" -Method POST -Headers $headers -Body '{
  "impact_level": 9,
  "speed_before": 60,
  "speed_after": 0,
  "no_movement_seconds": 50,
  "phone_angle_changed": true,
  "location": "Near India Gate, Delhi"
}'
# Returns: severity=high, risk_score=100, guardian_alert_sent=true

# =============================================
# STEP 8: User Confirms Accident (EMERGENCY)
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/accident-signal/" -Method POST -Headers $headers -Body '{
  "user_confirmed": true,
  "location": "28.6139,77.2090"
}'
# Returns: severity=confirmed, risk_score=100, ambulance_requested=true

# =============================================
# STEP 9: Helmet Not Worn (Vision Observation)
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/vision-observation/" -Method POST -Headers $headers -Body '{
  "observation_type": "helmet",
  "label": "not_worn",
  "confidence": 0.92,
  "latitude": 28.6139,
  "longitude": 77.2090
}'
# Returns: guardian_alert_sent=true (confidence > 0.8 triggers alert)

# =============================================
# STEP 10: Get Trip History
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/history/" -Headers $headers
# Returns: all your trips with risk scores

# =============================================
# STEP 11: Get Alert History
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/history/" -Headers $headers
# Returns: all accident alerts with severity levels

# =============================================
# STEP 12: Weekly Safety Summary
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/weekly-summary/" -Headers $headers
# Returns: total_trips, overspeed_events, helmet_issues, etc.

# =============================================
# STEP 13: Get Safety Zones (no auth needed)
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/zones/"

# =============================================
# STEP 14: Register Device for Push Notifications
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/register-device/" -Method POST -Headers $headers -Body '{
  "token": "fake-fcm-token-for-testing",
  "platform": "android"
}'

# =============================================
# STEP 15: View Profile
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/profile/" -Headers $headers

# =============================================
# STEP 16: Change Password
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/change-password/" -Method POST -Headers $headers -Body '{
  "current_password": "MyPassword123!",
  "new_password": "NewPassword456!"
}'
# Returns new token (old one is invalidated)

# =============================================
# STEP 17: Logout (invalidates token)
# =============================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/logout/" -Method POST -Headers $headers
# Token is now invalid, need to login again
```

### 2.4 Django Admin Panel

1. Open browser: http://127.0.0.1:8000/admin/
2. Login with your superuser credentials
3. You can:
   - View all users, trips, alerts
   - Add safety zones (name, lat, lon, radius)
   - Check notification logs
   - Create emergency contacts for users

### 2.5 Add Safety Zones (Admin)

1. Go to http://127.0.0.1:8000/admin/
2. Click **"Safety zones" → "Add Safety Zone"**
3. Fill in:
   - Name: "Connaught Place School"
   - Zone type: "School Zone"
   - Latitude: 28.6315
   - Longitude: 77.2167
   - Radius: 300 (meters)
   - Active: checked
4. Save. Now when trip data falls within 300m, rider gets a zone alert.

---

## 3. Mobile App — Phone Me Build + Install

### 3.1 First Time Setup

```powershell
# Go to mobile folder
cd Safira\mobile

# Get Flutter packages
flutter pub get

# Check everything is ready
flutter doctor
# All should be green (or yellow for iOS if you're on Windows — that's fine)
```

### 3.2 Run on Emulator (Testing on Laptop)

```powershell
# List available emulators
flutter emulators

# Launch an emulator (if you have one set up in Android Studio)
flutter emulators --launch Pixel_6_API_34

# OR if a physical device is connected via USB:
flutter devices

# Run in debug mode (hot reload, slower)
flutter run

# Run in release mode (fast, like real app)
flutter run --release
```

### 3.3 Build Release APK (For Phone, No Lag)

```powershell
# Clean previous builds
flutter clean

# Get packages fresh
flutter pub get

# Build release APK (split by phone CPU type — smaller)
flutter build apk --release --split-per-abi

# OR build one universal APK (bigger, works on all phones)
flutter build apk --release
```

### 3.4 Find the APK File

After build finishes:

```
mobile\build\app\outputs\flutter-apk\
├── app-arm64-v8a-release.apk    ← USE THIS (most phones 2017+)
├── app-armeabi-v7a-release.apk  ← Older phones
└── app-x86_64-release.apk       ← Emulators only
```

**Not sure which one?** Use `app-arm64-v8a-release.apk` — 95% phones today are arm64.

### 3.5 Transfer APK to Phone (No USB Debugging Needed)

| Method | Steps |
|--------|-------|
| **Google Drive** | Upload APK to Drive on PC → Open Drive app on phone → Download → Install |
| **WhatsApp** | Open WhatsApp Web → Send APK to yourself ("Message yourself") → Download on phone |
| **Telegram** | Send to "Saved Messages" → Download on phone |
| **Email** | Email APK as attachment → Open email on phone → Download |
| **USB (just copy)** | Plug phone → Select "File Transfer" → Drag APK to Downloads → Done |

### 3.6 Install APK on Phone

1. Open the APK (from Downloads / file manager)
2. Android asks: "Can't install from this source"
3. Tap **Settings** → Toggle **"Allow from this source"** ON
4. Go back → Tap **Install**
5. Open **SafeRide Guardian** from app drawer

### 3.7 First Run on Phone

1. **Login Screen** appears:
   - Backend URL: `http://192.168.x.x:8000` (your PC's IP, same WiFi)
     OR `https://safira-backend-xxx.a.run.app` (if deployed)
   - Tap "New user? Create an account"
   - Fill username, email, password (10+ chars), guardian phone
   - Tap **Create Account**

2. **Home Screen:**
   - Grant **Location** permission → "Allow all the time"
   - Grant **Notification** permission
   - Tap **Start Tracking** → You'll see speed update as you move

3. **Test Features:**
   - Walk around → Speed shows in km/h
   - Shake phone hard → Impact G increases
   - Tap **Manual SOS** → Opens SMS + Call to guardian
   - Tap **Live Helmet Detection** → Camera opens (needs model file)

---

## 4. Backend + Mobile Together (Full Flow Test)

### Setup (Same WiFi)

**Terminal 1 (Backend):**
```powershell
cd Safira\backend
.\venv\Scripts\Activate.ps1
python manage.py runserver 0.0.0.0:8000
```
> `0.0.0.0` means the server accepts connections from any device on your network.

**Find your PC's IP:**
```powershell
# Windows
ipconfig
# Look for: IPv4 Address: 192.168.1.X (under Wi-Fi adapter)

# Mac/Linux
ifconfig | grep "inet "
```

**In the mobile app login screen, enter:**
```
http://192.168.1.X:8000
```
(Replace X with your actual IP number)

### Test Scenarios

| Scenario | How to Test | Expected Result |
|----------|-------------|-----------------|
| Normal ride | Walk with phone (app tracking) | Speed shows, trip recorded on backend |
| Overspeed | Drive/cycle above 40 km/h for 10s | Local notification "Overspeed warning" |
| Accident | Shake phone hard + stop suddenly | Countdown starts, notification appears |
| Mark safe | Tap "I am safe" during countdown | Countdown stops, no alert sent |
| Confirm accident | Let countdown finish OR tap "Alert now" | SMS app opens with location, call opens |
| Manual SOS | Tap "Manual SOS" button | Immediate SMS + Call to guardian |
| Helmet missing | Tap "Helmet missing" button | Backend records vision observation, guardian alerted |
| Safety zones | Add zone in admin → send trip within radius | Zone alert in alert history |
| Weekly report | After some trips, check weekly summary | Stats shown via API |
| Offline mode | Turn off WiFi → ride → turn WiFi on | Trips queued offline, synced when online |

---

## 5. Helmet AI Model Train Karna (Colab)

### Step 1: Open Notebook

Browser me ye link paste karo:
```
https://colab.research.google.com/github/RishiPlaysCodes/Safira/blob/feat/production-readiness-v2/ai_training/helmet_detection_colab.ipynb
```

### Step 2: GPU Select Karo
- **Runtime → Change runtime type → T4 GPU → Save**

### Step 3: Run All
- **Runtime → Run all** (Ctrl+F9)
- Warning aaye: "Run anyway"

### Step 4: Wait 15-20 min
- Dataset download: ~2 min
- Training: ~12-15 min
- Export: ~1 min
- Auto-download: `helmet_detector.tflite`

### Step 5: Put in Flutter App
```powershell
# Copy downloaded file to app assets
copy ~\Downloads\helmet_detector.tflite Safira\mobile\assets\models\

# Rebuild APK
cd Safira\mobile
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

### Step 6: Install + Test
- Transfer new APK to phone
- Open app → "Live Helmet Detection" button
- Point camera at someone with/without helmet
- Green box = helmet, Red box + flash = no helmet

---

## 6. Production Deployment (Google Cloud — FREE)

### One-Time Setup

```bash
# Install Google Cloud CLI
# Windows: Download from https://cloud.google.com/sdk/docs/install
# After install, open new terminal:

# Login
gcloud auth login

# Create project
gcloud projects create safira-app --name="Safira"
gcloud config set project safira-app

# Link billing (free trial $300 credit)
gcloud billing accounts list
# Copy the ACCOUNT_ID from output
gcloud billing projects link safira-app --billing-account=YOUR_ACCOUNT_ID

# Enable services
gcloud services enable run.googleapis.com sqladmin.googleapis.com cloudbuild.googleapis.com artifactregistry.googleapis.com secretmanager.googleapis.com
```

### Create Database

```bash
# Create PostgreSQL instance (~3-5 min)
gcloud sql instances create safira-db \
  --database-version=POSTGRES_15 \
  --tier=db-f1-micro \
  --region=asia-south1 \
  --storage-size=10 \
  --storage-type=HDD

# Create database
gcloud sql databases create saferide --instance=safira-db

# Set password
gcloud sql users set-password postgres \
  --instance=safira-db \
  --password=YourStrongDBPassword123
```

### Store Secrets

```bash
# Generate Django secret key
python -c "import secrets; print(secrets.token_urlsafe(50))"
# Copy the output

# Store it
echo -n "YOUR_GENERATED_KEY" | gcloud secrets create django-secret-key --data-file=-

# Store DB password
echo -n "YourStrongDBPassword123" | gcloud secrets create db-password --data-file=-
```

### Build + Deploy

```bash
# Create image repository
gcloud artifacts repositories create safira-repo \
  --repository-format=docker \
  --location=asia-south1

# Build Docker image in the cloud
cd Safira/backend
gcloud builds submit --tag asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest

# Deploy to Cloud Run
gcloud run deploy safira-backend \
  --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest \
  --platform=managed \
  --region=asia-south1 \
  --allow-unauthenticated \
  --port=8000 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=2 \
  --set-env-vars="DJANGO_DEBUG=False,DJANGO_ALLOWED_HOSTS=*,DB_ENGINE=django.db.backends.postgresql,DB_NAME=saferide,DB_USER=postgres,DB_HOST=/cloudsql/safira-app:asia-south1:safira-db,DB_PORT=5432,NOTIFICATION_PROVIDER=free,VISION_PROVIDER=free_manual" \
  --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest,DB_PASSWORD=db-password:latest" \
  --add-cloudsql-instances=safira-app:asia-south1:safira-db
```

### Run Migrations + Create Admin

```bash
# Run migrations
gcloud run jobs create migrate \
  --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest \
  --region=asia-south1 \
  --set-env-vars="DJANGO_DEBUG=False,DB_ENGINE=django.db.backends.postgresql,DB_NAME=saferide,DB_USER=postgres,DB_HOST=/cloudsql/safira-app:asia-south1:safira-db,DB_PORT=5432,NOTIFICATION_PROVIDER=free" \
  --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest,DB_PASSWORD=db-password:latest" \
  --add-cloudsql-instances=safira-app:asia-south1:safira-db \
  --command="python" \
  --args="manage.py,migrate,--noinput"

gcloud run jobs execute migrate --region=asia-south1 --wait

# Create admin user
gcloud run jobs create create-admin \
  --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest \
  --region=asia-south1 \
  --set-env-vars="DJANGO_DEBUG=False,DB_ENGINE=django.db.backends.postgresql,DB_NAME=saferide,DB_USER=postgres,DB_HOST=/cloudsql/safira-app:asia-south1:safira-db,DB_PORT=5432,DJANGO_SUPERUSER_USERNAME=admin,DJANGO_SUPERUSER_EMAIL=your@email.com,DJANGO_SUPERUSER_PASSWORD=YourAdminPass123!,NOTIFICATION_PROVIDER=free" \
  --set-secrets="DJANGO_SECRET_KEY=django-secret-key:latest,DB_PASSWORD=db-password:latest" \
  --add-cloudsql-instances=safira-app:asia-south1:safira-db \
  --command="python" \
  --args="manage.py,createsuperuser,--noinput"

gcloud run jobs execute create-admin --region=asia-south1 --wait
```

### Get Your Live URL

```bash
gcloud run services describe safira-backend --region=asia-south1 --format="value(status.url)"
# Output: https://safira-backend-xxxxx-el.a.run.app
```

### Test Production

```bash
# Health check
curl https://safira-backend-xxxxx-el.a.run.app/api/health/

# Signup
curl -X POST https://safira-backend-xxxxx-el.a.run.app/api/auth/signup/ \
  -H "Content-Type: application/json" \
  -d '{"username":"rishi","email":"rishi@test.com","password":"MyPassword123!","phone_number":"+919876543210","vehicle_type":"bike","role":"driver"}'
```

### Update After Code Changes

```bash
cd Safira/backend

# Rebuild
gcloud builds submit --tag asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest

# Redeploy
gcloud run deploy safira-backend \
  --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest \
  --region=asia-south1

# Run migrations (if models changed)
gcloud run jobs execute migrate --region=asia-south1 --wait
```

---

## 7. All Commands Cheat Sheet

### Backend (Local)

```powershell
# Start
cd Safira\backend
.\venv\Scripts\Activate.ps1
python manage.py runserver              # localhost only
python manage.py runserver 0.0.0.0:8000 # for phone access

# Database
python manage.py migrate                # apply new migrations
python manage.py createsuperuser        # create admin

# New dependency added?
pip install -r requirements.txt
```

### Mobile App

```powershell
# Setup
cd Safira\mobile
flutter pub get

# Run (debug mode, on connected device/emulator)
flutter run
flutter run --release    # fast mode

# Build APK
flutter clean
flutter pub get
flutter build apk --release --split-per-abi

# APK is at:
# mobile\build\app\outputs\flutter-apk\app-arm64-v8a-release.apk

# Run tests
flutter test
```

### Google Cloud

```bash
# Login
gcloud auth login

# Build + deploy
cd Safira/backend
gcloud builds submit --tag asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest
gcloud run deploy safira-backend --image=asia-south1-docker.pkg.dev/safira-app/safira-repo/backend:latest --region=asia-south1

# Migrations
gcloud run jobs execute migrate --region=asia-south1 --wait

# Logs
gcloud run services logs read safira-backend --region=asia-south1 --limit=50

# Stop (save credits)
gcloud run services delete safira-backend --region=asia-south1
gcloud sql instances patch safira-db --activation-policy=NEVER
```

### Git

```powershell
# Pull latest code
cd Safira
git checkout feat/production-readiness-v2
git pull origin feat/production-readiness-v2

# Merge to main (when ready for production)
git checkout main
git merge feat/production-readiness-v2
git push origin main
```

---

## Common Errors + Fixes

| Error | Fix |
|-------|-----|
| `python: command not found` | Install Python, add to PATH, restart terminal |
| `flutter: command not found` | Install Flutter SDK, add to PATH |
| `DJANGO_SECRET_KEY required` | Run `copy .env.example .env` in backend folder |
| `No module named 'corsheaders'` | `pip install -r requirements.txt` |
| `OperationalError: no such table` | `python manage.py migrate` |
| `flutter build` fails on licenses | `flutter doctor --android-licenses` accept all |
| Can't connect from phone | Use `0.0.0.0:8000` + your PC IP + same WiFi |
| "App not installed" on phone | Uninstall old version first |
| Token error / 401 | Login again to get a new token |
| Colab GPU not available | Runtime → Change runtime → T4 GPU |
| `gcloud: command not found` | Install Google Cloud SDK, restart terminal |

---

*Yahi hai poori guide. Save karke rakh. Koi step pe atka toh screenshot bhej.*
