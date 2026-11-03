class SchoolDayConfig {
  final int dayOfWeek; // 1 = الاثنين ... 6 = السبت، 7 = الأحد
  final String dayName;
  bool isEnabled;

  SchoolDayConfig({
    required this.dayOfWeek,
    required this.dayName,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'dayOfWeek': dayOfWeek,
      'dayName': dayName,
      'isEnabled': isEnabled,
    };
  }

  factory SchoolDayConfig.fromMap(Map<String, dynamic> map) {
    return SchoolDayConfig(
      dayOfWeek: map['dayOfWeek'] as int,
      dayName: map['dayName'] as String,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  // القائمة الافتراضية لأيام الأسبوع الدراسي (من السبت إلى الخميس)
  static List<SchoolDayConfig> defaultDays() {
    return [
      SchoolDayConfig(dayOfWeek: 6, dayName: 'السبت', isEnabled: true),
      SchoolDayConfig(dayOfWeek: 7, dayName: 'الأحد', isEnabled: true),
      SchoolDayConfig(dayOfWeek: 1, dayName: 'الإثنين', isEnabled: true),
      SchoolDayConfig(dayOfWeek: 2, dayName: 'الثلاثاء', isEnabled: true),
      SchoolDayConfig(dayOfWeek: 3, dayName: 'الأربعاء', isEnabled: true),
      SchoolDayConfig(dayOfWeek: 4, dayName: 'الخميس', isEnabled: true),
      SchoolDayConfig(dayOfWeek: 5, dayName: 'الجمعة', isEnabled: false),
    ];
  }
}

