import 'package:flutter_radar/flutter_radar.dart';

class LocationHandler {
  static Future<void> checkAndRequestPermissions() async {
    String? status = await Radar.getPermissionsStatus();

    if (status == 'DENIED' || status == 'NOT_DETERMINED') {
      bool background = false;
      String newStatus = await Radar.requestPermissions(background);

      if (newStatus == 'GRANTED_FOREGROUND' || newStatus == 'GRANTED_BACKGROUND') {
        print('location permissions granted');
      } else {
        print('Location permission denied');
      }
    } else {
      print('Permission already granted : $status');
    }
  }
}