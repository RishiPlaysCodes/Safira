# Safira - Local Testing Guide (VS Code)

VS Code me project test karne ke liye step-by-step commands.

---

## One-Time Setup (Pehli Baar)

### 1. Open Project in VS Code

```bash
# Clone (agar nahi kiya hai)
git clone https://github.com/RishiPlaysCodes/Safira.git
cd Safira

# Open in VS Code
code .
```

### 2. Backend Setup (Terminal 1)

VS Code me new terminal open kar: `` Ctrl + ` `` ya `Terminal > New Terminal`

```bash
# Go to backend folder
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# Windows PowerShell:
.\venv\Scripts\Activate.ps1
# Windows CMD:
.\venv\Scripts\activate.bat
# Mac/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env

# Run database migrations
python manage.py migrate

# Create your admin user
python manage.py createsuperuser
# Username: admin
# Email: your@email.com
# Password: (kuch bhi strong)

# Start server
python manage.py runserver
```

**Server running at:** http://127.0.0.1:8000

### 3. Mobile App Setup (Terminal 2)

VS Code me second terminal open kar: `Terminal > New Terminal`

```bash
cd mobile

# Get Flutter packages
flutter pub get

# Check connected devices
flutter devices

# Run app (on connected phone or emulator)
flutter run
```

---

## Testing Commands (Har Baar Use Karna)

### Start Backend (Terminal 1)

```bash
cd backend
.\venv\Scripts\Activate.ps1     # Windows
# source venv/bin/activate      # Mac/Linux
python manage.py runserver
```

### Run Mobile App (Terminal 2)

```bash
cd mobile
flutter run
```

---

## API Testing (VS Code Terminal ya Postman)

### Option A: VS Code Terminal (curl commands)

**Windows PowerShell me `curl` slightly different hota hai, use `Invoke-RestMethod`:**

```powershell
# ========================================
# 1. SIGNUP - Register a new user
# ========================================
$signup = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/signup/" -Method POST -ContentType "application/json" -Body '{
  "username": "rishi",
  "email": "rishi@test.com",
  "password": "TestPass123!",
  "phone_number": "+919876543210",
  "vehicle_type": "bike",
  "role": "driver"
}'
Write-Host "Token: $($signup.token)"
# SAVE THIS TOKEN! You'll need it for all other requests

# ========================================
# 2. LOGIN (if already registered)
# ========================================
$login = Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/login/" -Method POST -ContentType "application/json" -Body '{
  "username": "rishi",
  "password": "TestPass123!"
}'
$token = $login.token
Write-Host "Token: $token"

# ========================================
# 3. CHECK HEALTH
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/health/"
# Returns: status = ok

Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/health/ready/"
# Returns: status = healthy, checks = {database, cache}

# ========================================
# 4. SEND TRIP DATA (simulates riding)
# ========================================
$headers = @{ Authorization = "Token $token"; "Content-Type" = "application/json" }

Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/receive/" -Method POST -Headers $headers -Body '{
  "speed": 45,
  "speed_limit": 40,
  "latitude": 28.6139,
  "longitude": 77.2090,
  "helmet_worn": true,
  "road_type": "normal"
}'
# Returns: trip data, overspeed=true, risk_score

# ========================================
# 5. SEND ACCIDENT SIGNAL
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/accident-signal/" -Method POST -Headers $headers -Body '{
  "impact_level": 9,
  "speed_before": 60,
  "speed_after": 0,
  "no_movement_seconds": 50,
  "phone_angle_changed": true,
  "location": "28.6139,77.2090"
}'
# Returns: risk_score, severity, guardian_alert_sent

# ========================================
# 6. GET TRIP HISTORY
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/history/" -Headers $headers

# ========================================
# 7. GET WEEKLY SUMMARY
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/weekly-summary/" -Headers $headers

# ========================================
# 8. GET ALERT HISTORY
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/history/" -Headers $headers

# ========================================
# 9. SEND VISION OBSERVATION (helmet check)
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/vision-observation/" -Method POST -Headers $headers -Body '{
  "observation_type": "helmet",
  "label": "not_worn",
  "confidence": 0.92,
  "latitude": 28.6139,
  "longitude": 77.2090
}'

# ========================================
# 10. GET SAFETY ZONES (no auth needed)
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/zones/"

# ========================================
# 11. REGISTER DEVICE FOR PUSH (fake token)
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/register-device/" -Method POST -Headers $headers -Body '{
  "token": "fake-fcm-token-for-testing-12345",
  "platform": "android"
}'

# ========================================
# 12. VIEW PROFILE
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/profile/" -Headers $headers

# ========================================
# 13. LOGOUT (invalidates token)
# ========================================
Invoke-RestMethod -Uri "http://127.0.0.1:8000/api/auth/logout/" -Method POST -Headers $headers
```

### Option B: Git Bash / Mac / Linux (curl)

```bash
# Signup
curl -X POST http://127.0.0.1:8000/api/auth/signup/ \
  -H "Content-Type: application/json" \
  -d '{"username":"rishi","email":"rishi@test.com","password":"TestPass123!","phone_number":"+919876543210","vehicle_type":"bike","role":"driver"}'

# Save the token from response
TOKEN="paste-your-token-here"

# Login
curl -X POST http://127.0.0.1:8000/api/auth/login/ \
  -H "Content-Type: application/json" \
  -d '{"username":"rishi","password":"TestPass123!"}'

# Health check
curl http://127.0.0.1:8000/api/health/

# Send trip data
curl -X POST http://127.0.0.1:8000/trips/api/receive/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $TOKEN" \
  -d '{"speed":45,"speed_limit":40,"latitude":28.6139,"longitude":77.2090,"helmet_worn":true}'

# Send accident signal
curl -X POST http://127.0.0.1:8000/alerts/api/accident-signal/ \
  -H "Content-Type: application/json" \
  -H "Authorization: Token $TOKEN" \
  -d '{"impact_level":9,"speed_before":60,"speed_after":0,"no_movement_seconds":50,"phone_angle_changed":true,"location":"28.6139,77.2090"}'

# Trip history
curl -H "Authorization: Token $TOKEN" http://127.0.0.1:8000/trips/api/history/

# Alert history
curl -H "Authorization: Token $TOKEN" http://127.0.0.1:8000/alerts/api/history/
```

### Option C: REST Client Extension (VS Code)

Install the **REST Client** extension in VS Code, then create a file `test.http`:

```http
### Health Check
GET http://127.0.0.1:8000/api/health/

### Signup
POST http://127.0.0.1:8000/api/auth/signup/
Content-Type: application/json

{
  "username": "rishi",
  "email": "rishi@test.com",
  "password": "TestPass123!",
  "phone_number": "+919876543210",
  "vehicle_type": "bike",
  "role": "driver"
}

### Login
POST http://127.0.0.1:8000/api/auth/login/
Content-Type: application/json

{
  "username": "rishi",
  "password": "TestPass123!"
}

### Send Trip Data (replace token below)
POST http://127.0.0.1:8000/trips/api/receive/
Content-Type: application/json
Authorization: Token YOUR_TOKEN_HERE

{
  "speed": 55,
  "speed_limit": 40,
  "latitude": 28.6139,
  "longitude": 77.2090,
  "helmet_worn": false
}

### Accident Signal
POST http://127.0.0.1:8000/alerts/api/accident-signal/
Content-Type: application/json
Authorization: Token YOUR_TOKEN_HERE

{
  "impact_level": 9,
  "speed_before": 60,
  "speed_after": 0,
  "no_movement_seconds": 50,
  "phone_angle_changed": true,
  "location": "Near India Gate, Delhi"
}

### Trip History
GET http://127.0.0.1:8000/trips/api/history/
Authorization: Token YOUR_TOKEN_HERE

### Weekly Summary
GET http://127.0.0.1:8000/trips/api/weekly-summary/
Authorization: Token YOUR_TOKEN_HERE

### Alert History
GET http://127.0.0.1:8000/alerts/api/history/
Authorization: Token YOUR_TOKEN_HERE

### Profile
GET http://127.0.0.1:8000/api/auth/profile/
Authorization: Token YOUR_TOKEN_HERE

### Safety Zones (public, no auth needed)
GET http://127.0.0.1:8000/trips/api/zones/
```

Click "Send Request" above each request to test!

---

## Django Admin Panel

1. Go to: http://127.0.0.1:8000/admin/
2. Login with your superuser credentials
3. Here you can:
   - View all users, trips, alerts
   - Add safety zones manually
   - Check notification logs
   - Manage emergency contacts

---

## Mobile App + Backend Together

### Android Emulator

Backend URL in mobile app settings: `http://10.0.2.2:8000`

(10.0.2.2 is how Android emulator accesses your PC's localhost)

### Physical Phone (same WiFi)

1. Find your PC's IP:
   ```bash
   # Windows
   ipconfig
   # Look for "IPv4 Address" under your WiFi adapter (e.g., 192.168.1.5)
   
   # Mac/Linux
   ifconfig | grep "inet "
   ```

2. Run Django with your IP:
   ```bash
   python manage.py runserver 0.0.0.0:8000
   ```

3. In mobile app settings, enter: `http://192.168.1.5:8000`
   (replace with your actual IP)

---

## Quick Test Scenarios

### Scenario 1: Normal Ride (Low Risk)
```powershell
# Speed within limit, helmet worn
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/receive/" -Method POST -Headers $headers -Body '{
  "speed": 30, "speed_limit": 40, "helmet_worn": true, "latitude": 28.61, "longitude": 77.20
}'
# Expected: risk_score = 0, overspeed = false
```

### Scenario 2: Overspeed + No Helmet (High Risk)
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:8000/trips/api/receive/" -Method POST -Headers $headers -Body '{
  "speed": 80, "speed_limit": 40, "helmet_worn": false, "red_light_crossed": true, "latitude": 28.61, "longitude": 77.20
}'
# Expected: risk_score = 80, overspeed = true, tags include overspeed,helmet-missing,red-light
```

### Scenario 3: Accident Detected (Guardian Alert)
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/accident-signal/" -Method POST -Headers $headers -Body '{
  "impact_level": 9, "speed_before": 60, "speed_after": 0, "no_movement_seconds": 50, "phone_angle_changed": true
}'
# Expected: severity = high, guardian_alert_sent = true, risk_score >= 75
```

### Scenario 4: User Confirms Accident (Emergency)
```powershell
Invoke-RestMethod -Uri "http://127.0.0.1:8000/alerts/api/accident-signal/" -Method POST -Headers $headers -Body '{
  "user_confirmed": true, "location": "Near India Gate"
}'
# Expected: severity = confirmed, ambulance_requested = true, risk_score = 100
```

---

## Common Issues

| Problem | Solution |
|---------|----------|
| `ModuleNotFoundError` | `pip install -r requirements.txt` |
| `DJANGO_SECRET_KEY required` | `cp .env.example .env` |
| `No module named 'corsheaders'` | `pip install django-cors-headers` |
| `flutter run` fails | `flutter pub get` first |
| Can't connect from phone | Use `runserver 0.0.0.0:8000` and your IP |
| Token expired/invalid | Login again to get new token |
| `OperationalError: no such table` | `python manage.py migrate` |
