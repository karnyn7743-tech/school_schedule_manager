import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/task_item_model.dart';
import '../core/utils/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();
    // ضبط المنطقة الزمنية المحلية
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));

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
    await PermissionHelper.requestNotificationPermissions(flutterLocalNotificationsPlugin);
  }

  NotificationDetails _alarmNotificationDetails({
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
        fullScreenIntent: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
    );
  }

  // جدولة جرس الحصة المتكرر أسبوعياً
  Future<void> scheduleClassPeriodAlarm({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      _nextInstanceOfDayAndTime(dayOfWeek, hour, minute),
      _alarmNotificationDetails(
        channelId: 'school_bell_channel',
        channelName: 'أجراس الحصص المدرسية',
        channelDescription: 'تنبيهات مواعيد بداية ونهاية الحصص وفترات الراحة',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  // جدولة تنبيه مهمة أو تكليف إداري
  Future<void> scheduleTaskAlarm(TaskItem task) async {
    DateTimeComponents? matchComponents;
    switch (task.recurrence) {
      case TaskRecurrence.daily:
        matchComponents = DateTimeComponents.time;
        break;
      case TaskRecurrence.weekly:
        matchComponents = DateTimeComponents.dayOfWeekAndTime;
        break;
      case TaskRecurrence.monthly:
        matchComponents = DateTimeComponents.dayOfMonthAndTime;
        break;
      case TaskRecurrence.yearly:
        matchComponents = DateTimeComponents.dateAndTime;
        break;
      case TaskRecurrence.none:
        matchComponents = null;
        break;
    }

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id,
      '📌 تذكير بمهمة: ${task.title}',
      task.notes ?? 'موعد تنفيذ المهمة المجدولة',
      tz.TZDateTime.from(task.scheduledDateTime, tz.local),
      _alarmNotificationDetails(
        channelId: 'school_tasks_channel',
        channelName: 'جدول الأعمال والمهام',
        channelDescription: 'تنبيهات مواعيد جدول الأعمال والمهام الإدارية',
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: matchComponents,
    );
  }

  // حساب الموعد الأقرب القادم لليوم والساعة المحددة
  tz.TZDateTime _nextInstanceOfDayAndTime(int day, int hour, int minute) {
    tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != day || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllAlarms() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }
}

