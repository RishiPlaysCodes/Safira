# Activating On-Device Mode Later

The app now supports switching analyzers without code rewrites.

## Current default
Manual mode:
```bash
flutter run
```

## Future model mode
After real `.tflite` files are added and `OnDeviceVisionAnalyzer` is implemented:
```bash
flutter run --dart-define=VISION_MODE=on_device
```

The rest of the app does not change:
- same alerts
- same reports
- same backend APIs
- same dashboard
