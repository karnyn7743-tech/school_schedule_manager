import 'package:flutter/material.dart';
import '../../models/task_item_model.dart';
import '../../services/local_storage_service.dart';
import '../../services/notification_service.dart';
import 'widgets/task_tile.dart';
import 'add_edit_task_dialog.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => TasksScreenState();
}

class TasksScreenState extends State<TasksScreen> {
  List<TaskItem> _tasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTasksData();
  }

  Future<void> loadTasksData() async {
    setState(() => _isLoading = true);
    final tasks = await LocalStorageService.loadTasks();
    // ترتيب المهام بحسب الأقرب تاريخاً
    tasks.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
    setState(() {
      _tasks = tasks;
      _isLoading = false;
    });
  }

  Future<void> openAddEditTaskDialog([TaskItem? task]) async {
    final result = await showDialog<TaskItem>(
      context: context,
      builder: (ctx) => AddEditTaskDialog(task: task),
    );

    if (result != null) {
      setState(() {
        if (task == null) {
          _tasks.add(result);
        } else {
          final index = _tasks.indexWhere((t) => t.id == task.id);
          if (index != -1) _tasks[index] = result;
        }
        _tasks.sort((a, b) => a.scheduledDateTime.compareTo(b.scheduledDateTime));
      });

      await LocalStorageService.saveTasks(_tasks);

      // جدولة التنبيه الدقيق للمهمة
      // Replace an old reminder with the updated reminder, if any.
      await NotificationService().cancelAlarm(result.id);
      if (!result.isCompleted) {
        // ⬇️ الربط التلقائي: خدمة الإشعارات ستقرأ عنوان المهمة وتختار 
        // نغمة deng_er إذا كان العنوان يحتوي على "الطوارئ"، أو important_alert للمهام العادية.
        await NotificationService().scheduleTaskAlarm(result); 
      }
    }
  }

  Future<void> _toggleTaskComplete(TaskItem task, bool? completed) async {
    final isDone = completed ?? false;
    setState(() {
      task.isCompleted = isDone;
    });

    await LocalStorageService.saveTasks(_tasks);

    if (isDone) {
      await NotificationService().cancelAlarm(task.id);
    } else {
      // ⬇️ الربط التلقائي يعمل هنا أيضاً عند إعادة تفعيل المهمة
      await NotificationService().scheduleTaskAlarm(task);
    }
  }

  Future<void> _deleteTask(TaskItem task) async {
    await NotificationService().cancelAlarm(task.id);
    setState(() {
      _tasks.removeWhere((t) => t.id == task.id);
    });
    await LocalStorageService.saveTasks(_tasks);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_outlined, size: 70, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'لا توجد مهام مجدولة حالياً',
              style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'اضغط الزر السفلي (+) لإضافة مهمة إلى جدول الأعمال',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // ⬇️ التعديل: استخدام Stack لوضع زر الفحص فوق قائمة المهام ⬇️
    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 80),
          itemCount: _tasks.length,
          itemBuilder: (context, index) {
            final task = _tasks[index];
            return TaskTile(
              task: task,
              onToggleComplete: (val) => _toggleTaskComplete(task, val),
              onEdit: () => openAddEditTaskDialog(task),
              onDelete: () => _deleteTask(task),
            );
          },
        ),
        // ⬇️ زر الفحص المؤقت (يظهر عائماً في أسفل اليمين) ⬇️
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            backgroundColor: Colors.red.shade700,
            icon: const Icon(Icons.bug_report, color: Colors.white),
            label: const Text('فحص الإشعارات', style: TextStyle(color: Colors.white)),
            onPressed: () async {
              final pending = await NotificationService().pendingNotifications();
              debugPrint('========== الإشعارات المجدولة: ${pending.length} ==========');
              for (var p in pending) {
                debugPrint('ID: ${p.id} | Title: ${p.title} | Date: ${p.scheduledDate}');
              }
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('يوجد ${pending.length} تنبيه مجدول (راجع الـ Terminal)')),
                );
              }
            },
          ),
        ),
      ],
    );
  }
}
