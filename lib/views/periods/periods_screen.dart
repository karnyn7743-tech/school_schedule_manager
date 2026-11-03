import 'package:flutter/material.dart';
import '../../models/class_period_model.dart';
import '../../models/school_day_config.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import 'widgets/period_card.dart';
import 'add_edit_period_dialog.dart';

class PeriodsScreen extends StatefulWidget {
  const PeriodsScreen({super.key});

  @override
  State<PeriodsScreen> createState() => PeriodsScreenState();
}

class PeriodsScreenState extends State<PeriodsScreen> {
  List<ClassPeriod> _periods = [];
  List<SchoolDayConfig> _schoolDays = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadScheduleData();
  }

  // تحميل البيانات من الذاكرة المحلية
  Future<void> loadScheduleData() async {
    setState(() => _isLoading = true);
    final periods = await LocalStorageService.loadPeriods();
    final days = await LocalStorageService.loadSchoolDays();
    setState(() {
      _periods = periods;
      _schoolDays = days;
      _isLoading = false;
    });
  }

  // جدولة كل الحصص على أيام الدراسة المعتمدة
  Future<void> _rescheduleAllAlarms() async {
    for (final period in _periods) {
      for (final dayConfig in _schoolDays) {
        if (!dayConfig.isEnabled) continue;

        final int startId = period.id + dayConfig.dayOfWeek;
        final int endId = period.id + dayConfig.dayOfWeek + 100000;

        // منبه بداية الحصة
        await NotificationService().scheduleClassPeriodAlarm(
          id: startId,
          title: '🔔 بداية: ${period.title}',
          body: 'حان الآن وقت بداية ${period.title}',
          dayOfWeek: dayConfig.dayOfWeek,
          hour: period.startHour,
          minute: period.startMinute,
        );

        // منبه نهاية الحصة
        await NotificationService().scheduleClassPeriodAlarm(
          id: endId,
          title: '🔕 انتهاء: ${period.title}',
          body: 'انتهت الآن ${period.title}',
          dayOfWeek: dayConfig.dayOfWeek,
          hour: period.endHour,
          minute: period.endMinute,
        );
      }
    }
  }

  // إضافة أو تعديل حصة
  Future<void> openAddEditDialog([ClassPeriod? period]) async {
    final result = await showDialog<ClassPeriod>(
      context: context,
      builder: (ctx) => AddEditPeriodDialog(period: period),
    );

    if (result != null) {
      setState(() {
        if (period == null) {
          _periods.add(result);
        } else {
          final index = _periods.indexWhere((p) => p.id == period.id);
          if (index != -1) _periods[index] = result;
        }
      });
      await LocalStorageService.savePeriods(_periods);
      await _rescheduleAllAlarms();
    }
  }

  // حذف حصة وإلغاء منبهاتها
  Future<void> _deletePeriod(ClassPeriod period) async {
    for (final day in _schoolDays) {
      await NotificationService().cancelAlarm(period.id + day.dayOfWeek);
      await NotificationService().cancelAlarm(period.id + day.dayOfWeek + 100000);
    }
    setState(() {
      _periods.removeWhere((p) => p.id == period.id);
    });
    await LocalStorageService.savePeriods(_periods);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_periods.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'لا توجد حصص مضافة حتى الآن',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط زر الإضافة (+) بالأسفل أو استورد الجدول من ملف إكسل',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: _periods.length,
      itemBuilder: (context, index) {
        final period = _periods[index];
        return PeriodCard(
          period: period,
          onEdit: () => openAddEditDialog(period),
          onDelete: () => _deletePeriod(period),
        );
      },
    );
  }
}

