import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:provider/provider.dart';
import '../../services/detection_service.dart';
import './detection_result_screen.dart';

// 1. KEEP ALL EXISTING UTILITY FUNCTIONS (unchanged)
Uint8List _yuv420ToRgb(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];
  final rgbBuffer = Uint8List(width * height * 3);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex = (y ~/ 2) * (uPlane.bytesPerRow) + (x ~/ 2);
      final int yIndex = y * yPlane.bytesPerRow + x;

      final int yVal = yPlane.bytes[yIndex];
      final int uVal = uPlane.bytes[uvIndex];
      final int vVal = vPlane.bytes[uvIndex];

      final int r = (yVal + 1.402 * (vVal - 128)).clamp(0, 255).toInt();
      final int g =
          (yVal - 0.344136 * (uVal - 128) - 0.714136 * (vVal - 128))
              .clamp(0, 255)
              .toInt();
      final int b = (yVal + 1.772 * (uVal - 128)).clamp(0, 255).toInt();

      final int rgbIndex = (y * width + x) * 3;
      rgbBuffer[rgbIndex] = r;
      rgbBuffer[rgbIndex + 1] = g;
      rgbBuffer[rgbIndex + 2] = b;
    }
  }
  return rgbBuffer;
}

img.Image _convertYUV420ToImage(CameraImage image) {
  final rgbBytes = _yuv420ToRgb(image);
  return img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: rgbBytes.buffer,
    numChannels: 3,
  );
}

// 2. KEEP ALL EXISTING WIDGET CLASSES (unchanged)
class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isProcessing = false;
  bool _isFrontCamera = false;
  bool _isFlashOn = false;
  double _zoomLevel = 1.0; // NEW: Zoom control

  // 3. KEEP ALL EXISTING LIFECYCLE METHODS (unchanged)
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null || !_controller!.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _controller!.dispose();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  // 4. KEEP ORIGINAL CAMERA INITIALIZATION (unchanged)
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() => _isInitialized = false);
        return;
      }

      final camera =
          _isFrontCamera
              ? _cameras!.firstWhere(
                (c) => c.lensDirection == CameraLensDirection.front,
                orElse: () => _cameras!.first,
              )
              : _cameras!.firstWhere(
                (c) => c.lensDirection == CameraLensDirection.back,
                orElse: () => _cameras!.first,
              );

      _controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      debugPrint('Camera initialization error: $e');
      if (mounted) {
        setState(() => _isInitialized = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to initialize camera: $e')),
        );
      }
    }
  }

  // 5. KEEP ORIGINAL PICTURE CAPTURE LOGIC (unchanged)
  Future<void> _takePicture() async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    setState(() => _isProcessing = true);

    try {
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      final XFile photo = await _controller!.takePicture();
      final detectionService = Provider.of<DetectionService>(
        context,
        listen: false,
      );

      final imageFile = File(photo.path);
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');

      await detectionService.detectPothole(imageFile);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetectionResultScreen(imagePath: photo.path),
          ),
        ).then((_) => setState(() => _isProcessing = false));
      }
    } catch (e) {
      debugPrint('Error taking picture: $e');
      setState(() => _isProcessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to capture image: $e')));
      }
    }
  }

  // 6. NEW: ZOOM CONTROL HANDLERS (ADDITIONAL FUNCTIONALITY)
  void _handleZoomUpdate(DragUpdateDetails details) {
    setState(() {
      _zoomLevel = (_zoomLevel + details.delta.dy * 0.01).clamp(1.0, 5.0);
      _controller?.setZoomLevel(_zoomLevel);
    });
  }

  void _resetZoom() {
    setState(() {
      _zoomLevel = 1.0;
      _controller?.setZoomLevel(_zoomLevel);
    });
  }

  // 7. ENHANCED BUILD METHOD (ADDING NEW FEATURES WITHOUT MODIFYING EXISTING)
  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onVerticalDragUpdate: _handleZoomUpdate, // NEW: Zoom gesture
      onDoubleTap: _resetZoom, // NEW: Zoom reset
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // EXISTING CAMERA PREVIEW STACK
            CameraPreview(_controller!),
            Positioned.fill(child: CustomPaint(painter: OverlayPainter())),

            // NEW: ZOOM INDICATOR
            Positioned(
              top: 100,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Zoom: ${_zoomLevel.toStringAsFixed(1)}x',
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ),

            // EXISTING CONTROLS (unchanged)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 8,
                  bottom: 8,
                  left: 8,
                  right: 8,
                ),
                color: Colors.black.withOpacity(0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Capture Pothole',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        if (_cameras != null && _cameras!.length > 1)
                          IconButton(
                            icon: const Icon(
                              Icons.flip_camera_ios,
                              color: Colors.white,
                            ),
                            onPressed: _toggleCamera,
                          ),
                        IconButton(
                          icon: Icon(
                            _isFlashOn ? Icons.flash_on : Icons.flash_off,
                            color: Colors.white,
                          ),
                          onPressed: _toggleFlash,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 30,
              child: Column(
                children: [
                  const Text(
                    'Position camera to frame the pothole',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          blurRadius: 4,
                          color: Colors.black54,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: _isProcessing ? null : _takePicture,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
                        if (_isProcessing)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          const Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.blue,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 8. KEEP ALL EXISTING HELPER METHODS (unchanged)
  void _toggleCamera() {
    if (_cameras == null || _cameras!.length <= 1) return;
    setState(() {
      _isFrontCamera = !_isFrontCamera;
      _isInitialized = false;
    });
    _controller?.dispose();
    _initializeCamera();
  }

  void _toggleFlash() {
    setState(() => _isFlashOn = !_isFlashOn);
  }
}

// 9. KEEP EXISTING OVERLAYPAINTER CLASS (unchanged)
class OverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint =
        Paint()
          ..color = Colors.black.withOpacity(0.5)
          ..style = PaintingStyle.fill;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;
    final double frameSize = size.width * 0.7;

    final Path path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                center: Offset(centerX, centerY),
                width: frameSize,
                height: frameSize,
              ),
              const Radius.circular(16),
            ),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    final Paint borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: frameSize,
          height: frameSize,
        ),
        const Radius.circular(16),
      ),
      borderPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
