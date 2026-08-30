# Android & Edge Models

This directory contains pre-trained, quantized edge models exported for on-device inference on Android, iOS, and edge devices.

---

## Model Artifacts

| Model File | Format | Framework | Description |
|---|---|---|---|
| `ColabModel.onnx` | ONNX | PyTorch / YOLOv8 | ONNX format exported from Google Colab training run |
| `KaggleModel.onnx` | ONNX | PyTorch / YOLOv8 | ONNX format exported from Kaggle training run |
| `colabmodel.tflite` | TFLite | TensorFlow Lite | Quantized TFLite model for mobile deployment |
| `KaggleModel.tflite`| TFLite | TensorFlow Lite | TFLite model optimized for mobile inference |
| `labels.txt` | Text | — | Class labels definition (`0 pothole`) |

---

## How to Use in Flutter / Android

1. Copy the desired `.tflite` file into your Flutter project's `assets/` directory (e.g. `front_end/assets/model.tflite`).
2. Copy `labels.txt` into `assets/labels.txt`.
3. Verify that `pubspec.yaml` includes the asset paths under `flutter.assets`:
   ```yaml
   flutter:
     assets:
       - assets/model.tflite
       - assets/labels.txt
   ```
