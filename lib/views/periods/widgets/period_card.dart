import 'package:flutter/material.dart';
import '../../../models/class_period_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_time_utils.dart';

class PeriodCard extends StatelessWidget {
  final ClassPeriod period;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PeriodCard({
    super.key,
    required this.period,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    // حساب مدة الحصة بالدقائق
    final int duration = DateTimeUtils.calculateDurationMinutes(
      period.startHour,
      period.startMinute,
      period.endHour,
      period.endMinute,
    );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: period.isBreak ? AppColors.breakTime.withOpacity(0.4) : AppColors.cardBorder,
          width: 1.2,
        ),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // أيقونة مميزة للحصة أو الفسحة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: period.isBreak
                    ? AppColors.breakTime.withOpacity(0.12)
                    : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                period.isBreak ? Icons.free_breakfast_outlined : Icons.school_outlined,
                color: period.isBreak ? AppColors.breakTime : AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(width: 14),

            // تفاصيل الحصة والوقت
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        period.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: period.isBreak ? AppColors.breakTime : AppColors.textPrimary,
                        ),
                      ),
                      if (period.isBreak) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.breakTime.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'راحة',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.breakTime,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'من ${DateTimeUtils.formatTime12H(period.startHour, period.startMinute)} إلى ${DateTimeUtils.formatTime12H(period.endHour, period.endMinute)}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '($duration دقيقة)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // أزرار التعديل والحذف
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.blueAccent, size: 22),
                  tooltip: 'تعديل',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 22),
                  tooltip: 'حذف',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('تأكيد الحذف', textAlign: TextAlign.right),
                        content: Text('هل ترغب في حذف "${period.title}" وإلغاء تنبيهاتها؟'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('إلغاء'),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                            onPressed: () {
                              Navigator.pop(ctx);
                              onDelete();
                            },
                            child: const Text('حذف'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

