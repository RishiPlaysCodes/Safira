# SafeRide Guardian - Build APK & Install on Your Phone (FREE, No USB Debugging)

Yeh guide batata hai kaise **release APK** banaye aur apne phone me install kare — bina USB debugging, bina paise, aur bina lag ke.

> **Lag kyun nahi hoga?** Debug build (`flutter run`) slow hota hai. **Release APK** fast + optimized hota hai — bilkul Play Store app jaisa smooth.

---

## Step 0: One-Time Setup

Install these on your PC (Windows/Mac/Linux):

1. **Flutter SDK** — https://docs.flutter.dev/get-started/install
2. **Android Studio** (for Android SDK + build tools) — https://developer.android.com/studio

Verify everything is ready:

```bash
flutter doctor
```

Fix anything that shows a red ✗ (usually "Android licenses" — run `flutter doctor --android-licenses` and accept all).

---

## Step 1: Point the App at Your Backend

The app needs a backend URL. Two free options:

### Option A — Backend on Google Cloud (recommended, works anywhere)
Deploy the backend first using **[../DEPLOYMENT_GUIDE.md](../DEPLOYMENT_GUIDE.md)**. You'll get a URL like:
```
https://safira-backend-xxxxx.a.run.app
```
Use this in the app's login screen. Works on mobile data + any WiFi.

### Option B — Backend on your PC (same WiFi only, fully free)
1. Find your PC's local IP:
   ```bash
   # Windows
   ipconfig        # look for IPv4 Address, e.g. 192.168.1.5
   # Mac/Linux
   ifconfig | grep "inet "
   ```
2. Run Django so the phone can reach it:
   ```bash
   cd backend
   python manage.py runserver 0.0.0.0:8000
   ```
3. In the app login screen, enter: `http://192.168.1.5:8000` (your PC's IP)

> Phone and PC must be on the **same WiFi** for Option B.

---

## Step 2: Build the Release APK

```bash
cd mobile

# Clean any old builds
flutter clean

# Get packages
flutter pub get

# Build smaller APKs, one per phone type (recommended - smaller file)
flutter build apk --release --split-per-abi
```

**OR** build a single universal APK (bigger, but works on any phone):

```bash
flutter build apk --release
```

### Where is the APK?

After the build finishes, your APK is here:

```
mobile/build/app/outputs/flutter-apk/
```

- `app-arm64-v8a-release.apk`  ← use this for most modern phones (2017+)
- `app-armeabi-v7a-release.apk` ← older phones
- `app-release.apk`            ← universal (if you didn't use --split-per-abi)

> **Not sure which one?** Use `app-arm64-v8a-release.apk`. Almost all phones today are arm64.

---

## Step 3: Transfer APK to Your Phone (Wireless, No USB Debugging)

Pick **any** free method:

| Method | How |
|--------|-----|
| **Google Drive** | Upload APK to Drive on PC → open Drive app on phone → download |
| **WhatsApp** | Message the APK to yourself ("Message yourself" feature) → download on phone |
| **Telegram** | Send to "Saved Messages" → download on phone |
| **Email** | Email the APK to yourself → open on phone → download attachment |
| **USB cable (copy only)** | Plug phone in as "File Transfer" → drag APK into Downloads folder. (This is NOT USB debugging — just copying a file.) |

---

## Step 4: Install the APK on Your Phone

1. Open the APK file on your phone (from Downloads / Files app / the app you transferred it with).
2. Android will say **"For your security, your phone can't install unknown apps from this source."**
3. Tap **Settings** → toggle **Allow from this source** ON.
4. Go back → tap **Install**.
5. Done! Open **SafeRide Guardian** from your app drawer.

> This is called "sideloading" — completely normal and free. No developer account or Play Store needed.

---

## Step 5: First Run

1. Open the app → you'll see the **Login screen**.
2. Tap **"New user? Create an account"**.
3. Fill in:
   - **Backend URL** — your Cloud Run URL or `http://<PC-IP>:8000`
   - **Username**, **Email**, **Guardian phone** (parent's number), **Password** (10+ chars)
4. Tap **Create Account** → you're in!
5. Grant **Location** permission (choose **"Allow all the time"** for background tracking).
6. Grant **Notifications** permission.
7. Tap **Start Tracking** and go for a ride 🏍️

---

## What Works Without Any Paid Service

| Feature | Works Free? | Notes |
|---------|-------------|-------|
| GPS speed tracking | ✅ | Uses phone GPS |
| Overspeed warning | ✅ | Local notification when you exceed limit |
| Accident detection | ✅ | Impact + speed-drop + no-movement sensors |
| Emergency SMS/Call to guardian | ✅ | Opens your phone's SMS/dialer |
| Live map (route) | ✅ | OpenStreetMap - no API key, no cost |
| Alert history / weekly report | ✅ | Stored on your backend |
| Push notifications (FCM) | ⚠️ Optional | Needs free Firebase setup (see below) |
| Camera helmet detection (auto) | ⚠️ Manual for now | Buttons simulate it; real on-device ML model needs to be trained + added |

---

## Optional: Enable Push Notifications (Free Firebase)

Only if you want the backend to push alerts to the phone:

1. Go to https://console.firebase.google.com (free)
2. Create a project → Add an **Android app** with package name `com.example.saferide_mobile`
3. Download `google-services.json`
4. Put it in: `mobile/android/app/google-services.json`
5. Rebuild the APK (Step 2)

The app auto-detects the file and turns on push notifications. Without it, everything else still works.

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| `flutter build apk` fails on licenses | `flutter doctor --android-licenses` → accept all |
| "App not installed" on phone | Uninstall any old version first; ensure enough storage |
| App opens but "Network error" | Check backend URL; if using PC, ensure same WiFi + `runserver 0.0.0.0:8000` |
| "Session expired" | Login again (token refresh) |
| No GPS speed | Go outdoors; grant "Allow all the time" location |
| Overspeed/accident notification not showing | Grant Notifications permission in phone settings |
| APK too big | Use `--split-per-abi` and install the `arm64-v8a` one |

---

## Quick Command Reference

```bash
# Build release APK (split by phone type - recommended)
cd mobile
flutter clean && flutter pub get
flutter build apk --release --split-per-abi

# APK location:
# mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk

# Run tests before building (optional)
flutter test
```
