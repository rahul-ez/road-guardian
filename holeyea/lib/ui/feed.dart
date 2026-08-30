import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:holeyea/viewmodels/feed_view_model.dart';

class Feed extends StatefulWidget {
	const Feed({super.key, required this.vm});

	final FeedViewModel vm;

	@override
	  State<StatefulWidget> createState() {
	    return _FeedState();
	}
}

class _FeedState extends State<Feed> {

  @override
  void dispose() {
    super.dispose();
    widget.vm.controller?.dispose();
  }

	@override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.vm, 
      builder: (c, w) => Scaffold(
      appBar: AppBar(
        title: Text("Feed"),
        actions: [IconButton(onPressed: () {}, icon: Icon(Icons.history))],
      ),

      body: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            cameraWidget(),
            overlayWidget()
          ],
        ),
      ),
    )
    );
  }

  Widget cameraWidget() {
    if(!widget.vm.controller!.value.isInitialized) {
      return const Center(child: Text("Camera not initialized", style: TextStyle(color: Colors.white)));
    } else {
      var camera = widget.vm.controller!.value;
      // fetch screen size
      final size = MediaQuery.of(context).size;
      var scale = size.aspectRatio * camera.aspectRatio;

      // to prevent distortion, swap width and height for scale calculation 
      // if camera is landscape but screen is portrait (which is usually the case on mobile)
      if (scale < 1) scale = 1 / scale;

      return Transform.scale(
        scale: scale,
        child: Center(
          child: CameraPreview(widget.vm.controller!),
        ),
      );
    }
  }

  // Need separate widget for overlay to sit ON TOP of the scaled preview
  Widget overlayWidget() {
     return Stack(
          children: [

             
             if(widget.vm.detections.isNotEmpty && widget.vm.imageSize != Size.zero)
              Positioned.fill(
                child: CustomPaint(
                  painter: PotholePainter(
                    detections: widget.vm.detections,
                    imageSize: widget.vm.imageSize,
                    inferenceTimeMs: widget.vm.inferenceTimeMs,
                    currentPosition: widget.vm.currentPosition,
                  ),
                ),
              )
          ],
      );
  }
}

class PotholePainter extends CustomPainter {
  final List<dynamic> detections;
  final Size imageSize;
  final int inferenceTimeMs;
  final Position? currentPosition;

  PotholePainter({
    required this.detections, 
    required this.imageSize,
    required this.inferenceTimeMs,
    this.currentPosition,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final Paint bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;

    // Scale factors
    double scaleX = size.width / imageSize.width;
    double scaleY = size.height / imageSize.height;

    for (var d in detections) {
      var bbox = d['bbox']; // [x1, y1, x2, y2]
      double confidence = d['confidence'];
      
      double x1 = bbox[0] * scaleX;
      double y1 = bbox[1] * scaleY;
      double x2 = bbox[2] * scaleX;
      double y2 = bbox[3] * scaleY;

      // Draw bounding box
      canvas.drawRect(Rect.fromLTRB(x1, y1, x2, y2), boxPaint);

      // Prepare text
      String confText = '${(confidence * 100).toStringAsFixed(1)}%';
      String timeText = '${inferenceTimeMs}ms';
      String gpsText = currentPosition != null 
          ? 'GPS: ${currentPosition!.latitude.toStringAsFixed(4)}, ${currentPosition!.longitude.toStringAsFixed(4)}'
          : 'GPS: N/A';

      // Text styling
      final textStyle = TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      );

      // Create text painters
      final confPainter = TextPainter(
        text: TextSpan(text: confText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final timePainter = TextPainter(
        text: TextSpan(text: timeText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();

      final gpsPainter = TextPainter(
        text: TextSpan(text: gpsText, style: textStyle.copyWith(fontSize: 12)),
        textDirection: TextDirection.ltr,
      )..layout();

      // Calculate positions
      double textX = x1;
      double textY = y1 - 80; // Start above the box

      // If text would go off top, put it inside the box
      if (textY < 0) {
        textY = y1 + 10;
      }

      // Draw confidence
      final confBgRect = Rect.fromLTWH(
        textX, 
        textY, 
        confPainter.width + 8, 
        confPainter.height + 4
      );
      canvas.drawRect(confBgRect, bgPaint);
      confPainter.paint(canvas, Offset(textX + 4, textY + 2));

      // Draw inference time
      textY += confPainter.height + 6;
      final timeBgRect = Rect.fromLTWH(
        textX, 
        textY, 
        timePainter.width + 8, 
        timePainter.height + 4
      );
      canvas.drawRect(timeBgRect, bgPaint);
      timePainter.paint(canvas, Offset(textX + 4, textY + 2));

      // Draw GPS
      textY += timePainter.height + 6;
      final gpsBgRect = Rect.fromLTWH(
        textX, 
        textY, 
        gpsPainter.width + 8, 
        gpsPainter.height + 4
      );
      canvas.drawRect(gpsBgRect, bgPaint);
      gpsPainter.paint(canvas, Offset(textX + 4, textY + 2));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; 
  }
}
