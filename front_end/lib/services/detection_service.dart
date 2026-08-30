import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:exif/exif.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/detection_result.dart';
import '../services/tflite_service.dart';

class DetectionService extends ChangeNotifier {
  final TFLiteService _tfliteService = TFLiteService();
  DetectionResult? _latestResult;
  List<DetectionResult> _detectionHistory = [];
  String? _pythonBackendUrl;
  bool _modelLoaded = false;
  bool _isInitializing = false;
  bool _isUploading = false;

  DetectionResult? get latestResult => _latestResult;
  List<DetectionResult> get detectionHistory => _detectionHistory;
  bool get isModelLoaded => _modelLoaded;
  bool get isInitializing => _isInitializing;
  bool get isUploading => _isUploading;

  late SupabaseClient supabase;

  Future<void> initialize() async {
    if (_isInitializing) return;

    _isInitializing = true;
    notifyListeners();

    try {
      supabase = SupabaseClient(
        "https://hzyjidjxuvqwxnqaopqi.supabase.co",
        "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh6eWppZGp4dXZxd3hucWFvcHFpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDU2MTQ2OTksImV4cCI6MjA2MTE5MDY5OX0.IVuXa7vpRwTtK5nlSRGpJlCPtOXNuj4ynkMU7NH0AJo",
      );
      await supabase.from('potholes').select().limit(1);
      _modelLoaded = await _tfliteService.loadModel();
      await loadDetectionHistory();
    } catch (e) {
      debugPrint('Error initializing detection service: $e');
      rethrow;
    } finally {
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<void> detectPothole(File imageFile) async {
    try {
      if (!_modelLoaded) {
        _modelLoaded = await _tfliteService.loadModel();
        if (!_modelLoaded) {
          throw Exception('Failed to load TFLite model');
        }
      }

      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) throw Exception('Failed to decode image');

      List<Detection> detections = [];
      try {
        detections = await _tfliteService.detectPotholes(imageBytes);
      } catch (e) {
        debugPrint('Error in TFLite detection: $e');
      }

      final Position position = await _getCurrentLocation();

      final result = DetectionResult(
        imagePath: imageFile.path,
        imageWidth: originalImage.width,
        imageHeight: originalImage.height,
        timestamp: DateTime.now(),
        detections: detections,
        latitude: position.latitude,
        longitude: position.longitude,
        isReported: false,
      );

      _latestResult = result;
      _detectionHistory.add(result);
      notifyListeners();
      await _saveDetectionHistory();
    } catch (e) {
      debugPrint('Detection error: $e');
      await _createEmptyDetectionResult(imageFile);
      rethrow;
    }
  }

  Future<void> _createEmptyDetectionResult(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return;

      final Position position = await _getCurrentLocation();

      final result = DetectionResult(
        imagePath: imageFile.path,
        imageWidth: originalImage.width,
        imageHeight: originalImage.height,
        timestamp: DateTime.now(),
        detections: [],
        latitude: position.latitude,
        longitude: position.longitude,
        isReported: false,
      );

      _latestResult = result;
      _detectionHistory.add(result);
      notifyListeners();
      await _saveDetectionHistory();
    } catch (e) {
      debugPrint('Error creating empty result: $e');
      rethrow;
    }
  }

  Future<String> _uploadFile(File file) async {
    _isUploading = true;
    notifyListeners();

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}';
      final uploadPath = 'potholes/$fileName';

      await supabase.storage.from('images').upload(uploadPath, file);
      return uploadPath;
    } catch (e) {
      debugPrint('Error uploading file: $e');
      rethrow;
    } finally {
      _isUploading = false;
      notifyListeners();
    }
  }

  Future<void> reportDetection() async {
    if (_latestResult == null || _latestResult!.isReported) return;

    try {
      final imagePath = await _uploadFile(File(_latestResult!.imagePath));

      await supabase.from("potholes").insert({
        "image_path": imagePath,
        "count": _latestResult!.detections.length,
        "latitude": _latestResult!.latitude,
        "longitude": _latestResult!.longitude,
      });

      final index = _detectionHistory.indexWhere(
        (r) => r.imagePath == _latestResult!.imagePath,
      );
      if (index != -1) {
        _detectionHistory[index] = _detectionHistory[index].copyWith(
          isReported: true,
        );
        _latestResult = _detectionHistory[index];
        notifyListeners();
      }

      if (_pythonBackendUrl != null) {
        await http.post(
          Uri.parse('$_pythonBackendUrl/report'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(_latestResult!.toJson()),
        );
      }

      await _saveDetectionHistory();
    } catch (e) {
      debugPrint('Error reporting detection: $e');
      rethrow;
    }
  }

  Future<Position> _getCurrentLocation() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Error getting location: $e');
      rethrow;
    }
  }

  Future<void> saveDetectionResults() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/detection_history.json');
      await file.writeAsString(
        jsonEncode({
          'history': _detectionHistory.map((r) => r.toJson()).toList(),
        }),
      );
      debugPrint('Detection results saved successfully');
    } catch (e) {
      debugPrint('Error saving detection results: $e');
      rethrow;
    }
  }

  Future<void> _saveDetectionHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/detection_history.json');
      await file.writeAsString(
        jsonEncode({
          'history': _detectionHistory.map((r) => r.toJson()).toList(),
        }),
      );
    } catch (e) {
      debugPrint('Error saving detection history: $e');
      rethrow;
    }
  }

  Future<void> loadDetectionHistory() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/detection_history.json');
      if (await file.exists()) {
        final jsonContent = await file.readAsString();
        final data = jsonDecode(jsonContent);
        _detectionHistory =
            (data['history'] as List)
                .map((item) => DetectionResult.fromJson(item))
                .toList();
        if (_detectionHistory.isNotEmpty) {
          _latestResult = _detectionHistory.last;
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading detection history: $e');
      rethrow;
    }
  }

  void setPythonBackendUrl(String url) {
    _pythonBackendUrl = url;
  }

  void setLatestResult(DetectionResult result) {
    _latestResult = result;
    notifyListeners();
  }

  @override
  void dispose() {
    _tfliteService.dispose();
    super.dispose();
  }

  img.Image _applyExifOrientation(
    img.Image image,
    Map<String, IfdTag> exifData,
  ) {
    final orientation = exifData['Image Orientation']?.printable ?? '1';
    switch (orientation) {
      case '2':
        return img.flipHorizontal(image);
      case '3':
        return img.copyRotate(image, angle: 180);
      case '4':
        return img.flipVertical(image);
      case '5':
        return img.copyRotate(img.flipHorizontal(image), angle: -90);
      case '6':
        return img.copyRotate(image, angle: -90);
      case '7':
        return img.copyRotate(img.flipHorizontal(image), angle: 90);
      case '8':
        return img.copyRotate(image, angle: 90);
      default:
        return image;
    }
  }
}
