import 'package:flutter/material.dart';
import 'periods/periods_screen.dart';
import 'tasks/tasks_screen.dart';
import 'settings/settings_screen.dart';
import '../services/excel_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../models/class_period_model.dart';
import '../core/constants/app_colors.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // مفاتيح للوصول إلى دوال الإضافة داخل الشاشات
  final GlobalKey<PeriodsScreenState> _periodsKey = GlobalKey<PeriodsScreenState>();
  final GlobalKey<TasksScreenState> _tasksKey = GlobalKey<TasksScreenState>();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NotificationService().requestPermissions();
    });
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // استيراد جدول المهام المجدولة من ملف إكسل وتفعيله فوراً
  Future<void> _handleImportExcel() async {
    try {
      final List<ClassPeriod>? imported = await ExcelService.importSchedule();
      if (imported != null && imported.isNotEmpty) {
        // احتفظ بالجدول السابق قبل استبداله حتى نلغي أجراسه القديمة.
        final oldPeriods = await LocalStorageService.loadPeriods();
        final schoolDays = await LocalStorageService.loadSchoolDays();

        // إلغاء معرفات أجراس الجدول السابق فقط، مع إبقاء تنبيهات المهام.
        for (final oldPeriod in oldPeriods) {
          for (var day = DateTime.monday; day <= DateTime.sunday; day++) {
            await NotificationService().cancelAlarm(
              NotificationService.periodStartId(oldPeriod.id, day),
            );
            await NotificationService().cancelAlarm(
              NotificationService.periodEndId(oldPeriod.id, day),
            );
            // تنظيف معرفات الإصدارات السابقة من التطبيق.
            await NotificationService().cancelAlarm(
              ((oldPeriod.id % 100000) * 10) + day,
            );
            await NotificationService().cancelAlarm(
              ((oldPeriod.id % 100000) * 10) + day + 500000,
            );
            await NotificationService().cancelAlarm(oldPeriod.id + day);
            await NotificationService().cancelAlarm(oldPeriod.id + day + 100000);
          }
        }

        // جدولة التنبيهات للمهام المستوردة
        for (final period in imported) {
          for (final dayConfig in schoolDays) {
            if (!dayConfig.isEnabled) continue;

            // توليد معرفات آمنة وصغيرة تقع بدقة ضمن حدود الـ 32-bit
            final int startId = NotificationService.periodStartId(
              period.id, dayConfig.dayOfWeek,
            );
            final int endId = NotificationService.periodEndId(
              period.id, dayConfig.dayOfWeek,
            );

            await NotificationService().scheduleClassPeriodAlarm(
              id: startId,
              title: '🔔 بداية: ${period.title}',
              body: 'حان الآن وقت بداية ${period.title}',
              dayOfWeek: dayConfig.dayOfWeek,
              hour: period.startHour,
              minute: period.startMinute,
            );

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

        await LocalStorageService.savePeriods(imported);

        // تحديث واجهة المهام المجدولة
        _periodsKey.currentState?.loadScheduleData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم استيراد ${imported.length} فترة وجدولة تنبيهاتها بنجاح!'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الاستيراد: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // تصدير جدول المهام الحالي إلى إكسل
  Future<void> _handleExportExcel() async {
    final periods = await LocalStorageService.loadPeriods();
    if (periods.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('الجدول فارغ! أضف المهام أولاً لتصديرها.')),
        );
      }
      return;
    }
    await ExcelService.exportSchedule(periods);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مدير المهام المجدولة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'استيراد جدول من Excel',
            onPressed: _handleImportExcel,
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'تصدير الجدول إلى Excel',
            onPressed: _handleExportExcel,
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'إعدادات الدوام',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              ).then((_) {
                // تحديث البيانات عند العودة من الإعدادات
                _periodsKey.currentState?.loadScheduleData();
              });
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.notifications_active_outlined),
              text: 'أجراس أعمال متكررة',
            ),
            Tab(
              icon: Icon(Icons.assignment_outlined),
              text: 'جدول الإلتزامات والمهام',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          PeriodsScreen(key: _periodsKey),
          TasksScreen(key: _tasksKey),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_tabController.index == 0) {
            _periodsKey.currentState?.openAddEditDialog();
          } else {
            _tasksKey.currentState?.openAddEditTaskDialog();
          }
        },
        icon: const Icon(Icons.add),
        label: Text(_tabController.index == 0 ? 'إضافة حصة' : 'إضافة مهمة'),
      ),
    );
  }
}
