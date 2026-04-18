import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class AppPermissions {
  const AppPermissions._();

  static Future<void> requestStartupPermissions() async {
    final isMobile =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    if (!isMobile) {
      return;
    }

    try {
      final status = await Permission.locationWhenInUse.status;
      if (status.isDenied) {
        await Permission.locationWhenInUse.request();
      }
    } catch (_) {}

    try {
      final status = await Permission.photos.status;
      if (status.isDenied) {
        await Permission.photos.request();
      }
    } catch (_) {}
  }
}
