import 'package:flutter/material.dart';
import '../../models/class_period_model.dart';
import '../../core/utils/date_time_utils.dart';

class AddEditPeriodDialog extends StatefulWidget {
  final ClassPeriod? period;

  const AddEditPeriodDialog({super.key, this.period});

  @override
  State<AddEditPeriodDialog> createState() => _AddEditPeriodDialogState();
}

class _AddEditPeriodDialogState extends State<AddEditPeriodDialog> {
  late TextEditingController _titleController;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isBreak;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.period?.title ?? '');
    _startTime = widget.period != null
        ? TimeOfDay(hour: widget.period!.startHour, minute: widget.period!.startMinute)
        : const TimeOfDay(hour: 8, minute: 0);
    _endTime = widget.period != null
        ? TimeOfDay(hour: widget.period!.endHour, minute: widget.period!.endMinute)
        : const TimeOfDay(hour: 8, minute: 45);
    _isBreak = widget.period?.isBreak ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final initial = isStart ? _startTime : _endTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.period != null;

    return AlertDialog(
      title: Text(
        isEditing ? 'تعديل الفترة الدراسية' : 'إضافة حصة / فترة جديدة',
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
                labelText: 'اسم الحصة أو النشاط (مثلاً: الحصة الأولى)',
                prefixIcon: Icon(Icons.school_outlined),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text('وقت البداية:'),
              trailing: Text(
                DateTimeUtils.formatTime12H(_startTime.hour, _startTime.minute),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              leading: const Icon(Icons.access_time),
              onTap: () => _selectTime(true),
            ),
            const SizedBox(height: 10),
            ListTile(
              tileColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              title: const Text('وقت النهاية:'),
              trailing: Text(
                DateTimeUtils.formatTime12H(_endTime.hour, _endTime.minute),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              leading: const Icon(Icons.access_time_filled),
              onTap: () => _selectTime(false),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('فترة راحة / فسحة'),
              value: _isBreak,
              onChanged: (val) {
                setState(() {
                  _isBreak = val;
                  if (val && _titleController.text.isEmpty) {
                    _titleController.text = 'فترة الراحة (الفسحة)';
                  }
                });
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
                const SnackBar(content: Text('يرجى إدخال اسم الحصة')),
              );
              return;
            }

            final newPeriod = ClassPeriod(
              id: widget.period?.id ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
              title: _titleController.text.trim(),
              startHour: _startTime.hour,
              startMinute: _startTime.minute,
              endHour: _endTime.hour,
              endMinute: _endTime.minute,
              isBreak: _isBreak,
            );

            Navigator.pop(context, newPeriod);
          },
          child: const Text('حفظ'),
        ),
      ],
    );
  }
}

