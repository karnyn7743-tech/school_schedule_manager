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

    await _createNotificationChannels();
  }

  Future<void> _createNotificationChannels() async {
    final androidNotificationPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidNotificationPlugin != null) {
      // قناة جرس بداية الحصص
      const AndroidNotificationChannel startChannel = AndroidNotificationChannel(
        'school_start_bell_v2',
        'أجراس بداية الحصص',
        description: 'تنبيهات صوتية خاصة ببدء الحصص المدرسية',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('bell_start'),
        playSound: true,
      );

      // قناة جرس نهاية الحصص
      const AndroidNotificationChannel endChannel = AndroidNotificationChannel(
        'school_end_bell_v2',
        'أجراس نهاية الحصص',
        description: 'تنبيهات صوتية خاصة بانتهاء الحصص المدرسية',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('bell_end'),
        playSound: true,
      );

      // قناة المهام والأعمال المدرسية
      const AndroidNotificationChannel tasksChannel = AndroidNotificationChannel(
        'school_tasks_channel',
        'تنبيهات المهام والأعمال',
        description: 'تنبيهات خاصة بالمهام والأنشطة المدرسية',
        importance: Importance.high,
        playSound: true,
      );

      await androidNotificationPlugin.createNotificationChannel(startChannel);
      await androidNotificationPlugin.createNotificationChannel(endChannel);
      await androidNotificationPlugin.createNotificationChannel(tasksChannel);
    }
  }

  // جدولة جرس الحصة الأسبوعي
  Future<void> scheduleClassPeriodAlarm({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    bool isStart = true,
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

  // جدولة تنبيه لمهمة محددة بمرونة تامة
  Future<void> scheduleTaskAlarm(dynamic task) async {
    try {
      DateTime? targetTime;
      try { targetTime = task.dueDate; } catch (_) {}
      try { targetTime ??= task.dateTime; } catch (_) {}
      try { targetTime ??= task.date; } catch (_) {}
      try { targetTime ??= task.reminderTime; } catch (_) {}

      if (targetTime == null) return;

      final tz.TZDateTime scheduledDate = tz.TZDateTime.from(targetTime, tz.local);
      if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

      String taskTitle = 'مهمة مدرسية';
      try { taskTitle = task.title.toString(); } catch (_) {}

      String bodyText = 'حان موعد إنجاز المهمة المدرسية';
      try {
        if (task.notes != null && task.notes.toString().isNotEmpty) {
          bodyText = task.notes.toString();
        }
      } catch (_) {}
      try {
        if (task.description != null && task.description.toString().isNotEmpty) {
          bodyText = task.description.toString();
        }
      } catch (_) {}

      int taskId = 0;
      try { taskId = task.id is int ? task.id : int.parse(task.id.toString()); } catch (_) {}

      const androidDetails = AndroidNotificationDetails(
        'school_tasks_channel',
        'تنبيهات المهام والأعمال',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );

      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );

      await flutterLocalNotificationsPlugin.zonedSchedule(
        taskId,
        '📋 تذكير بمهمة: $taskTitle',
        bodyText,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      // تفادي إيقاف التطبيق إذا كانت المهمة بدون وقت محدد
    }
  }

  // إلغاء تنبيه فردي برقم المعرّف
  Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  // إلغاء كافة التنبيهات المجدولة
  Future<void> cancelAllAlarms() async {
    await flutterLocalNotificationsPlugin.cancelAll();
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
