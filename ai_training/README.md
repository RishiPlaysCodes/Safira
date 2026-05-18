# AI Training Kit

This folder is the free path for turning the current AI-ready app into a real on-device AI app.

## Models needed
1. `helmet_detector.tflite`
2. `red_light_detector.tflite`
3. `vehicle_detector.tflite`

## Recommended approach
Use one custom object-detection pipeline per problem:
- helmet: classes like `helmet`, `no_helmet`
- red light: classes like `red_signal`, `green_signal`, `stop_line`
- vehicles: classes like `car`, `bike`, `bus`, `truck`

## Dataset folders
- `datasets/helmet/`
- `datasets/red_light/`
- `datasets/vehicles/`

Each dataset should eventually contain:
- `images/`
- `annotations/`
- train / validation split

## Final export location
After training, place the exported models here:
- `mobile/assets/models/helmet_detector.tflite`
- `mobile/assets/models/red_light_detector.tflite`
- `mobile/assets/models/vehicle_detector.tflite`

## App integration status
Already ready:
- mobile model folder
- analyzer abstraction
- backend observation API
- alerts, reports, and dashboard integration

Still needed later:
- the actual trained `.tflite` files
- replacing the placeholder methods inside `OnDeviceVisionAnalyzer`
