import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateTimeUtils {
  // تنسيق الوقت بنظام 12 ساعة (مثال: 08:30 ص أو 01:15 م)
  static String formatTime12H(int hour, int minute) {
    final period = hour >= 12 ? 'م' : 'ص';
    final formattedHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final formattedMinute = minute.toString().padLeft(2, '0');
    return '$formattedHour:$formattedMinute $period';
  }

  // تنسيق الوقت رقمياً (مثال: 08:30)
  static String formatTimeDigits(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  // تنسيق التاريخ الميلادي (مثال: 2026/11/03)
  static String formatDate(DateTime date) {
    return DateFormat('yyyy/MM/dd').format(date);
  }

  // الحصول على اسم اليوم بالعربية بحسب رقمه في نظام DateTime
  static String getArabicDayName(int weekday) {
    switch (weekday) {
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      default:
        return '';
    }
  }

  // حساب الفارق بالدقائق بين وقتين
  static int calculateDurationMinutes(
    int startHour,
    int startMinute,
    int endHour,
    int endMinute,
  ) {
    final startTotal = startHour * 60 + startMinute;
    final endTotal = endHour * 60 + endMinute;
    return endTotal - startTotal;
  }
}

