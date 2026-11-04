import 'package:flutter/material.dart';
import 'periods/periods_screen.dart';
import 'tasks/tasks_screen.dart';
import 'settings/settings_screen.dart';
import '../services/excel_service.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../models/class_period_model.dart';
import '../models/task_item_model.dart'; // ⬅️ [إضافة جديدة]
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

  // ⬇️ [تعديل]: دالة تظهر نافذة اختيار نوع الاستيراد ⬇️
  Future<void> _showImportSelectionDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'ماذا تريد أن تستورد؟',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
                title: const Text('أجراس الحصص'),
                onTap: () {
                  Navigator.pop(context);
                  _importScheduleData();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.assignment_outlined, color: Colors.orange),
                title: const Text('جدول الأعمال والمهام'),
                onTap: () {
                  Navigator.pop(context);
                  _importTasksData();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // ⬇️ [تعديل]: دالة تظهر نافذة اختيار نوع التصدير ⬇️
  Future<void> _showExportSelectionDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'ماذا تريد أن تصدر؟',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.notifications_active_outlined, color: Colors.blue),
                title: const Text('تصدير أجراس الحصص'),
                onTap: () {
                  Navigator.pop(context);
                  _exportScheduleData();
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.assignment_outlined, color: Colors.orange),
                title: const Text('تصدير جدول الأعمال والمهام'),
                onTap: () {
                  Navigator.pop(context);
                  _exportTasksData();
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  // استيراد جدول الحصص المجدولة من ملف إكسل وتفعيله فوراً (نفس الكود السابق)
  Future<void> _importScheduleData() async {
    try {
      final List<ClassPeriod>? imported = await ExcelService.importSchedule();
      if (imported != null && imported.isNotEmpty) {
        // احتفظ بالجدول السابق قبل استبداله حتى نلغي أجراسه القديمة.
        final oldPeriods = await LocalStorageService.loadPeriods();
        final schoolDays = await LocalStorageService.loadSchoolDays();

        // إلغاء معرفات أجراس الجدول السابق فقط، مع إبقاء تنبيهات الحصص.
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

        // جدولة التنبيهات للحصص المستوردة
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

        // تحديث واجهة أجراس الحصص
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

  // ⬇️ [إضافة جديدة]: استيراد المهام ⬇️
  Future<void> _importTasksData() async {
    try {
      final List<TaskItem>? imported = await ExcelService.importTasks();
      if (imported != null && imported.isNotEmpty) {
        // إلغاء تنبيهات المهام القديمة
        final oldTasks = await LocalStorageService.loadTasks();
        for (final oldTask in oldTasks) {
          await NotificationService().cancelAlarm(oldTask.id);
        }

        // حفظ المهام الجديدة
        await LocalStorageService.saveTasks(imported);

        // جدولة المهام الجديدة
        for (final task in imported) {
          if (!task.isCompleted) {
            await NotificationService().scheduleTaskAlarm(task);
          }
        }

        // تحديث واجهة المهام
        _tasksKey.currentState?.loadTasksData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('تم استيراد ${imported.length} مهمة وجدولة تنبيهاتها بنجاح!'),
              backgroundColor: AppColors.secondary,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء استيراد المهام: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // تصدير جدول الحصص الحالي إلى إكسل (نفس الكود السابق)
  Future<void> _exportScheduleData() async {
    final periods = await LocalStorageService.loadPeriods();
    if (periods.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جدول الحصص فارغ! أضف الحصص أولاً لتصديرها.')),
        );
      }
      return;
    }
    await ExcelService.exportSchedule(periods);
  }

  // ⬇️ [إضافة جديدة]: تصدير المهام ⬇️
  Future<void> _exportTasksData() async {
    final tasks = await LocalStorageService.loadTasks();
    if (tasks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('جدول المهام فارغ! أضف المهام أولاً لتصديرها.')),
        );
      }
      return;
    }
    await ExcelService.exportTasks(tasks);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مدير المهام والحصص المجدولة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'استيراد من Excel',
            onPressed: _showImportSelectionDialog, // ⬅️ [تعديل]: استدعاء النافذة المنبثقة
          ),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined),
            tooltip: 'تصدير إلى Excel',
            onPressed: _showExportSelectionDialog, // ⬅️ [تعديل]: استدعاء النافذة المنبثقة
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
              text: 'أجراس الحصص',
            ),
            Tab(
              icon: Icon(Icons.assignment_outlined),
              text: 'جدول الأعمال والمهام',
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
