# On-Device AI Setup

The mobile app now has a clean on-device AI architecture:
- `VisionAnalyzer`
- `ManualVisionAnalyzer`
- `OnDeviceVisionAnalyzer`
- `VisionPipelineService`
- model asset folder at `assets/models/`

## Current free mode
The app uses `ManualVisionAnalyzer` so every requested flow works end-to-end today:
- helmet missing
- red-light event
- heavy traffic

## How to make it truly automatic later without cloud API cost
1. Train or download compatible `.tflite` models for:
   - helmet detection
   - red-light detection
   - vehicle detection / density
2. Put them in `assets/models/`
3. Add a Flutter TFLite runtime package
4. Replace the placeholder methods inside `OnDeviceVisionAnalyzer`
5. Switch `VisionPipelineService` to use `OnDeviceVisionAnalyzer`

## Why this is production-friendly
The app flow, backend API, reports, alerts, and storage do not change later. Only the analyzer implementation changes from manual mode to model mode.
