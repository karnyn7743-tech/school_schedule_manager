import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Handles Android notification permissions without requesting permissions
/// that do not exist on older Android releases.
class PermissionHelper {
  static const MethodChannel _deviceChannel =
      MethodChannel('school_app/device_info');

  static Future<int> androidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    try {
      final info = await _deviceChannel.invokeMapMethod<String, dynamic>(
        'getDeviceInfo',
      );
      return (info?['sdkInt'] as num?)?.toInt() ?? 0;
    } catch (_) {
      return 0;
    }
  }

  static Future<bool> requestNotificationPermissions(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (Platform.isAndroid) {
      final android = plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return false;

      final sdk = await androidSdkInt();

      // POST_NOTIFICATIONS exists only from Android 13 (API 33).
      if (sdk >= 33) {
        final granted = await android.requestNotificationsPermission();
        if (granted != true) return false;
      }

      return true;
    }

    if (Platform.isIOS) {
      final ios = plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      final granted = await ios?.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }
    return true;
  }

  static Future<bool> requestExactAlarmPermission(
    FlutterLocalNotificationsPlugin plugin,
  ) async {
    if (!Platform.isAndroid) return true;
    final sdk = await androidSdkInt();
    if (sdk < 31) return true;
    final android = plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    final granted = await android?.requestExactAlarmsPermission();
    // A null result means the platform/plugin did not expose this request;
    // do not block notifications, but use inexact scheduling as a safe fallback.
    return granted ?? false;
  }
}
