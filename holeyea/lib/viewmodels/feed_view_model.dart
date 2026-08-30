import 'dart:developer';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as imglib;
import 'package:geolocator/geolocator.dart';

class FeedViewModel extends ChangeNotifier {

	FeedViewModel(List<CameraDescription> cameras) {
		// Create Camera Camera
		// by default create back camera controller
		if (cameras.isEmpty) {
			// Web or no camera available - handle gracefully
			print("No cameras available");
			return;
		}
		_desc = cameras.firstWhere( 
			(desc) => desc.lensDirection == CameraLensDirection.back,
			orElse: () => cameras.first // Fallback to first camera if no back camera
		);
    init();
	}

	CameraController? controller;
  CameraDescription? _desc; // Made nullable for web compatibility
  bool doing = false;
  // For Android device: use your PC's local IP (both must be on same WiFi)
  final String backendUrl = "http://10.210.62.48:5000/predict"; 

  List<dynamic> detections = [];
  Size imageSize = Size.zero;
  Position? _currentPosition;
  int inferenceTimeMs = 0;
  
  Position? get currentPosition => _currentPosition;

  Future<void> startCamera() async {
    if (_desc == null) {
      print("No camera description available");
      return;
    }
    controller = CameraController(_desc!, ResolutionPreset.medium); // Reduced resolution for faster transfer
    controller?.initialize().then( (value) {
      notifyListeners();
      controller?.startImageStream((image) => onImage(image));
    });
  }

  void init() async {
    await _startLocationStream();
    await startCamera();
  }

  Future<void> _startLocationStream() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      log("Location services are disabled.");
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        log("Location permissions are denied");
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      log("Location permissions are permanently denied, we cannot request permissions.");
      return;
    } 

    Geolocator.getPositionStream().listen((Position position) {
      _currentPosition = position;
    });
  }

  void onImage(CameraImage cameraImage) async {
    if(doing) {
      // log("Previous process not done yet");
      return;
    }

    doing = true;
    
    try {
      // Convert CameraImage to Image
      imglib.Image image = convertYUV420ToImage(cameraImage);
      
      // Encode to JPG
      List<int> jpegBytes = imglib.encodeJpg(image, quality: 70);
      
      // Send to backend
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files.add(http.MultipartFile.fromBytes(
        'file', 
        jpegBytes, 
        filename: 'frame.jpg'
      ));

      if (_currentPosition != null) {
        request.fields['lat'] = _currentPosition!.latitude.toString();
        request.fields['long'] = _currentPosition!.longitude.toString();
      }

      log("Sending request to $backendUrl");
      final stopwatch = Stopwatch()..start();
      var response = await request.send();
      stopwatch.stop();
      inferenceTimeMs = stopwatch.elapsedMilliseconds;

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        detections = jsonDecode(responseBody);
        imageSize = Size(cameraImage.width.toDouble(), cameraImage.height.toDouble());
        notifyListeners();
        log("${detections.length} potholes found in ${inferenceTimeMs}ms");
      } else {
        log("Backend error: ${response.statusCode}");
      }

    } catch (e) {
      log("Error processing frame: $e");
    } finally {
      doing = false;
    }
  }


  imglib.Image convertYUV420ToImage(CameraImage cameraImage) {
  final imageWidth = cameraImage.width;
  final imageHeight = cameraImage.height;

  final yBuffer = cameraImage.planes.first.bytes;
  final uBuffer = cameraImage.planes[1].bytes;
  final vBuffer = cameraImage.planes[2].bytes;

  final int yRowStride = cameraImage.planes[0].bytesPerRow;
  final int yPixelStride = cameraImage.planes[0].bytesPerPixel!;

  final int uvRowStride = cameraImage.planes[1].bytesPerRow;
  final int uvPixelStride = cameraImage.planes[1].bytesPerPixel!;

  var image = imglib.Image(width: imageWidth, height: imageHeight);

  for (int h = 0; h < imageHeight; h++) {
    int uvh = (h / 2).floor();

    for (int w = 0; w < imageWidth; w++) {
      int uvw = (w / 2).floor();

      final yIndex = (h * yRowStride) + (w * yPixelStride);

      // Y plane should have positive values belonging to [0...255]
      final int y = yBuffer[yIndex];

      // U/V Values are subsampled i.e. each pixel in U/V channel in a
      // YUV_420 image act as chroma value for 4 neighbouring pixels
      final int uvIndex = (uvh * uvRowStride) + (uvw * uvPixelStride);

      final int u = uBuffer[uvIndex];
      final int v = vBuffer[uvIndex];

      // Compute RGB values per formula above.
      int r = (y + v * 1436 / 1024 - 179).round();
      int g = (y - u * 46549 / 131072 + 44 - v * 93604 / 131072 + 91).round();
      int b = (y + u * 1814 / 1024 - 227).round();

      r = r.clamp(0, 255);
      g = g.clamp(0, 255);
      b = b.clamp(0, 255);

      image.data?.setPixelRgba(w, h, r, g, b, 0xff);
    }
  }

  return image;
}
}
