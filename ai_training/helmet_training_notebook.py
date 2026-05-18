"""Notebook-style starter for helmet object detection training.

Paste these cells into Google Colab after adding a real labeled dataset.
The output should be exported as `helmet_detector.tflite`.
"""

# 1) Install dependencies in Colab
# !pip install -q tflite-model-maker

# 2) Imports
# from tflite_model_maker import model_spec, object_detector
# from tflite_model_maker.config import ExportFormat

# 3) Dataset input
# If annotations are PASCAL VOC XML:
# train_data = object_detector.DataLoader.from_pascal_voc(
#     image_dir='helmet_dataset/images/train',
#     annotations_dir='helmet_dataset/annotations/train',
#     label_map={1: 'helmet', 2: 'no_helmet'},
# )
# validation_data = object_detector.DataLoader.from_pascal_voc(
#     image_dir='helmet_dataset/images/val',
#     annotations_dir='helmet_dataset/annotations/val',
#     label_map={1: 'helmet', 2: 'no_helmet'},
# )
# test_data = object_detector.DataLoader.from_pascal_voc(
#     image_dir='helmet_dataset/images/test',
#     annotations_dir='helmet_dataset/annotations/test',
#     label_map={1: 'helmet', 2: 'no_helmet'},
# )

# 4) Train a mobile-friendly detector
# spec = model_spec.get('efficientdet_lite0')
# model = object_detector.create(
#     train_data,
#     model_spec=spec,
#     validation_data=validation_data,
#     epochs=30,
#     batch_size=8,
# )

# 5) Evaluate
# model.evaluate(test_data)

# 6) Export
# model.export(
#     export_dir='helmet_export',
#     export_format=[ExportFormat.TFLITE, ExportFormat.LABEL],
# )

# 7) Copy output into Flutter app
# Download `helmet_export/model.tflite`
# Rename to `helmet_detector.tflite`
# Put it in: `mobile/assets/models/helmet_detector.tflite`
