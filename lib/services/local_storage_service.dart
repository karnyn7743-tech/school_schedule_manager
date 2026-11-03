import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/class_period_model.dart';
import '../models/task_item_model.dart';
import '../models/school_day_config.dart';

class LocalStorageService {
  static const String _periodsKey = 'saved_school_periods';
  static const String _tasksKey = 'saved_school_tasks';
  static const String _daysKey = 'saved_school_days';

  // --- حفظ واسترجاع الحصص ---
  static Future<void> savePeriods(List<ClassPeriod> periods) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(periods.map((p) => p.toMap()).toList());
    await prefs.setString(_periodsKey, data);
  }

  static Future<List<ClassPeriod>> loadPeriods() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_periodsKey);
    if (data == null || data.isEmpty) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => ClassPeriod.fromMap(e)).toList();
  }

  // --- حفظ واسترجاع المهام ---
  static Future<void> saveTasks(List<TaskItem> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await prefs.setString(_tasksKey, data);
  }

  static Future<List<TaskItem>> loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_tasksKey);
    if (data == null || data.isEmpty) return [];
    final List decoded = jsonDecode(data);
    return decoded.map((e) => TaskItem.fromMap(e)).toList();
  }

  // --- حفظ واسترجاع إعدادات أيام الدوام ---
  static Future<void> saveSchoolDays(List<SchoolDayConfig> days) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(days.map((d) => d.toMap()).toList());
    await prefs.setString(_daysKey, data);
  }

  static Future<List<SchoolDayConfig>> loadSchoolDays() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_daysKey);
    if (data == null || data.isEmpty) {
      return SchoolDayConfig.defaultDays();
    }
    final List decoded = jsonDecode(data);
    return decoded.map((e) => SchoolDayConfig.fromMap(e)).toList();
  }
}

