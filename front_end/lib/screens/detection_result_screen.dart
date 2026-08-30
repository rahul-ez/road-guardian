import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/detection_result.dart';
import '../../services/detection_service.dart';

class DetectionResultScreen extends StatelessWidget {
  final String imagePath;

  const DetectionResultScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    final detectionService = Provider.of<DetectionService>(context);
    final DetectionResult? result = detectionService.latestResult;
    final hasDetections = result?.detections.isNotEmpty ?? false;

    return Scaffold(
      appBar: AppBar(title: const Text('Detection Result')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.file(File(imagePath), fit: BoxFit.contain),
                      if (hasDetections)
                        CustomPaint(
                          size: Size.infinite,
                          painter: DetectionPainter(
                            result!.detections,
                            imageSize: Size(
                              result.imageWidth.toDouble(),
                              result.imageHeight.toDouble(),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: _buildDetectionInfo(
                  context,
                  result,
                  hasDetections,
                  detectionService,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionInfo(
    BuildContext context,
    DetectionResult? result,
    bool hasDetections,
    DetectionService detectionService,
  ) {
    if (result == null) {
      return const Center(child: Text('No detection results available'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detection Results',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Expanded(
          child:
              hasDetections
                  ? ListView.builder(
                    itemCount: result.detections.length,
                    itemBuilder:
                        (context, index) => _DetectionItem(
                          detection: result.detections[index],
                          index: index,
                        ),
                  )
                  : const Center(child: Text('No potholes detected')),
        ),
        _buildActionButtons(context, detectionService, hasDetections),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    DetectionService service,
    bool hasDetections,
  ) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.black87,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            icon: const Icon(Icons.replay),
            label: const Text('Take Another'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: AbsorbPointer(
            absorbing: !hasDetections,
            child: ElevatedButton.icon(
              onPressed:
                  hasDetections
                      ? () {
                        service.reportDetection();
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Report submitted successfully!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                      : null,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor:
                    hasDetections
                        ? Theme.of(context).primaryColor
                        : Colors.grey.withOpacity(0.5),
              ),
              icon: Icon(
                Icons.send,
                color: hasDetections ? Colors.white : Colors.grey.shade700,
              ),
              label: Text(
                'Report',
                style: TextStyle(
                  color: hasDetections ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _DetectionItem extends StatelessWidget {
  final Detection detection;
  final int index;

  const _DetectionItem({required this.detection, required this.index});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Center(
            child: Icon(Icons.warning_amber_rounded, color: Colors.red),
          ),
        ),
        title: Text(
          'Pothole ${index + 1}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Confidence: ${(detection.confidence * 100).toStringAsFixed(1)}%\n'
          'Size: ${_calculateSize(detection)}',
        ),
      ),
    );
  }
}

String _calculateSize(Detection detection) {
  final area = detection.width * detection.height;
  if (area < 0.1) return 'Small';
  if (area < 0.3) return 'Medium';
  return 'Large';
}

class DetectionPainter extends CustomPainter {
  final List<Detection> detections;
  final Size imageSize;

  DetectionPainter(this.detections, {required this.imageSize});

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;

    final labelBackgroundPaint = Paint()..color = Colors.red;

    final scale = _calculateScale(size);
    final offset = _calculateOffset(size, scale);

    for (final detection in detections) {
      final x = detection.x * imageSize.width;
      final y = detection.y * imageSize.height;
      final width = detection.width * imageSize.width;
      final height = detection.height * imageSize.height;

      final left = offset.dx + x * scale;
      final top = offset.dy + y * scale;
      final scaledWidth = width * scale;
      final scaledHeight = height * scale;

      final rect = Rect.fromLTWH(left, top, scaledWidth, scaledHeight);
      canvas.drawRect(rect, boxPaint);

      final textSpan = TextSpan(
        text: 'Pothole ${(detection.confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      double textY = top - textPainter.height - 4;
      if (textY < 0) textY = top + 4;

      final labelRect = Rect.fromLTWH(
        left,
        textY,
        textPainter.width + 8,
        textPainter.height + 4,
      );

      canvas.drawRect(labelRect, labelBackgroundPaint);
      textPainter.paint(canvas, Offset(left + 4, textY + 2));
    }
  }

  double _calculateScale(Size canvasSize) {
    final imageAspect = imageSize.width / imageSize.height;
    final canvasAspect = canvasSize.width / canvasSize.height;

    if (imageAspect > canvasAspect) {
      return canvasSize.width / imageSize.width;
    } else {
      return canvasSize.height / imageSize.height;
    }
  }

  Offset _calculateOffset(Size canvasSize, double scale) {
    final scaledWidth = imageSize.width * scale;
    final scaledHeight = imageSize.height * scale;
    return Offset(
      (canvasSize.width - scaledWidth) / 2,
      (canvasSize.height - scaledHeight) / 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
