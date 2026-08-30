import os
import tensorflow as tf
import numpy as np
import cv2
from flask import Flask, request, jsonify
from flask_cors import CORS

import csv
import time
from datetime import datetime

app = Flask(__name__)
CORS(app)  # Enable CORS for all routes

@app.route('/', methods=['GET'])
def health_check():
    return jsonify({"status": "Backend is running!", "ip": request.remote_addr}), 200

# Config
MODEL_DIR = os.path.join(os.path.dirname(__file__), "exported-model", "saved_model")
THRESHOLD = 0.5
DETECTIONS_DIR = os.path.join(os.path.dirname(__file__), "detections")
CSV_FILE = os.path.join(DETECTIONS_DIR, "detections.csv")

# Initialize Logging
if not os.path.exists(DETECTIONS_DIR):
    os.makedirs(DETECTIONS_DIR)

if not os.path.exists(CSV_FILE):
    with open(CSV_FILE, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(["timestamp", "filename", "lat", "long", "confidence"])

# Initialize Model
try:
    print(f"Loading model from {MODEL_DIR}...")
    detect_fn = tf.saved_model.load(MODEL_DIR)
    print("Model loaded successfully.")
except Exception as e:
    print(f"Error loading model: {e}")
    detect_fn = None

@app.route('/predict', methods=['POST'])
def predict():
    if detect_fn is None:
        return jsonify({"error": "Model not loaded"}), 500

    if 'file' not in request.files:
        return jsonify({"error": "No file part"}), 400
    
    file = request.files['file']
    if file.filename == '':
        return jsonify({"error": "No selected file"}), 400

    try:
        # 1. Preprocess
        # Read image from file storage
        file_bytes = np.frombuffer(file.read(), np.uint8)
        image = cv2.imdecode(file_bytes, cv2.IMREAD_COLOR)
        
        if image is None:
             return jsonify({"error": "Could not decode image"}), 400

        image_rgb = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        input_tensor = tf.convert_to_tensor(image_rgb)
        input_tensor = input_tensor[tf.newaxis, ...]

        # 2. Predict
        detections = detect_fn(input_tensor)

        # 3. Parse Results
        boxes = detections['detection_boxes'][0].numpy() # [y1, x1, y2, x2] normalized
        scores = detections['detection_scores'][0].numpy()

        results = []
        h, w, _ = image.shape

        for i in range(len(scores)):
            if scores[i] > THRESHOLD:
                y1, x1, y2, x2 = boxes[i]
                # Convert to pixel coordinates
                bbox = [int(x1 * w), int(y1 * h), int(x2 * w), int(y2 * h)]
                results.append({
                    "label": "pothole",
                    "confidence": float(scores[i]),
                    "bbox": bbox
                })

        # --- Logging ---
        if results:
            try:
                # Get GPS coordinates
                lat = request.form.get('lat', '0.0')
                long = request.form.get('long', '0.0')
                
                # Create annotated image with bounding boxes and metadata
                annotated_image = image.copy()
                
                for r in results:
                    bbox = r['bbox']  # [x1, y1, x2, y2]
                    confidence = r['confidence']
                    
                    # Draw bounding box
                    cv2.rectangle(annotated_image, 
                                (bbox[0], bbox[1]), 
                                (bbox[2], bbox[3]), 
                                (0, 0, 255),  # Red color in BGR
                                3)
                    
                    # Prepare text
                    conf_text = f"Conf: {confidence*100:.1f}%"
                    gps_text = f"GPS: {lat}, {long}"
                    
                    # Calculate text size for background
                    font = cv2.FONT_HERSHEY_SIMPLEX
                    font_scale = 0.6
                    thickness = 2
                    
                    (conf_w, conf_h), _ = cv2.getTextSize(conf_text, font, font_scale, thickness)
                    (gps_w, gps_h), _ = cv2.getTextSize(gps_text, font, font_scale, thickness)
                    
                    # Position text above bounding box
                    text_x = bbox[0]
                    text_y = bbox[1] - 10
                    
                    # If text would go off top of image, put it inside the box
                    if text_y - conf_h - gps_h - 10 < 0:
                        text_y = bbox[1] + 25
                    
                    # Draw background rectangles for text
                    cv2.rectangle(annotated_image,
                                (text_x, text_y - conf_h - 5),
                                (text_x + conf_w + 5, text_y + 5),
                                (0, 0, 0),  # Black background
                                -1)
                    
                    cv2.rectangle(annotated_image,
                                (text_x, text_y + 10),
                                (text_x + gps_w + 5, text_y + gps_h + 15),
                                (0, 0, 0),  # Black background
                                -1)
                    
                    # Draw text
                    cv2.putText(annotated_image, conf_text,
                              (text_x + 2, text_y),
                              font, font_scale, (255, 255, 255), thickness)
                    
                    cv2.putText(annotated_image, gps_text,
                              (text_x + 2, text_y + gps_h + 10),
                              font, font_scale, (255, 255, 255), thickness)
                
                # Save annotated image
                timestamp = datetime.now().strftime("%Y%m%d_%H%M%S_%f")
                filename = f"pothole_{timestamp}.jpg"
                filepath = os.path.join(DETECTIONS_DIR, filename)
                cv2.imwrite(filepath, annotated_image)

                # Log to CSV
                max_conf = max([r['confidence'] for r in results])
                
                with open(CSV_FILE, 'a', newline='') as f:
                    writer = csv.writer(f)
                    writer.writerow([timestamp, filename, lat, long, max_conf])
                
                print(f"Logged pothole: {filename} at {lat}, {long}")
            except Exception as e:
                print(f"Logging error: {e}")
        # ----------------

        return jsonify(results)

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Disable debug mode to prevent the model from loading twice due to the reloader
    app.run(host='0.0.0.0', port=5000, debug=False)
