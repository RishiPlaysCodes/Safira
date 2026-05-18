# Helmet Dataset Intake Checklist

Before training, confirm:
- [ ] dataset license is acceptable for your use
- [ ] images are road-rider relevant where possible
- [ ] both helmet and no-helmet cases exist
- [ ] annotations are bounding boxes, not only image-level labels
- [ ] train / validation / test split exists
- [ ] labels are normalized to exactly `helmet` and `no_helmet`

## Folder structure expected by the training notebook
```text
helmet_dataset/
  images/
    train/
    val/
    test/
  annotations/
    train/
    val/
    test/
```

## Practical warning
Construction hard-hat datasets can help bootstrap the pipeline, but road-rider photos are still needed for good motorcycle helmet performance.
