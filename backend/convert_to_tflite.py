"""
Convert TensorFlow SavedModel to TFLite format for on-device inference.

This script converts your TensorFlow object detection model to TFLite format
which can run directly on Android devices for real-time detection.
"""

import tensorflow as tf
import os

# Paths
SAVED_MODEL_DIR = "exported-model/saved_model"
OUTPUT_TFLITE = "model.tflite"

def convert_to_tflite():
    """Convert SavedModel to TFLite format."""
    
    print(f"Loading SavedModel from {SAVED_MODEL_DIR}...")
    
    try:
        # Load the SavedModel
        converter = tf.lite.TFLiteConverter.from_saved_model(SAVED_MODEL_DIR)
        
        # Optimization settings for better performance
        converter.optimizations = [tf.lite.Optimize.DEFAULT]
        
        # Optional: Use float16 quantization for smaller model size and faster inference
        # Uncomment the following lines if you want float16 quantization:
        # converter.target_spec.supported_types = [tf.float16]
        
        # Convert the model
        print("Converting to TFLite format...")
        tflite_model = converter.convert()
        
        # Save the TFLite model
        with open(OUTPUT_TFLITE, 'wb') as f:
            f.write(tflite_model)
        
        # Get file size
        file_size_mb = os.path.getsize(OUTPUT_TFLITE) / (1024 * 1024)
        
        print(f"\nConversion successful!")
        print(f"TFLite model saved to: {OUTPUT_TFLITE}")
        print(f"Model size: {file_size_mb:.2f} MB")
        print(f"\nNext steps:")
        print(f"1. Copy {OUTPUT_TFLITE} to your Flutter project:")
        print(f"   assets/model.tflite")
        print(f"2. Update pubspec.yaml to include the asset")
        print(f"3. Run the app on your Android device")
        
    except Exception as e:
        print(f"\nError during conversion: {e}")
        print("\nTroubleshooting:")
        print("1. Make sure your SavedModel is in the correct directory")
        print("2. Verify the model was exported correctly")
        print("3. Check that TensorFlow is installed: pip install tensorflow")

if __name__ == "__main__":
    convert_to_tflite()
