# Model Assets

Place your trained TFLite model here:

- `helmet_detector.tflite` — YOLOv8n helmet detection model (~6 MB)
- `helmet_labels.txt` — Class labels (already present)

## How to get the model:

1. Open `ai_training/helmet_detection_colab.ipynb` in Google Colab
2. Run all cells (takes ~15 min with free T4 GPU)
3. Download the generated `helmet_detector.tflite`
4. Place it in this folder

See `HELMET_TRAINING_GUIDE.md` in the project root for full instructions.
