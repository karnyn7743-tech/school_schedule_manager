import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // ⬅️ [إضافة جديدة]: لتنسيق التاريخ
import '../models/class_period_model.dart';
import '../models/task_item_model.dart'; // ⬅️ [إضافة جديدة]: لاستيراد وتصدير المهام

class ExcelService {
  // تصدير جدول الحصص إلى ملف إكسل ومشاركته
  static Future<void> exportSchedule(List<ClassPeriod> periods) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['class']; // ⬅️ [تعديل]: توحيد اسم الورقة
    excel.setDefaultSheet('class');

    // ترويسة الأعمدة
    sheet.appendRow([
      TextCellValue('م'),
      TextCellValue('اسم الحصة / النشاط'),
      TextCellValue('ساعة البداية'),
      TextCellValue('دقيقة البداية'),
      TextCellValue('ساعة النهاية'),
      TextCellValue('دقيقة النهاية'),
      TextCellValue('هل هي راحة (نعم/لا)'),
    ]);

    // إضافة صفوف الحصص
    for (int i = 0; i < periods.length; i++) {
      final p = periods[i];
      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(p.title),
        IntCellValue(p.startHour),
        IntCellValue(p.startMinute),
        IntCellValue(p.endHour),
        IntCellValue(p.endMinute),
        TextCellValue(p.isBreak ? 'نعم' : 'لا'),
      ]);
    }

    // حفظ الملف المؤقت وفتحه للمشاركة
    final directory = await getTemporaryDirectory();
    final filePath =
        '${directory.path}/School_Schedule_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    final bytes = excel.encode();

    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'جدول دوام وحصص المدرسة',
      );
    }
  }

  // استيراد جدول الحصص من ملف إكسل محلي
  static Future<List<ClassPeriod>?> importSchedule() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final List<ClassPeriod> imported = [];
      
      // ⬇️ [تعديل]: البحث عن ورقة 'class' تحديداً بدلاً من الورقة الأولى
      final sheet = excel.tables['class']; 

      if (sheet != null) {
        // توليد معرف أساسي آمن من الوقت الحالي لا يتجاوز نطاق 32-bit
        final int baseId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 10000;

        // البدء من الصف الثاني لتخطي الترويسة
        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row.length < 6 || row[1] == null) continue;

          final String title = row[1]?.value?.toString().trim() ?? '';
          if (title.isEmpty) continue;

          final int startH = int.tryParse(row[2]?.value?.toString() ?? '8') ?? 8;
          final int startM = int.tryParse(row[3]?.value?.toString() ?? '0') ?? 0;
          final int endH = int.tryParse(row[4]?.value?.toString() ?? '8') ?? 8;
          final int endM = int.tryParse(row[5]?.value?.toString() ?? '45') ?? 45;
          final bool isBreak = row.length > 6 &&
              (row[6]?.value?.toString().trim() == 'نعم' ||
                  row[6]?.value?.toString().trim().toLowerCase() == 'yes');

          imported.add(
            ClassPeriod(
              id: (baseId * 100) + i,
              title: title,
              startHour: startH,
              startMinute: startM,
              endHour: endH,
              endMinute: endM,
              isBreak: isBreak,
            ),
          );
        }
      }
      return imported;
    }
    return null;
  }

  // ⬇️ [إضافة جديدة]: تصدير المهام إلى ورقة 'task_w'
  static Future<void> exportTasks(List<TaskItem> tasks) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['task_w'];
    excel.setDefaultSheet('task_w');

    // ترويسة الأعمدة (مطابقة للصورة)
    sheet.appendRow([
      TextCellValue('م'),
      TextCellValue('عنوان المهمة'),
      TextCellValue('ملاحظات وتفاصيل إضافية'),
      TextCellValue('تاريخ التنفيذ'),
      TextCellValue('وقت التنبيه (ساعة)'),
      TextCellValue('وقت التنبيه (دقيقة)'),
      TextCellValue('نمط التكرار'),
      TextCellValue('مهمة طارئة (نعم/لا)'),
    ]);

    final dateFormat = DateFormat('dd/MM/yyyy');

    for (int i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      String recurrenceStr = 'مرة واحدة';
      switch (t.recurrence) {
        case TaskRecurrence.daily: recurrenceStr = 'يومياً'; break;
        case TaskRecurrence.weekly: recurrenceStr = 'أسبوعياً'; break;
        case TaskRecurrence.monthly: recurrenceStr = 'شهرياً'; break;
        case TaskRecurrence.yearly: recurrenceStr = 'سنوياً'; break;
        default: recurrenceStr = 'مرة واحدة';
      }

      sheet.appendRow([
        IntCellValue(i + 1),
        TextCellValue(t.title),
        TextCellValue(t.notes ?? ''),
        TextCellValue(dateFormat.format(t.scheduledDateTime)),
        IntCellValue(t.scheduledDateTime.hour),
        IntCellValue(t.scheduledDateTime.minute),
        TextCellValue(recurrenceStr),
        TextCellValue(t.isEmergency ? 'نعم' : 'لا'),
      ]);
    }

    final directory = await getTemporaryDirectory();
    final filePath = '${directory.path}/School_Tasks_${DateTime.now().millisecondsSinceEpoch}.xlsx';
    final file = File(filePath);
    final bytes = excel.encode();

    if (bytes != null) {
      await file.writeAsBytes(bytes);
      await Share.shareXFiles(
        [XFile(filePath)],
        text: 'جدول المهام والأعمال',
      );
    }
  }

  // ⬇️ [إضافة جديدة]: استيراد المهام من ورقة 'task_w'
  static Future<List<TaskItem>?> importTasks() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );

    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final bytes = file.readAsBytesSync();
      final excel = Excel.decodeBytes(bytes);

      final List<TaskItem> imported = [];
      final sheet = excel.tables['task_w'];

      if (sheet != null) {
        final int baseId = (DateTime.now().millisecondsSinceEpoch ~/ 1000) % 1000000;

        for (int i = 1; i < sheet.maxRows; i++) {
          final row = sheet.rows[i];
          if (row.isEmpty || row.length < 8 || row[1] == null) continue;

          final String title = row[1]?.value?.toString().trim() ?? '';
          if (title.isEmpty) continue;

          final String notes = row[2]?.value?.toString().trim() ?? '';
          
          // قراءة التاريخ (تنسيق dd/MM/yyyy)
          final String dateStr = row[3]?.value?.toString().trim() ?? '';
          final dateParts = dateStr.split('/');
          if (dateParts.length < 3) continue; // تخطي إذا كان التاريخ غير صالح
          final int day = int.tryParse(dateParts[0]) ?? 1;
          final int month = int.tryParse(dateParts[1]) ?? 1;
          final int year = int.tryParse(dateParts[2]) ?? DateTime.now().year;

          // قراءة الساعة والدقيقة
          final int hour = int.tryParse(row[4]?.value?.toString() ?? '8') ?? 8;
          final int minute = int.tryParse(row[5]?.value?.toString() ?? '0') ?? 0;

          final DateTime scheduledDateTime = DateTime(year, month, day, hour, minute);

          // قراءة نمط التكرار
          final String recStr = row[6]?.value?.toString().trim() ?? 'مرة واحدة';
          TaskRecurrence rec = TaskRecurrence.none;
          if (recStr.contains('يوم')) rec = TaskRecurrence.daily;
          else if (recStr.contains('أسبوع')) rec = TaskRecurrence.weekly;
          else if (recStr.contains('شهر')) rec = TaskRecurrence.monthly;
          else if (recStr.contains('سنو')) rec = TaskRecurrence.yearly;

          // قراءة حالة الطوارئ
          final String emergencyStr = row[7]?.value?.toString().trim() ?? 'لا';
          final bool isEmergency = emergencyStr == 'نعم' || emergencyStr.toLowerCase() == 'yes';

          imported.add(
            TaskItem(
              id: baseId + i,
              title: title,
              notes: notes.isEmpty ? null : notes,
              scheduledDateTime: scheduledDateTime,
              recurrence: rec,
              isCompleted: false,
              isEmergency: isEmergency,
            ),
          );
        }
      }
      return imported;
    }
    return null;
  }
}
