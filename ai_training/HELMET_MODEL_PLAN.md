# Helmet Model Build Plan

## Recommended first model
Helmet detection should be the first real on-device AI model because it is the simplest useful problem and directly supports parent alerts.

## Dataset choice strategy
Prefer a road-safety dataset with:
- helmet / no-helmet labels
- object-detection annotations
- clear license
- rider images, not only construction hard-hat images

If a rider-specific dataset is not available immediately, start with a public helmet dataset for the pipeline and later fine-tune using rider images.

## Target classes
- `helmet`
- `no_helmet`

## Minimum useful dataset size
- 500+ helmet examples
- 500+ no-helmet examples

## Export target
- `mobile/assets/models/helmet_detector.tflite`

## Integration target
Once trained, wire the model into:
- `mobile/lib/vision/vision_analyzer.dart`
- switch using `--dart-define=VISION_MODE=on_device`
