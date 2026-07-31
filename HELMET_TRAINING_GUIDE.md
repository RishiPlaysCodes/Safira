# Helmet Detection Model - Complete Training Guide

Ye guide batata hai kaise **15-20 minutes me** apna helmet detection ML model train kare (FREE, Google Colab pe) aur usse Flutter app me integrate kare.

## Result

Jab ye complete hoga:
- Phone camera se **real-time helmet detect** hoga (20+ FPS)
- **Bina internet ke kaam karega** (on-device, offline)
- Agar rider bina helmet ke hai → guardian ko alert jayega
- Model size: ~6 MB

---

## Step 1: Get a Free Kaggle Account (2 min)

1. Go to https://www.kaggle.com
2. Sign up (free, Google account se bhi ho jayega)
3. Go to **Settings** (top-right avatar → Settings)
4. Scroll down to **API** section → Click **"Create New Token"**
5. `kaggle.json` file download hogi — **isse save karke rakh**

---

## Step 2: Open the Training Notebook in Google Colab (1 min)

1. Go to your project folder: `ai_training/helmet_detection_colab.ipynb`
2. Upload it to Google Colab:
   - Go to https://colab.research.google.com
   - Click **File → Upload Notebook**
   - Select `helmet_detection_colab.ipynb`

3. **IMPORTANT:** Change runtime to GPU:
   - Click **Runtime → Change runtime type**
   - Select **T4 GPU** (free tier)
   - Click **Save**

---

## Step 3: Run the Notebook (15-20 min)

Click **Runtime → Run all** (or Ctrl+F9).

The notebook will:
1. Install dependencies (ultralytics, etc.)
2. Ask you to upload `kaggle.json` — upload the file from Step 1
3. Download the helmet dataset from Kaggle (~5000 images)
4. Convert annotations to YOLO format
5. Split into train/val/test (70/20/10)
6. Train YOLOv8-nano for 50 epochs
7. Evaluate accuracy (should be mAP50 > 0.7)
8. Export to TFLite (FP16 quantized)
9. Auto-download `helmet_detector.tflite` to your computer

**What to expect:**
- Dataset download: ~2 min
- Training: ~10-15 min (on T4 GPU)
- Export: ~1 min
- Total: ~15-20 min

---

## Step 4: Put the Model in Your Flutter App (1 min)

After the notebook finishes, you'll have two files downloaded:
- `helmet_detector.tflite` (~6 MB)
- `helmet_labels.txt`

Copy them to:
```
mobile/assets/models/helmet_detector.tflite
mobile/assets/models/helmet_labels.txt    ← (already exists, just confirm)
```

---

## Step 5: Rebuild the APK (3 min)

```bash
cd mobile
flutter clean
flutter pub get
flutter build apk --release --split-per-abi
```

Install the new APK on your phone (same as before - Drive/WhatsApp/etc).

---

## Step 6: Use It!

1. Open the app → Login
2. On the home screen, tap **"Live Helmet Detection"** button (under Ride Analysis)
3. Point camera at a rider's head
4. You'll see:
   - **Green box** + "helmet" label if wearing helmet
   - **Red box** + "NO HELMET DETECTED" + red border if not wearing
5. If no helmet is detected for 30+ seconds → guardian alert is sent automatically

---

## How It Works (Technical)

```
Camera Frame (YUV420)
    ↓
Preprocess (resize to 320x320, normalize 0-1)
    ↓
YOLOv8n TFLite Model (on-device GPU/CPU)
    ↓
Decode YOLO output (boxes + class scores)
    ↓
Non-Maximum Suppression (remove overlaps)
    ↓
Result: [{label: "helmet", confidence: 0.92, box: ...}]
    ↓
If "no_helmet" confidence > 0.6 → Alert Guardian
```

**Performance:**
- Model: YOLOv8-nano (3.2M parameters)
- Input: 320x320 pixels
- Speed: 20-30 FPS on mid-range phones (Snapdragon 600+)
- Accuracy: ~80-90% mAP50 (depends on dataset quality)
- Runs 100% offline, no internet needed

---

## Alternative: Use a Better Dataset (Optional)

The Kaggle dataset is good but mostly construction helmet images. For **best** motorcycle rider accuracy:

### Option A: Roboflow Universe (recommended)

1. Go to https://universe.roboflow.com
2. Search: "motorcycle helmet detection"
3. Pick a dataset with 2000+ images and good reviews
4. Click **Download → YOLOv8 format → Show download code**
5. In the Colab notebook, uncomment the Roboflow section and paste your API snippet

### Option B: Collect Your Own Data

Best accuracy = your own local data:
1. Take 200+ photos of riders WITH helmets
2. Take 200+ photos of riders WITHOUT helmets
3. Annotate with https://roboflow.com (free, browser-based)
4. Export in YOLOv8 format
5. Upload to Colab and train

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Colab says "GPU not available" | Runtime → Change runtime type → T4 GPU (free) |
| "kaggle.json not found" | Upload it when prompted (Step 1) |
| Low accuracy (mAP < 0.5) | Use a better dataset (motorcycle-specific), or train longer (100 epochs) |
| Model too slow on phone | Already using nano (fastest). Reduce `_processEveryNFrames` in camera_screen.dart |
| Camera permission denied | Go to phone Settings → Apps → SafeRide → Permissions → Camera → Allow |
| "Model not found" in app | Check `mobile/assets/models/helmet_detector.tflite` exists and rebuild APK |
| App crashes on camera open | Some old phones don't support YUV420. Try changing `imageFormatGroup` in camera_screen.dart |

---

## File Structure After Setup

```
mobile/
├── assets/
│   └── models/
│       ├── helmet_detector.tflite    ← YOUR TRAINED MODEL (from Colab)
│       └── helmet_labels.txt         ← Class labels
├── lib/
│   ├── features/
│   │   └── camera/
│   │       └── camera_screen.dart    ← Live camera UI with detection overlay
│   └── vision/
│       ├── on_device_analyzer.dart   ← High-level analyzer (frame → result)
│       ├── tflite/
│       │   └── helmet_detector.dart  ← TFLite inference engine (YOLOv8 decode)
│       ├── vision_analyzer.dart      ← Analyzer interface
│       └── vision_pipeline_service.dart
└── pubspec.yaml                      ← Includes camera + tflite_flutter deps

ai_training/
├── helmet_detection_colab.ipynb      ← Training notebook (run in Colab)
└── HELMET_MODEL_PLAN.md              ← Architecture notes
```

---

## Quick Reference Commands

```bash
# Train model (in Google Colab — NOT on your PC)
# Just open the .ipynb file in Colab and click Run All

# After getting helmet_detector.tflite:
cp ~/Downloads/helmet_detector.tflite mobile/assets/models/

# Rebuild app
cd mobile
flutter clean && flutter pub get
flutter build apk --release --split-per-abi

# APK location:
# mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

---

## Cost: Completely FREE

| Resource | Cost |
|----------|------|
| Google Colab (T4 GPU) | Free |
| Kaggle dataset | Free |
| Flutter + TFLite | Free (open source) |
| On-device inference | Free (no API calls, no cloud) |
| **Total** | **$0** |
