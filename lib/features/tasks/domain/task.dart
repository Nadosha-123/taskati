enum TaskStatus { inProgress, completed }

class Task {
  const Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String title;
  final String description;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final TaskStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task copyWith({
    String? title,
    String? description,
    DateTime? date,
    DateTime? startTime,
    DateTime? endTime,
    TaskStatus? status,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'date': date.toIso8601String(),
    'start_time': startTime.toIso8601String(),
    'end_time': endTime.toIso8601String(),
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory Task.fromMap(Map<String, Object?> map) => Task(
    id: map['id']! as String,
    title: map['title']! as String,
    description: map['description']! as String,
    date: DateTime.parse(map['date']! as String),
    startTime: DateTime.parse(map['start_time']! as String),
    endTime: DateTime.parse(map['end_time']! as String),
    status: TaskStatus.values.byName(map['status']! as String),
    createdAt: DateTime.parse(map['created_at']! as String),
    updatedAt: DateTime.parse(map['updated_at']! as String),
  );
}
