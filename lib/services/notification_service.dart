import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tzdata;

import '../core/utils/permission_handler.dart';
import '../models/task_item_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  static const MethodChannel _deviceChannel =
      MethodChannel('school_app/device_info');

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _exactAlarmAllowed = true;
  bool _notificationPermissionGranted = true;
  String? _deviceTimeZone;

  bool get isInitialized => _initialized;
  bool get canUseExactAlarms => _exactAlarmAllowed;
  bool get canShowNotifications => _notificationPermissionGranted;
  String? get deviceTimeZone => _deviceTimeZone;

  /// Stable, distinct IDs for every period/day/start-end combination.
  /// Kept below Android's signed 32-bit notification ID limit.
  static int periodStartId(int periodId, int dayOfWeek) =>
      ((periodId.abs() % 20000000) * 100) + (dayOfWeek * 2);
  static int periodEndId(int periodId, int dayOfWeek) =>
      periodStartId(periodId, dayOfWeek) + 1;

  Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    await _configureLocalTimeZone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(settings);
    await _createNotificationChannels();
    _initialized = true;
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      if (Platform.isAndroid) {
        final info = await _deviceChannel.invokeMapMethod<String, dynamic>(
          'getDeviceInfo',
        );
        final zoneId = info?['timeZoneId'] as String?;
        if (zoneId != null && zoneId.isNotEmpty) {
          tz.setLocalLocation(tz.getLocation(zoneId));
          _deviceTimeZone = zoneId;
          return;
        }
      }
      // A safe fallback for platforms where the native IANA zone is unavailable.
      final offset = DateTime.now().timeZoneOffset;
      final sign = offset.isNegative ? '-' : '+';
      final hours = offset.inHours.abs().toString().padLeft(2, '0');
      final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
      final fixedOffset = 'Etc/GMT${offset.isNegative ? '+' : '-'}${offset.inHours.abs()}';
      try {
        tz.setLocalLocation(tz.getLocation(fixedOffset));
        _deviceTimeZone = '$sign$hours:$minutes';
      } catch (_) {
        tz.setLocalLocation(tz.UTC);
        _deviceTimeZone = 'UTC (fallback)';
      }
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
      _deviceTimeZone = 'UTC (fallback)';
    }
  }

  Future<bool> requestPermissions() async {
    _notificationPermissionGranted =
        await PermissionHelper.requestNotificationPermissions(
      flutterLocalNotificationsPlugin,
    );
    _exactAlarmAllowed = await PermissionHelper.requestExactAlarmPermission(
      flutterLocalNotificationsPlugin,
    );
    return _notificationPermissionGranted;
  }

  Future<void> _createNotificationChannels() async {
    final android = flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return;

    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'school_start_bell_v3',
        'أجراس بداية الحصص',
        description: 'تنبيهات صوتية خاصة ببدء الحصص المدرسية',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('bell_start'),
        playSound: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'school_end_bell_v3',
        'أجراس نهاية الحصص',
        description: 'تنبيهات صوتية خاصة بانتهاء الحصص المدرسية',
        importance: Importance.max,
        sound: RawResourceAndroidNotificationSound('bell_end'),
        playSound: true,
      ),
    );
    
    // ⬇️ [إضافة جديدة]: قناة المهام العادية (نغمة important_alert) ⬇️
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'school_tasks_channel_v3', // معرف جديد لتجنب مشكلة أندرويد في تغيير صوت القنوات القديمة
        'تنبيهات المهام والأعمال',
        description: 'تنبيهات خاصة بالمهام والأنشطة المدرسية',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('important_alert'),
      ),
    );
    // ⬇️ [إضافة جديدة]: قناة مهام الطوارئ (نغمة deng_er) ⬇️
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'school_emergency_channel_v1',
        'تنبيهات الطوارئ',
        description: 'تنبيهات خاصة بالمهام الطارئة',
        importance: Importance.max, // الطوارئ تحتاج أولوية قصوى
        playSound: true,
        sound: RawResourceAndroidNotificationSound('deng_er'),
      ),
    );

    // القنوات القديمة (مُبقاة لضمان عدم حدوث أخطاء في التحديثات السابقة)
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'school_tasks_channel_v2',
        'تنبيهات المهام والأعمال (قديم)',
        description: 'تنبيهات خاصة بالمهام والأنشطة المدرسية',
        importance: Importance.high,
        playSound: true,
      ),
    );
    await android.createNotificationChannel(
      const AndroidNotificationChannel(
        'school_fallback_channel_v2',
        'تنبيهات مدرسية عامة',
        description: 'قناة احتياطية للتنبيهات المدرسية',
        importance: Importance.high,
        playSound: true,
      ),
    );
  }

  AndroidScheduleMode get _scheduleMode => _exactAlarmAllowed
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  Future<void> scheduleClassPeriodAlarm({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    bool isStart = true,
  }) async {
    if (!_initialized) await init();
    if (dayOfWeek < DateTime.monday || dayOfWeek > DateTime.sunday ||
        hour < 0 || hour > 23 || minute < 0 || minute > 59) {
      throw ArgumentError('Invalid weekday or alarm time');
    }

    final soundName = isStart ? 'bell_start' : 'bell_end';
    final channelId = isStart ? 'school_start_bell_v3' : 'school_end_bell_v3';
    final channelName = isStart ? 'أجراس بداية الحصص' : 'أجراس نهاية الحصص';
    final scheduledDate = _nextInstanceOfDayTime(dayOfWeek, hour, minute);

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'تنبيهات الحصص المدرسية',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundName),
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.alarm,
      ),
      iOS: DarwinNotificationDetails(sound: '$soundName.mp3'),
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      details,
      androidScheduleMode: _scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  Future<void> scheduleTaskAlarm(TaskItem task) async {
    if (!_initialized) await init();
    if (task.isCompleted) {
      await cancelAlarm(task.id);
      return;
    }

    final target = tz.TZDateTime.from(task.scheduledDateTime, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (task.recurrence == TaskRecurrence.none && !target.isAfter(now)) {
      await cancelAlarm(task.id);
      return;
    }

    DateTimeComponents? match;
    switch (task.recurrence) {
      case TaskRecurrence.none:
        match = null;
        break;
      case TaskRecurrence.daily:
        match = DateTimeComponents.time;
        break;
      case TaskRecurrence.weekly:
        match = DateTimeComponents.dayOfWeekAndTime;
        break;
      case TaskRecurrence.monthly:
        match = DateTimeComponents.dayOfMonthAndTime;
        break;
      case TaskRecurrence.yearly:
        match = DateTimeComponents.dateAndTime;
        break;
    }

    // ⬇️ [تعديل جوهري]: تحديد نوع المهمة واختيار القناة والصوت المناسب بناءً على حقل الطوارئ ⬇️
    final isEmergency = task.isEmergency; 
    final channelId = isEmergency ? 'school_emergency_channel_v1' : 'school_tasks_channel_v3';
    final channelName = isEmergency ? 'تنبيهات الطوارئ' : 'تنبيهات المهام والأعمال';
    final soundName = isEmergency ? 'deng_er' : 'important_alert';
    final importance = isEmergency ? Importance.max : Importance.high;

    await flutterLocalNotificationsPlugin.zonedSchedule(
      task.id,
      '📋 تذكير بمهمة: ${task.title}',
      task.notes?.trim().isNotEmpty == true
          ? task.notes!.trim()
          : 'حان موعد إنجاز المهمة المدرسية',
      target,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,       // تم التعديل
          channelName,     // تم التعديل
          channelDescription: 'تنبيهات المهام المدرسية',
          importance: importance, // تم التعديل
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(soundName), // تم التعديل
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(sound: '$soundName.mp3'), // تم التعديل
      ),
      androidScheduleMode: _scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: match,
    );
  }

  Future<void> showTestNotification({
    String title = 'اختبار التنبيهات',
    String body = 'إذا ظهر هذا الإشعار فإن عرض الإشعارات يعمل.',
    bool isStart = true,
  }) async {
    if (!_initialized) await init();
    final sound = isStart ? 'bell_start' : 'bell_end';
    final channel = isStart ? 'school_start_bell_v3' : 'school_end_bell_v3';
    await flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch.remainder(2147483647),
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          isStart ? 'أجراس بداية الحصص' : 'أجراس نهاية الحصص',
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(sound),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(sound: '$sound.mp3'),
      ),
    );
  }

  Future<void> scheduleTestNotificationAfterOneMinute({bool isStart = true}) async {
    if (!_initialized) await init();
    final sound = isStart ? 'bell_start' : 'bell_end';
    final channel = isStart ? 'school_start_bell_v3' : 'school_end_bell_v3';
    final channelName = isStart ? 'أجراس بداية الحصص' : 'أجراس نهاية الحصص';
    final scheduled = tz.TZDateTime.now(tz.local).add(const Duration(minutes: 1));
    await flutterLocalNotificationsPlugin.zonedSchedule(
      2147000000 + (isStart ? 1 : 2),
      'اختبار التنبيه المجدول',
      'إذا وصل هذا الإشعار بعد دقيقة، فالجدولة تعمل.',
      scheduled,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel,
          channelName,
          importance: Importance.max,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(sound),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(sound: '$sound.mp3'),
      ),
      androidScheduleMode: _scheduleMode,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<List<PendingNotificationRequest>> pendingNotifications() async =>
      flutterLocalNotificationsPlugin.pendingNotificationRequests();

  Future<void> cancelAlarm(int id) async {
    await flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllAlarms() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  tz.TZDateTime _nextInstanceOfDayTime(int dayOfWeek, int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var candidate = tz.TZDateTime(
      tz.local, now.year, now.month, now.day, hour, minute,
    );
    while (candidate.weekday != dayOfWeek || !candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }
}
