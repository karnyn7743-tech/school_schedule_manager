import 'dart:io';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/class_period_model.dart';

class ExcelService {
  // تصدير جدول الحصص إلى ملف إكسل ومشاركته
  static Future<void> exportSchedule(List<ClassPeriod> periods) async {
    final excel = Excel.createExcel();
    final Sheet sheet = excel['جدول الحصص'];
    excel.setDefaultSheet('جدول الحصص');

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
      final String firstSheet = excel.tables.keys.first;
      final sheet = excel.tables[firstSheet];

      if (sheet != null) {
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
              id: DateTime.now().millisecondsSinceEpoch + i,
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
}

