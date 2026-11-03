import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PermissionHelper {
  // فحص وطلب إذن إرسال الإشعارات على نظام أندرويد 13 فما فوق
  static Future<bool> requestNotificationPermissions(
    FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin,
  ) async {
    if (Platform.isAndroid) {
      final androidImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      final bool? grantedNotification =
          await androidImplementation?.requestNotificationsPermission();

      final bool? grantedExactAlarm =
          await androidImplementation?.requestExactAlarmsPermission();

      return (grantedNotification ?? false) && (grantedExactAlarm ?? true);
    } else if (Platform.isIOS) {
      final iosImplementation = flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      final bool? granted = await iosImplementation?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );

      return granted ?? false;
    }
    return true;
  }
}

