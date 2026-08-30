# Screenshots & Media Showcase

This directory stores visual assets, architecture diagrams, demo captures, and UI previews for the **Road Guardian** project.

## Available Media

| Asset | Description | Path |
|---|---|---|
| **Pothole Detection Sample 1** | Annotated pothole with bounding box, confidence score & GPS metadata | `sample_detection_1.jpg` |
| **Pothole Detection Sample 2** | Close-up road defect detection with telemetry overlay | `sample_detection_2.jpg` |
| **Heatmap Dashboard (Placeholder)** | Heatmap visualization of detected potholes across coordinates | `heatmap_dashboard.png` *(Add your screenshot here)* |
| **Mobile App UI (Placeholder)** | Flutter mobile app live detection preview | `mobile_livefeed.png` *(Add your screenshot here)* |

---

### Adding your Heatmap Screenshot

1. Run the heatmap server:
   ```bash
   cd backend/detections
   python serve_heatmap.py
   ```
2. Open `http://localhost:8000/heatmap.html` in your web browser.
3. Take a screenshot of the heatmap interface with plotted pothole markers and statistics panel.
4. Save the image file to this directory as:
   ```
   docs/screenshots/heatmap_dashboard.png
   ```
5. The main [README.md](../../README.md) will immediately display your screenshot.
