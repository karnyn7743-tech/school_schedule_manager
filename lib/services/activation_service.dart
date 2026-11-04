import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ActivationService {
  // مفتاح سري خاص بك فقط (لا تغيره بعد إطلاق التطبيق حتى لا تبطل المفاتيح القديمة)
  static const String _secretSalt = "SCHOOL_SCHEDULE_SECRET_KEY_2026";
  static const String _prefIsActivatedKey = "app_is_activated";
  static const String _prefActivationKey = "app_activation_key";

  // استخراج معرّف الجهاز (Android ID)
  static Future<String> getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // يمثل Android ID
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? "UNKNOWN_DEVICE";
      }
    } catch (_) {}
    return "UNKNOWN_DEVICE";
  }

  // خوارزمية توليد مفتاح التفعيل بناءً على معرف الجهاز والمفتاح السري
  // الصيغة الناتجة: 16 حرفاً مقسمة إلى 4 مجموعات (XXXX-XXXX-XXXX-XXXX)
  static String generateActivationKey(String deviceId) {
    final String raw = "${deviceId.trim()}_$_secretSalt";
    final Digest digest = sha256.convert(utf8.encode(raw));
    final String fullHex = digest.toString().toUpperCase();

    // أخذ أول 16 حرفاً وتقسيمها
    final part1 = fullHex.substring(0, 4);
    final part2 = fullHex.substring(4, 8);
    final part3 = fullHex.substring(8, 12);
    final part4 = fullHex.substring(12, 16);

    return "$part1-$part2-$part3-$part4";
  }

  // فحص هل التطبيق مفعل حالياً في الذاكرة
  static Future<bool> isAppActivated() async {
    final prefs = await SharedPreferences.getInstance();
    final bool isActivated = prefs.getBool(_prefIsActivatedKey) ?? false;
    final String savedKey = prefs.getString(_prefActivationKey) ?? "";

    if (!isActivated || savedKey.isEmpty) return false;

    // إعادة التحقق الأمني: التأكد أن المفتاح المحفوظ يطابق الجهاز الحالي فعلاً
    final currentDeviceId = await getDeviceId();
    final expectedKey = generateActivationKey(currentDeviceId);

    return savedKey == expectedKey;
  }

  // التحقق من المفتاح المدخل من قبل المستخدم وتفعيله
  static Future<bool> activateWithKey(String inputKey) async {
    final String deviceId = await getDeviceId();
    final String expectedKey = generateActivationKey(deviceId);

    // تنظيف المدخلات من المسافات
    final cleanInput = inputKey.trim().toUpperCase();

    if (cleanInput == expectedKey) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefIsActivatedKey, true);
      await prefs.setString(_prefActivationKey, expectedKey);
      return true;
    }
    return false;
  }
}
