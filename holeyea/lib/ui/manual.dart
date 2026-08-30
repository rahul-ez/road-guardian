import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ManualDetection extends StatefulWidget {
  const ManualDetection({super.key});

  @override
  State<ManualDetection> createState() => _ManualDetectionState();
}

class _ManualDetectionState extends State<ManualDetection> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _imageBytes;
  bool _isLoading = false;
  List<dynamic>? _detections;
  String? _error;

  CameraController? _cameraController;
  bool _isCameraReady = false;

  final String backendUrl = "http://10.210.62.48:5000/predict";

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        throw Exception("No cameras available");
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _cameraController!.initialize();
      if (mounted) {
        setState(() {
          _isCameraReady = true;
          _isLoading = false;
          _imageBytes = null;
          _detections = null;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Error initializing camera: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _captureImage() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;

    try {
      setState(() => _isLoading = true);
      final XFile image = await _cameraController!.takePicture();
      final bytes = await image.readAsBytes();

      if (mounted) {
        setState(() {
          _imageBytes = bytes;
          _isCameraReady = false;
          _detections = null;
          _error = null;
        });
        await _cameraController?.dispose();
        _cameraController = null;
      }

      await _detectPotholes(bytes);
    } catch (e) {
      setState(() {
        _error = "Error capturing image: $e";
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    if (source == ImageSource.camera) {
      await _initializeCamera();
      return;
    }

    try {
      final XFile? image = await _picker.pickImage(source: source);
      if (image == null) return;

      final bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
        _isCameraReady = false;
        _detections = null;
        _error = null;
      });

      await _detectPotholes(bytes);
    } catch (e) {
      setState(() {
        _error = "Error picking image: $e";
      });
    }
  }

  Future<void> _detectPotholes(Uint8List imageBytes) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse(backendUrl));
      request.files.add(http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: 'image.jpg',
      ));

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var detections = jsonDecode(responseBody) as List;

        setState(() {
          _detections = detections;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = "Backend error: ${response.statusCode}";
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = "Connection error: $e\n\nMake sure backend is running at $backendUrl";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manual Detection"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 300,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                ),
                child: _isCameraReady && _cameraController != null
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          CameraPreview(_cameraController!),
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                FloatingActionButton(
                                  onPressed: _isLoading ? null : _captureImage,
                                  backgroundColor: Colors.white,
                                  child: const Icon(Icons.camera_alt, color: Colors.black),
                                ),
                                const SizedBox(width: 16),
                                FloatingActionButton(
                                  onPressed: () {
                                    setState(() {
                                      _isCameraReady = false;
                                      _cameraController?.dispose();
                                      _cameraController = null;
                                    });
                                  },
                                  backgroundColor: Colors.redAccent,
                                  mini: true,
                                  child: const Icon(Icons.close, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : _imageBytes == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_rounded, size: 64, color: Colors.grey[700]),
                              const SizedBox(height: 16),
                              Text(
                                "No Image Selected",
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          )
                        : Image.memory(
                            _imageBytes!,
                            fit: BoxFit.cover,
                          ),
              ),
            ),

            const SizedBox(height: 24),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text(
                        "Gallery",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text(
                        "Camera",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            if (_error != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.red.withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: Colors.red),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              ),

            if (_detections != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Results",
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_detections!.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: Colors.green),
                          SizedBox(width: 12),
                          Text("No potholes detected! Safe road.", style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    )
                  else
                    ..._detections!.map((d) => Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.deepOrange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.warning_amber_rounded, color: Colors.deepOrangeAccent),
                          ),
                          title: const Text("Pothole Detected", style: TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("Confidence: ${(d['confidence'] * 100).toStringAsFixed(1)}%"),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                        ),
                      ),
                    )),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
