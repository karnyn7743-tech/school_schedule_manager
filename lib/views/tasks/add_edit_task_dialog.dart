import 'package:flutter/material.dart';
import '../../models/task_item_model.dart';
import '../../core/utils/date_time_utils.dart';

class AddEditTaskDialog extends StatefulWidget {
  final TaskItem? task;

  const AddEditTaskDialog({super.key, this.task});

  @override
  State<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends State<AddEditTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late TaskRecurrence _recurrence;
  late bool _isEmergency; // ⬅️ متغير جديد لحالة الطوارئ

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task?.title ?? '');
    _notesController = TextEditingController(text: widget.task?.notes ?? '');

    final initialDateTime = widget.task?.scheduledDateTime ?? DateTime.now().add(const Duration(hours: 1));
    _selectedDate = initialDateTime;
    _selectedTime = TimeOfDay(hour: initialDateTime.hour, minute: initialDateTime.minute);
    _recurrence = widget.task?.recurrence ?? TaskRecurrence.none;
    _isEmergency = widget.task?.isEmergency ?? false; // ⬅️ تهيئة حالة الطوارئ
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'تعديل المهمة الإدارية' : 'إضافة مهمة جديدة لجدول الأعمال',
        textAlign: TextAlign.right,
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                labelText: 'عنوان المهمة (مثال: اجتماع الكنترول)',
                prefixIcon: Icon(Icons.assignment_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              textAlign: TextAlign.right,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'ملاحظات وتفاصيل إضافية',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
            ),
            const SizedBox(height: 14),
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text('تاريخ التنفيذ:'),
              trailing: Text(
                DateTimeUtils.formatDate(_selectedDate),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.calendar_month),
              onTap: _pickDate,
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text('وقت التنبيه:'),
              trailing: Text(
                DateTimeUtils.formatTime12H(_selectedTime.hour, _selectedTime.minute),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              leading: const Icon(Icons.access_time),
              onTap: _pickTime,
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<TaskRecurrence>(
              value: _recurrence,
              decoration: const InputDecoration(
                labelText: 'نمط تكرار التنبيه',
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: TaskRecurrence.none, child: Text('مرة واحدة')),
                DropdownMenuItem(value: TaskRecurrence.daily, child: Text('يومياً')),
                DropdownMenuItem(value: TaskRecurrence.weekly, child: Text('أسبوعياً')),
                DropdownMenuItem(value: TaskRecurrence.monthly, child: Text('شهرياً')),
                DropdownMenuItem(value: TaskRecurrence.yearly, child: Text('سنوياً')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _recurrence = val);
              },
            ),
            const SizedBox(height: 10),
            // ⬇️ [إضافة جديدة]: زر تفعيل مهمة الطوارئ ⬇️
            SwitchListTile(
              title: const Text(
                'مهمة طوارئ',
                textAlign: TextAlign.right,
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              subtitle: const Text(
                'تفعيل هذا الخيار سيشغل نغمة تنبيه خاصة بالطوارئ.',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 11),
              ),
              value: _isEmergency,
              activeColor: Colors.red,
              secondary: const Icon(Icons.warning_amber_rounded, color: Colors.red),
              onChanged: (val) {
                setState(() => _isEmergency = val);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_titleController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('يرجى كتابة عنوان المهمة')),
              );
              return;
            }

            final finalDateTime = DateTime(
              _selectedDate.year,
              _selectedDate.month,
              _selectedDate.day,
              _selectedTime.hour,
              _selectedTime.minute,
            );

            final newTask = TaskItem(
              id: widget.task?.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: _titleController.text.trim(),
              notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
              scheduledDateTime: finalDateTime,
              recurrence: _recurrence,
              isCompleted: widget.task?.isCompleted ?? false,
              isEmergency: _isEmergency, // ⬅️ تمرير قيمة الطوارئ عند الحفظ
            );

            Navigator.pop(context, newTask);
          },
          child: const Text('حفظ المهمة'),
        ),
      ],
    );
  }
}
