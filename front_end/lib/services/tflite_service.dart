import 'dart:convert';
import 'dart:typed_data';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/detection_result.dart';

class TFLiteService {
  // Replace with your actual backend IP
  // If running on Android Emulator: http://10.0.2.2:5000/predict
  // If running on Physical Device: http://<YOUR_PC_IP>:5000/predict
  final String backendUrl = "http://10.210.62.48:5000/predict"; 
  
  final bool _isModelLoading = false;
  bool get isModelLoading => _isModelLoading;

  int _lastInferenceTime = 0;
  int get lastInferenceTime => _lastInferenceTime;

  Future<bool> loadModel() async {
    // No local model to load
    return true;
  }

  Future<List<Detection>> detectPotholes(Uint8List imageBytes) async {
    final stopwatch = Stopwatch()..start(); 

    try {
      final image = img.decodeImage(imageBytes);
      if (image == null) {
        print('Failed to decode image');
        return [];
      }

      // Send to backend
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        imageBytes, 
        filename: 'frame.jpg'
      ));

      var response = await request.send();
      _lastInferenceTime = stopwatch.elapsedMilliseconds;
      print('Inference completed in ${_lastInferenceTime}ms');

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var jsonDetections = jsonDecode(responseBody) as List;
        
        return jsonDetections.map((d) {
           var bbox = d['bbox']; // [x1, y1, x2, y2] in pixels
           double x1 = bbox[0].toDouble();
           double y1 = bbox[1].toDouble();
           double x2 = bbox[2].toDouble();
           double y2 = bbox[3].toDouble();
           
           double wString = image.width.toDouble();
           double hString = image.height.toDouble();

           // Normalize to 0-1
           double x = x1 / wString;
           double y = y1 / hString;
           double w = (x2 - x1) / wString;
           double h = (y2 - y1) / hString;

           return Detection(
             x: x,
             y: y,
             width: w,
             height: h,
             confidence: d['confidence'],
             className: d['label']
           );
        }).toList();
      } else {
        print("Backend error: ${response.statusCode}");
        return [];
      }

    } catch (e) {
      print('Detection error: $e');
      return [];
    } finally {
      stopwatch.stop();
    }
  }

  // Keep other methods if they are used by UI, otherwise dummy them or remove if possible.
  // Assuming convertToUiRects is used by UI.
  List<ui.Rect> convertToUiRects(
    List<Detection> detections,
    ui.Size imageSize,
  ) {
    return detections.map((detection) {
      return ui.Rect.fromLTWH(
        detection.x * imageSize.width,
        detection.y * imageSize.height,
        detection.width * imageSize.width,
        detection.height * imageSize.height,
      );
    }).toList();
  }

  void dispose() {
    // No cleanup needed
  }
}
