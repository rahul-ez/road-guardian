# Road Guardian Model Training & Export Pipeline

This directory contains the machine learning training workflows and Google Colab / Kaggle notebooks used to train custom pothole object detection models.

---

## Training Pipeline Overview

* **Architecture**: **YOLOv8 Nano (`yolov8n.pt`)** by Ultralytics.
* **Target Classes**: `pothole` (Single-class object detection).
* **Notebook**: [HoleYeahFinal.ipynb](HoleYeahFinal.ipynb).

---

## Dataset Structure

The model expects a YOLO-formatted dataset configuration (`data.yaml`):

```
datasets/
├── data.yaml              # Dataset configuration (paths, class names)
├── images/
│   ├── train/             # Training images
│   ├── val/               # Validation images
│   └── test/              # Test evaluation images
└── labels/
    ├── train/             # Training annotations in YOLO format
    ├── val/               # Validation annotations
    └── test/              # Test annotations
```

---

## Training Hyperparameters

The training was executed on GPU with the following parameters:

```bash
yolo task=detect mode=train \
  model=yolov8n.pt \
  data=/content/datasets/data.yaml \
  epochs=100 \
  batch=32 \
  imgsz=640 \
  device=0 \
  amp=True
```

- **`epochs=100`**: 100 training epochs with early stopping checkpoints.
- **`batch=32`**: Batch size per gradient update.
- **`imgsz=640`**: 640x640 input resolution.
- **`amp=True`**: Automatic Mixed Precision for accelerated GPU training.

---

## Model Export

Trained weights (`best.pt`) are exported into edge-ready inference formats:

```python
from ultralytics import YOLO

# Load the trained PyTorch weights
model = YOLO('best.pt')

# Export to TFLite (for Android / Flutter edge inference)
model.export(format='tflite')

# Export to ONNX (for cross-platform runtime)
model.export(format='onnx')
```

Exported models can be found in the `Android Models/` directory.
