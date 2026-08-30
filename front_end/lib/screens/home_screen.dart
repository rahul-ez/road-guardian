import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/permission_service.dart';
import '../../services/detection_service.dart';
import './camera_screen.dart';
import './detection_history_screen.dart';
import './livefeed.dart'; // Add this import

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isLoading = true);
    final permissionService = Provider.of<PermissionService>(
      context,
      listen: false,
    );
    await permissionService.checkAndRequestPermissions();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final detectionService = Provider.of<DetectionService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Road Guardian'), elevation: 0),
      body:
          _isLoading || detectionService.isInitializing
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Icon(
                        Icons.report_problem_rounded,
                        size: 100,
                        color: Colors.blue,
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Detect and report potholes to help improve road safety',
                        style: TextStyle(fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _buildModelStatusIndicator(detectionService),
                      const SizedBox(height: 32),
                      _buildActionButton(
                        context,
                        'Start Detection',
                        Icons.camera_alt,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CameraScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        context,
                        'Live Detection',
                        Icons.videocam,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LiveDetectionScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildActionButton(
                        context,
                        'Detection History',
                        Icons.history,
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (context) => const DetectionHistoryScreen(),
                          ),
                        ),
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildModelStatusIndicator(DetectionService service) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color:
            service.isModelLoaded
                ? Colors.green.withOpacity(0.1)
                : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            service.isModelLoaded ? Icons.check_circle : Icons.info,
            color: service.isModelLoaded ? Colors.green : Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            service.isModelLoaded ? 'Model loaded' : 'Using simulation mode',
            style: TextStyle(
              color: service.isModelLoaded ? Colors.green : Colors.orange,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onPressed, {
    bool isPrimary = true,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor:
            isPrimary ? Theme.of(context).colorScheme.primary : null,
        foregroundColor:
            isPrimary ? Theme.of(context).colorScheme.onPrimary : null,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
