import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceIdUtil {
  static Future<String> getDeviceId() async {
    final info = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final android = await info.androidInfo;
        return android.id;
      } else if (Platform.isIOS) {
        final ios = await info.iosInfo;
        return ios.identifierForVendor ?? 'unknown-ios';
      }
    } catch (_) {}
    return 'unknown';
  }
}
