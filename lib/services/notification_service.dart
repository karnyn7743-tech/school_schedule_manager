import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // تسجيل القنوات الصوتية الجديدة في نظام أندرويد
    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidNotificationPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      // قناة جرس البداية (تم تغيير المعرف إلى school_start_bell_v2 لإجبار النظام على ربط الصوت)
      const AndroidNotificationChannel startChannel = AndroidNotificationChannel(
        'school_start_bell_v2',
        'أجراس بداية الحصص',
        description: 'تنبيهات صوتية خاصة ببدء الحصص المدرسية',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('bell_start'),
        playSound: true,
      );

      // قناة جرس النهاية
      const AndroidNotificationChannel endChannel = AndroidNotificationChannel(
        'school_end_bell_v2',
        'أجراس نهاية الحصص',
        description: 'تنبيهات صوتية خاصة بانتهاء الحصص المدرسية',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('bell_end'),
        playSound: true,
      );

      await androidNotificationPlugin.createNotificationChannel(startChannel);
      await androidNotificationPlugin.createNotificationChannel(endChannel);
    }
  }

  // دالة جدولة الحصص بالأصوات المخصصة
  Future<void> scheduleClassPeriodAlarm({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek, // 1: الإثنين ... 7: الأحد
    required int hour,
    required int minute,
    bool isStart = true, // تحديد الجرس (بداية أم نهاية)
  }) async {
    final String soundName = isStart ? 'bell_start' : 'bell_end';
    final String channelId = isStart ? 'school_start_bell_v2' : 'school_end_bell_v2';
    final String channelName = isStart ? 'أجراس بداية الحصص' : 'أجراس نهاية الحصص';

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(soundName),
      playSound: true,
      enableVibration: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        sound: '$soundName.mp3',
      ),
    );

    final scheduledDate = _nextInstanceOfDayTime(dayOfWeek, hour, minute);

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextInstanceOfDayTime(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}
