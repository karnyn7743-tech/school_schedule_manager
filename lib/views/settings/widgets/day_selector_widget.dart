import 'package:flutter/material.dart';
import '../../../models/school_day_config.dart';
import '../../../core/constants/app_colors.dart';

class DaySelectorWidget extends StatelessWidget {
  final List<SchoolDayConfig> days;
  final Function(int index, bool value) onDayToggled;

  const DaySelectorWidget({
    super.key,
    required this.days,
    required this.onDayToggled,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.cardBorder),
      ),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.calendar_month, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  'أيام الدوام المدرسي الأسبوعية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'حدد الأيام التي ترغب في تفعيل أجراس الحصص خلالها تلقائياً:',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const Divider(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: List.generate(days.length, (index) {
                final day = days[index];
                return FilterChip(
                  label: Text(day.dayName),
                  selected: day.isEnabled,
                  selectedColor: AppColors.primary.withOpacity(0.15),
                  checkmarkColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: day.isEnabled ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: day.isEnabled ? FontWeight.bold : FontWeight.normal,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(
                      color: day.isEnabled ? AppColors.primary : AppColors.cardBorder,
                    ),
                  ),
                  onSelected: (bool selected) {
                    onDayToggled(index, selected);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

