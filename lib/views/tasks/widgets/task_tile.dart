import 'package:flutter/material.dart';
import '../../../models/task_item_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_utils.dart';

class TaskTile extends StatelessWidget {
  final TaskItem task;
  final ValueChanged<bool?> onToggleComplete;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TaskTile({
    super.key,
    required this.task,
    required this.onToggleComplete,
    required this.onEdit,
    required this.onDelete,
  });

  String _getRecurrenceText(TaskRecurrence recurrence) {
    switch (recurrence) {
      case TaskRecurrence.daily:
        return 'يتكرر يومياً';
      case TaskRecurrence.weekly:
        return 'يتكرر أسبوعياً';
      case TaskRecurrence.monthly:
        return 'يتكرر شهرياً';
      case TaskRecurrence.yearly:
        return 'يتكرر سنوياً';
      case TaskRecurrence.none:
        return 'مرة واحدة';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: task.isCompleted,
              activeColor: AppColors.taskCompleted,
              onChanged: onToggleComplete,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: task.isCompleted
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateTimeUtils.formatDate(task.scheduledDateTime),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.access_time, size: 13, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        DateTimeUtils.formatTime12H(
                          task.scheduledDateTime.hour,
                          task.scheduledDateTime.minute,
                        ),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      _getRecurrenceText(task.recurrence),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (task.notes != null && task.notes!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      task.notes!,
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 20),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

