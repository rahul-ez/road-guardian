# Road Guardian Backend Service

The backend module provides a lightweight, high-performance Flask inference server that handles pothole detection requests from mobile devices, automatically annotates detected images with GPS coordinates and bounding boxes, and serves a live interactive geospatial heatmap.

---

## Features

- **Object Detection API**: Accepts images from mobile devices and runs inference using **SSD MobileNet V2** (TensorFlow SavedModel).
- **Automated Visual Annotation**: Draws bounding boxes, confidence percentages, and GPS coordinates directly on detected pothole frames using OpenCV.
- **CSV & Storage Logging**: Automatically saves annotated images to `detections/` and appends entries to `detections.csv`.
- **Interactive Heatmap UI**: Embedded Leaflet.js dashboard with heatmap visualization, dynamic statistics, and image preview popups.
- **TFLite Model Converter**: Included utility to quantize and convert SavedModels into `.tflite` for edge deployment on mobile devices.

---

## Directory Structure

```
backend/
├── main.py                  # Core Flask server & detection pipeline
├── convert_to_tflite.py     # Model export & optimization script
├── requirements.txt         # Python package dependencies
├── exported-model/          # TensorFlow SavedModel assets
│   └── saved_model/
│       ├── saved_model.pb
│       └── variables/
└── detections/              # Detection outputs & visualization server
    ├── detections.csv       # Recorded pothole events log
    ├── heatmap.html         # Leaflet.js interactive map UI
    ├── serve_heatmap.py     # Static web server for the heatmap
    └── pothole_*.jpg        # Annotated detection images
```

---

## Setup & Execution

### 1. Install Dependencies
Ensure you have Python 3.8+ installed:

```bash
cd backend
python -m venv venv

# On Windows:
venv\Scripts\activate
# On Linux/macOS:
source venv/bin/activate

pip install -r requirements.txt
```

### 2. Start the Inference Server
```bash
python main.py
```
The server will start at `http://0.0.0.0:5000`.

### 3. Launch the Heatmap Dashboard
In a separate terminal:
```bash
cd backend/detections
python serve_heatmap.py
```
Open **[http://localhost:8000/heatmap.html](http://localhost:8000/heatmap.html)** in your browser.

---

## API Endpoints

### `GET /`
Health check and client IP inspection.
* **Response**: `{"status": "Backend is running!", "ip": "<client-ip>"}`

### `POST /predict`
* **Content-Type**: `multipart/form-data`
* **Parameters**:
  * `file`: Image file (`.jpg` or `.png`)
  * `lat` *(optional)*: Latitude e.g. `"12.9235"`
  * `long` *(optional)*: Longitude e.g. `"77.5003"`
* **Response**:
  ```json
  [
    {
      "label": "pothole",
      "confidence": 0.91,
      "bbox": [120, 200, 350, 410]
    }
  ]
  ```

---

## Converting Models to TFLite

To convert the SavedModel in `exported-model/saved_model` into an optimized `.tflite` model:
```bash
python convert_to_tflite.py
```
The output file `model.tflite` can be copied directly to your Flutter app's `assets/` directory.
