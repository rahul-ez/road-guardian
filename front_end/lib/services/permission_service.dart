// permission_service.dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';

class PermissionService {
  // Check and request all required permissions
  Future<bool> checkAndRequestPermissions() async {
    // Check camera permission
    final cameraStatus = await _checkAndRequestPermission(Permission.camera);

    // Check location permission
    final locationStatus = await _checkLocationPermission();

    return cameraStatus && locationStatus;
  }

  // Check and request a specific permission
  Future<bool> _checkAndRequestPermission(Permission permission) async {
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      final result = await permission.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied) {
      return false;
    }

    return false;
  }

  // Check and request location permission using Geolocator
  Future<bool> _checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Show dialog to explain why permissions are needed
  static Future<void> showPermissionRationaleDialog(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onOpenSettings,
  }) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  onOpenSettings();
                },
                child: const Text('OPEN SETTINGS'),
              ),
            ],
          ),
    );
  }

  // Open app settings
  Future<void> openAppSettings() async {
    await openAppSettings();
  }
}
