import 'dart:io';
import 'dart:ui' as ui;
import 'package:geolocator/geolocator.dart';

class Detection {
  final double x; // Normalized x-coordinate (0-1) of top-left corner
  final double y; // Normalized y-coordinate (0-1) of top-left corner
  final double width; // Normalized width (0-1)
  final double height; // Normalized height (0-1)
  final double confidence; // Confidence score (0-1)
  final String className; // Class name ("pothole")

  const Detection({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.confidence,
    required this.className,
  });

  // Convert to pixel coordinates for given image size
  ui.Rect toRect(double imageWidth, double imageHeight) {
    return ui.Rect.fromLTWH(
      x * imageWidth,
      y * imageHeight,
      width * imageWidth,
      height * imageHeight,
    );
  }

  // Calculate area (normalized 0-1)
  double get area => width * height;

  // Get center point (normalized)
  ui.Offset get center => ui.Offset(x + width / 2, y + height / 2);

  // Serialization
  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
    x: json['x']?.toDouble() ?? 0.0,
    y: json['y']?.toDouble() ?? 0.0,
    width: json['width']?.toDouble() ?? 0.0,
    height: json['height']?.toDouble() ?? 0.0,
    confidence: json['confidence']?.toDouble() ?? 0.0,
    className: json['class_name'] ?? 'pothole',
  );

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'confidence': confidence,
    'class_name': className,
  };
}

class DetectionResult {
  final String imagePath;
  final int imageWidth;
  final int imageHeight;
  final DateTime timestamp;
  final List<Detection> detections;
  final double latitude;
  final double longitude;
  final bool isReported;

  DetectionResult({
    required this.imagePath,
    required this.imageWidth,
    required this.imageHeight,
    required this.timestamp,
    required this.detections,
    required this.latitude,
    required this.longitude,
    required this.isReported,
  });

  // Unique identifier
  String get uniqueId =>
      '${timestamp.millisecondsSinceEpoch}_${latitude}_$longitude';

  String get googleMapsUrl =>
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';

  String get locationAddress {
    // This would be populated when reverse geocoding is implemented
    return 'Lat: ${latitude.toStringAsFixed(6)}, Lng: ${longitude.toStringAsFixed(6)}';
  }

  // Most confident detection
  Detection? get bestDetection =>
      detections.isEmpty
          ? null
          : detections.reduce((a, b) => a.confidence > b.confidence ? a : b);

  // Total detection area (normalized)
  double get totalDetectionArea =>
      detections.fold(0.0, (sum, detection) => sum + detection.area);

  // Has any detections
  bool get hasDetections => detections.isNotEmpty;

  // Create modified copy
  DetectionResult copyWith({
    String? imagePath,
    int? imageWidth,
    int? imageHeight,
    DateTime? timestamp,
    List<Detection>? detections,
    double? latitude,
    double? longitude,
    bool? isReported,
  }) => DetectionResult(
    imagePath: imagePath ?? this.imagePath,
    imageWidth: imageWidth ?? this.imageWidth,
    imageHeight: imageHeight ?? this.imageHeight,
    timestamp: timestamp ?? this.timestamp,
    detections: detections ?? this.detections,
    latitude: latitude ?? this.latitude,
    longitude: longitude ?? this.longitude,
    isReported: isReported ?? this.isReported,
  );

  // Serialization
  factory DetectionResult.fromJson(Map<String, dynamic> json) =>
      DetectionResult(
        imagePath: json['image_path'] ?? '',
        imageWidth: json['image_width'] ?? 0,
        imageHeight: json['image_height'] ?? 0,
        timestamp: DateTime.parse(
          json['timestamp'] ?? DateTime.now().toIso8601String(),
        ),
        detections:
            (json['detections'] as List?)
                ?.map((d) => Detection.fromJson(d))
                .toList() ??
            [],
        latitude: json['latitude']?.toDouble() ?? 0.0,
        longitude: json['longitude']?.toDouble() ?? 0.0,
        isReported: json['is_reported'] ?? false,
      );

  Map<String, dynamic> toJson() => {
    'image_path': imagePath,
    'image_width': imageWidth,
    'image_height': imageHeight,
    'timestamp': timestamp.toIso8601String(),
    'detections': detections.map((d) => d.toJson()).toList(),
    'latitude': latitude,
    'longitude': longitude,
    'is_reported': isReported,
  };

  // Compact format for storage
  Map<String, dynamic> toCompactJson() => {
    'image_path': imagePath,
    'image_width': imageWidth,
    'image_height': imageHeight,
    'timestamp': timestamp.toIso8601String(),
    'detection_count': detections.length,
    'latitude': latitude,
    'longitude': longitude,
    'is_reported': isReported,
    'confidence_score': bestDetection?.confidence ?? 0.0,
    'total_area': totalDetectionArea,
  };

  // Helper to get image file
  File get imageFile => File(imagePath);
}
