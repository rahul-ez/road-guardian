# Road Guardian Mobile App

A streamlined, modern dark-themed Flutter client for Road Guardian, designed for high-performance live camera streaming and manual image inspection.

---

## Features

- **Dark Minimalist Theme**: Optimized for low-light driving and clean contrast.
- **Declarative Navigation**: Built on top of `go_router` for route handling (`/`, `/manual`, `/automatic`).
- **Live Frame Streaming** (`viewmodels/feed_view_model.dart`):
  - Converts raw camera YUV420 buffers to JPEG on the fly.
  - Streams frames via HTTP multipart POST to the backend with attached live GPS coordinates.
  - Displays inference latency in milliseconds (`ms`).
- **Manual Gallery & Camera Detection** (`ui/manual.dart`):
  - Allows selecting images from the device gallery or capturing a single frame for inspection.

---

## Project Structure

```
holeyea/lib/
├── main.dart                      # App entry point & dark theme configuration
├── router.dart                    # GoRouter route definitions
├── holeyea.dart                   # Shared library exports
├── services/
│   └── camera_service.dart        # Camera lifecycle helper
├── ui/
│   ├── home.dart                  # Dashboard with navigation cards
│   ├── manual.dart                # Single image capture & gallery picker
│   └── feed.dart                  # Live camera feed screen
└── viewmodels/
    └── feed_view_model.dart       # Camera stream converter & network dispatcher
```

---

## Running the App

```bash
cd holeyea

# 1. Install packages
flutter pub get

# 2. Configure Backend URL
# Open `lib/viewmodels/feed_view_model.dart` and set `backendUrl`:
# final String backendUrl = "http://<YOUR_PC_IP>:5000/predict";

# 3. Launch App
flutter run
```
