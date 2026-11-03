enum TaskRecurrence { none, daily, weekly, monthly, yearly }

class TaskItem {
  final int id;
  final String title;
  final DateTime scheduledDateTime;
  final String? notes;
  final TaskRecurrence recurrence;
  bool isCompleted;

  TaskItem({
    required this.id,
    required this.title,
    required this.scheduledDateTime,
    this.notes,
    this.recurrence = TaskRecurrence.none,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'scheduledDateTime': scheduledDateTime.toIso8601String(),
      'notes': notes,
      'recurrence': recurrence.index,
      'isCompleted': isCompleted,
    };
  }

  factory TaskItem.fromMap(Map<String, dynamic> map) {
    return TaskItem(
      id: map['id'] as int,
      title: map['title'] as String,
      scheduledDateTime: DateTime.parse(map['scheduledDateTime'] as String),
      notes: map['notes'] as String?,
      recurrence: TaskRecurrence.values[map['recurrence'] as int? ?? 0],
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

