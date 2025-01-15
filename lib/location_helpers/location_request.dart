import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

//This function is the handler for getting permission from the user
class PermissionHandler {
  static Future<bool> requestLocationPermission(BuildContext context) async {
    PermissionStatus status = await Permission.location.status;

    if (status.isDenied || status.isRestricted) {
      final newStatus = await Permission.location.request();
      if (newStatus.isGranted) {
        return true;
      } else {
        return false;
      }
    } else if (status.isPermanentlyDenied) {
      _showSettingDialog(context);
      return false;
    } else {
      return true;
    }
  }

  static void _showSettingDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Location Permission Required'),
          content: const Text(
            'Location permission is permanently denied. Please open app settings to enable it.'
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            )
          ],
        );
      },
    );
  }
}