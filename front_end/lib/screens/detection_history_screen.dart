import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import '../../services/detection_service.dart';
import '../../models/detection_result.dart';
import 'detection_result_screen.dart';

class DetectionHistoryScreen extends StatelessWidget {
  const DetectionHistoryScreen({super.key});

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final detectionService = Provider.of<DetectionService>(context);
    final validHistory =
        detectionService.detectionHistory
            .where((item) => File(item.imagePath).existsSync())
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection History'),
        actions: [
          if (validHistory.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.map),
              tooltip: 'View all on map',
              onPressed: () => _showAllOnMap(context, validHistory),
            ),
        ],
      ),
      body:
          validHistory.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history, size: 72, color: Colors.grey),
                    SizedBox(height: 16),
                    Text(
                      'No detection history yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Detected potholes will appear here',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: validHistory.length,
                itemBuilder: (context, index) {
                  final item = validHistory[validHistory.length - 1 - index];
                  final hasDetections = item.detections.isNotEmpty;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 16),
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => DetectionResultScreen(
                                  imagePath: item.imagePath,
                                ),
                          ),
                        );
                      },
                      onLongPress: () => _showLocationOptions(context, item),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: Image.file(
                                  File(item.imagePath),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        hasDetections
                                            ? Colors.red
                                            : Colors.green,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    hasDetections
                                        ? '${item.detections.length} Detected'
                                        : 'No Potholes',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Captured on ${_formatDateTime(item.timestamp)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Location: ${_formatCoordinates(item.latitude, item.longitude)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                if (hasDetections) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 12,
                                        backgroundColor: Colors.red.shade100,
                                        child: Text(
                                          '${item.detections.length}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.red.shade700,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '${item.detections.length} ${item.detections.length == 1 ? 'pothole' : 'potholes'} detected',
                                        style: const TextStyle(
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton.icon(
                                      onPressed:
                                          () => _openGoogleMaps(context, item),
                                      icon: const Icon(Icons.map, size: 16),
                                      label: const Text('View on Map'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    if (item.isReported)
                                      Chip(
                                        label: const Text('Reported'),
                                        avatar: const Icon(
                                          Icons.check_circle,
                                          size: 16,
                                        ),
                                        backgroundColor: Colors.green.shade100,
                                        labelStyle: TextStyle(
                                          color: Colors.green.shade700,
                                        ),
                                      )
                                    else
                                      TextButton.icon(
                                        onPressed:
                                            hasDetections
                                                ? () {
                                                  detectionService
                                                      .setLatestResult(item);
                                                  detectionService
                                                      .reportDetection();
                                                  _showSnackBar(
                                                    context,
                                                    'Report submitted successfully!',
                                                  );
                                                }
                                                : null,
                                        icon: const Icon(Icons.send),
                                        label: const Text('Report'),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return 'Today, ${_formatTime(dateTime)}';
    } else if (date == yesterday) {
      return 'Yesterday, ${_formatTime(dateTime)}';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}, ${_formatTime(dateTime)}';
    }
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatCoordinates(double lat, double lng) {
    return '${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}';
  }

  Future<void> _openGoogleMaps(
    BuildContext context,
    DetectionResult item,
  ) async {
    final String url =
        'https://www.google.com/maps/search/?api=1&query=${item.latitude},${item.longitude}';
    final String fallbackUrl =
        'geo:${item.latitude},${item.longitude}?q=${item.latitude},${item.longitude}';

    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(Uri.parse(fallbackUrl))) {
        await launchUrl(
          Uri.parse(fallbackUrl),
          mode: LaunchMode.externalApplication,
        );
      } else {
        _showSnackBar(context, 'No maps application available');
      }
    } catch (e) {
      _showSnackBar(context, 'Error: ${e.toString()}');
    }
  }

  void _showLocationOptions(BuildContext context, DetectionResult item) {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('View on Google Maps'),
                onTap: () {
                  Navigator.pop(context);
                  _openGoogleMaps(context, item);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Copy Coordinates'),
                onTap: () {
                  Navigator.pop(context);
                  Clipboard.setData(
                    ClipboardData(text: '${item.latitude}, ${item.longitude}'),
                  );
                  _showSnackBar(context, 'Coordinates copied to clipboard');
                },
              ),
            ],
          ),
    );
  }

  void _showAllOnMap(BuildContext context, List<DetectionResult> history) {
    final validLocations =
        history
            .where((item) => item.latitude != 0 && item.longitude != 0)
            .toList();

    if (validLocations.isEmpty) {
      _showSnackBar(context, 'No valid locations to display');
      return;
    }

    final centerLat =
        validLocations.map((e) => e.latitude).reduce((a, b) => a + b) /
        validLocations.length;
    final centerLng =
        validLocations.map((e) => e.longitude).reduce((a, b) => a + b) /
        validLocations.length;

    final markers = validLocations
        .map((item) => '${item.latitude},${item.longitude}')
        .join('|');

    final url =
        'https://www.google.com/maps/dir/?api=1&origin=$centerLat,$centerLng&waypoints=$markers&travelmode=driving';

    _openGoogleMapsUrl(context, url);
  }

  Future<void> _openGoogleMapsUrl(BuildContext context, String url) async {
    try {
      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url));
      } else {
        _showSnackBar(context, 'Could not launch Google Maps');
      }
    } catch (e) {
      _showSnackBar(context, 'Error launching maps: $e');
    }
  }
}
