class ClassPeriod {
  final int id;
  final String title;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final bool isBreak; // لتحديد ما إذا كانت فترة راحة/فسحة

  ClassPeriod({
    required this.id,
    required this.title,
    required this.startHour,
    required this.startMinute,
    required this.endHour,
    required this.endMinute,
    this.isBreak = false,
  });

  // تنسيق وقت البداية
  String get startTimeFormatted =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}';

  // تنسيق وقت النهاية
  String get endTimeFormatted =>
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  // تحويل إلى Map للتخزين المحلي
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'startHour': startHour,
      'startMinute': startMinute,
      'endHour': endHour,
      'endMinute': endMinute,
      'isBreak': isBreak,
    };
  }

  // استرجاع الكائن من Map
  factory ClassPeriod.fromMap(Map<String, dynamic> map) {
    return ClassPeriod(
      id: map['id'] as int,
      title: map['title'] as String,
      startHour: map['startHour'] as int,
      startMinute: map['startMinute'] as int,
      endHour: map['endHour'] as int,
      endMinute: map['endMinute'] as int,
      isBreak: map['isBreak'] as bool? ?? false,
    );
  }
}

