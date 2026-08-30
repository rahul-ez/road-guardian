# Road Guardian Mobile App (Full Feature Client)

This Flutter application provides an end-to-end mobile interface for real-time pothole detection, manual road hazard capture, cloud synchronization with Supabase, and mapping via Google Maps.

---

## Features

- **Real-Time Live Feed Detection** (`screens/livefeed.dart`):
  - Automated continuous camera stream capture (500ms intervals).
  - On-screen bounding box overlays using `CustomPainter`.
  - Built-in detection cooldown (7s) to prevent spamming duplicate entries.
  - Auto-reporting toggle for hands-free driving usage.
- **Manual Camera Capture** (`screens/camera_screen.dart`):
  - Single-shot camera viewfinder with framing guide.
  - Smooth zoom gestures and flash control.
  - Instant detection feedback with pothole size grading (Small, Medium, Large).
- **Detection History & Maps** (`screens/detection_history_screen.dart`):
  - Persisted history of recorded potholes.
  - Direct navigation via Google Maps or multi-waypoint route plotting.
- **Cloud Sync (Supabase)**:
  - Automatically uploads pothole snapshots to Supabase Storage.
  - Stores location metadata (`latitude`, `longitude`, `count`) in Supabase PostgreSQL tables.

---

## Architecture Overview

```
front_end/lib/
├── main.dart                      # App initialization & Supabase setup
├── models/
│   └── detection_result.dart      # Detection & DetectionResult data models
├── screens/
│   ├── home_screen.dart           # Main dashboard
│   ├── camera_screen.dart         # Manual capture screen with zoom
│   ├── livefeed.dart              # Continuous real-time detection
│   ├── detection_result_screen.dart # Results with bounding box overlay
│   └── detection_history_screen.dart# Historical logs & Google Maps links
└── services/
    ├── detection_service.dart     # State manager & Supabase sync
    ├── permission_service.dart    # Camera & GPS permission handlers
    └── tflite_service.dart        # Backend HTTP client & parser
```

---

## Getting Started

### 1. Prerequisites
- [Flutter SDK v3.7+](https://docs.flutter.dev/get-started/install)
- Android / iOS development setup

### 2. Configure Backend URL & Supabase
1. Open `lib/services/tflite_service.dart` and update `backendUrl` with your PC's IP address:
   ```dart
   final String backendUrl = "http://<YOUR_PC_IP>:5000/predict";
   ```
2. In `lib/main.dart` and `lib/services/detection_service.dart`, verify or update your Supabase URL & Anon Key if using your own Supabase project.

### 3. Run the App
```bash
cd front_end
flutter pub get
flutter run
```
