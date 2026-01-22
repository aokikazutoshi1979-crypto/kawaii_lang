import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceService {
  static final _deviceInfo = DeviceInfoPlugin();

  /// 端末固有のIDを返します。
  /// iOS: identifierForVendor / Android: androidId
  static Future<String> getDeviceId() async {
    if (Platform.isIOS) {
      final info = await _deviceInfo.iosInfo;
      return info.identifierForVendor ?? '';
    } else if (Platform.isAndroid) {
      final info = await _deviceInfo.androidInfo;
      return info.id;     // ← androidId ではなく id を使う
    }
    return '';
  }
}
