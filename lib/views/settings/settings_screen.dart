import 'package:flutter/material.dart';
import '../../models/school_day_config.dart';
import '../../models/class_period_model.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import '../../core/constants/app_colors.dart';
import 'widgets/day_selector_widget.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  List<SchoolDayConfig> _schoolDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final days = await LocalStorageService.loadSchoolDays();
    setState(() {
      _schoolDays = days;
      _isLoading = false;
    });
  }

  // حفظ أيام الدوام وتحديث مواعيد المنبهات تلقائياً
  Future<void> _updateDayStatus(int index, bool isEnabled) async {
    setState(() {
      _schoolDays[index].isEnabled = isEnabled;
    });
    await LocalStorageService.saveSchoolDays(_schoolDays);

    // إعادة جدولة الحصص بناءً على الأيام المعدلة
    final periods = await LocalStorageService.loadPeriods();
    await _reScheduleAllPeriods(periods);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم تحديث جدول التنبيهات للأيام المحددة')),
      );
    }
  }

  Future<void> _reScheduleAllPeriods(List<ClassPeriod> periods) async {
    // إلغاء كل الأجراس القديمة وإعادة جدولتها وفق الأيام النشطة
    await NotificationService().cancelAllAlarms();

    for (final period in periods) {
      for (final day in _schoolDays) {
        if (!day.isEnabled) continue;

        final int startId = period.id + day.dayOfWeek;
        final int endId = period.id + day.dayOfWeek + 100000;

        await NotificationService().scheduleClassPeriodAlarm(
          id: startId,
          title: '🔔 بداية: ${period.title}',
          body: 'حان الآن وقت بداية ${period.title}',
          dayOfWeek: day.dayOfWeek,
          hour: period.startHour,
          minute: period.startMinute,
        );

        await NotificationService().scheduleClassPeriodAlarm(
          id: endId,
          title: '🔕 انتهاء: ${period.title}',
          body: 'انتهت الآن ${period.title}',
          dayOfWeek: day.dayOfWeek,
          hour: period.endHour,
          minute: period.endMinute,
        );
      }
    }
  }

  // إعادة ضبط المنبهات يدوياً
  Future<void> _resetAllAlarms() async {
    final periods = await LocalStorageService.loadPeriods();
    await _reScheduleAllPeriods(periods);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إعادة مزامنة وتنشيط كافة التنبيهات بنجاح')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات الدوام المدرسي'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 10),
        children: [
          DaySelectorWidget(
            days: _schoolDays,
            onDayToggled: _updateDayStatus,
          ),
          const SizedBox(height: 10),
          Card(
            margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.cardBorder),
            ),
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync, color: AppColors.primary),
                  title: const Text(
                    'إعادة مزامنة المنبهات',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('إعادة تنشيط وجدولة جميع أجراس الحصص في النظام'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: _resetAllAlarms,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.notifications_off_outlined, color: Colors.redAccent),
                  title: const Text(
                    'إيقاف جميع التنبيهات',
                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('إلغاء كافة التنبيهات الحالية للحصص والمهام'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تأكيد الإيقاف', textAlign: TextAlign.right),
                        content: const Text('هل ترغب في تعطيل كافة التنبيهات المجدولة حالياً؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () async {
                              await NotificationService().cancelAllAlarms();
                              Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('تم إلغاء كافة التنبيهات بنجاح')),
                                );
                              }
                            },
                            child: const Text('إيقاف الكل'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

