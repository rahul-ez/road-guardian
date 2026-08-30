import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/detection_service.dart';
import '../models/detection_result.dart';

class LiveDetectionScreen extends StatefulWidget {
  const LiveDetectionScreen({super.key});

  @override
  State<LiveDetectionScreen> createState() => _LiveDetectionScreenState();
}

class _LiveDetectionScreenState extends State<LiveDetectionScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  DateTime? _lastDetectionTime;
  Timer? _detectionTimer;
  List<Detection> _currentDetections = [];
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  Size? _cameraPreviewSize;
  bool _isProcessing = false;
  bool _autoReporting = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _startContinuousDetection();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    _controller = CameraController(cameras.first, ResolutionPreset.medium);
    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) {
        setState(() {
          _cameraPreviewSize = Size(
            _controller.value.previewSize!.width,
            _controller.value.previewSize!.height,
          );
        });
      }
    });
  }

  void _startContinuousDetection() {
    _detectionTimer = Timer.periodic(const Duration(milliseconds: 500), (
      _,
    ) async {
      if (_isProcessing ||
          (_lastDetectionTime != null &&
              DateTime.now().difference(_lastDetectionTime!) <
                  const Duration(seconds: 7))) {
        log("Exiting: Processing or cooldown active");
        return;
      }

      try {
        _isProcessing = true;
        log("Started processing");
        await _controller.setFlashMode(FlashMode.off);
        final image = await _controller.takePicture();
        final detectionService = Provider.of<DetectionService>(
          context,
          listen: false,
        );
        await detectionService.detectPothole(File(image.path));
        log("Processing done");

        final hasDetections =
            detectionService.latestResult?.detections.isNotEmpty ?? false;

        if (hasDetections) {
          setState(() {
            _currentDetections = detectionService.latestResult!.detections;
            _lastDetectionTime = DateTime.now();
          });

          _startCooldownTimer();

          if (_autoReporting) {
            await detectionService.reportDetection();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Pothole detected and reported!'),
                  duration: Duration(seconds: 2),
                ),
              );
            }
          }
        } else {
          final file = File(image.path);
          if (await file.exists()) {
            await file.delete();
          }
        }
      } catch (e) {
        debugPrint('Detection error: $e');
      } finally {
        _isProcessing = false;
      }
    });
  }

  void _startCooldownTimer() {
    _cooldownSeconds = 7;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _detectionTimer?.cancel();
    _cooldownTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Live Pothole Detection')),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                CameraPreview(_controller),
                if (_cameraPreviewSize != null)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: DetectionPainter(
                        detections: _currentDetections,
                        imageSize: _cameraPreviewSize!,
                      ),
                    ),
                  ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _cooldownSeconds > 0
                          ? 'Cooldown: $_cooldownSeconds'
                          : 'Monitoring...',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
                if (_isProcessing)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Processing',
                            style: TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Auto-Report',
                          style: TextStyle(color: Colors.white),
                        ),
                        Switch(
                          value: _autoReporting,
                          onChanged: (value) {
                            setState(() => _autoReporting = value);
                          },
                          activeThumbColor: Colors.green,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;

  DetectionPainter({required this.detections, required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0;

    for (final detection in detections) {
      final left = (detection.x - detection.width / 2) * size.width;
      final top = (detection.y - detection.height / 2) * size.height;
      final width = detection.width * size.width;
      final height = detection.height * size.height;

      canvas.drawRect(Rect.fromLTWH(left, top, width, height), paint);

      final textSpan = TextSpan(
        text: 'Pothole ${(detection.confidence * 100).toStringAsFixed(1)}%',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      double textY = top - textPainter.height - 4;
      if (textY < 0) textY = top + height + 4;

      canvas.drawRect(
        Rect.fromLTWH(
          left,
          textY,
          textPainter.width + 8,
          textPainter.height + 4,
        ),
        paint..style = PaintingStyle.fill,
      );

      textPainter.paint(canvas, Offset(left + 4, textY + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
