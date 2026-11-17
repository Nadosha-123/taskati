import 'package:flutter_test/flutter_test.dart';
import 'package:taskati/features/tasks/domain/task.dart';
import 'package:taskati/features/tasks/presentation/providers/task_provider.dart';

void main() {
  final day = DateTime(2026, 11, 17);
  final task = Task(
    id: 'task-1',
    title: 'Review sprint',
    description: 'Check the open items',
    date: day,
    startTime: DateTime(2026, 11, 17, 9),
    endTime: DateTime(2026, 11, 17, 10),
    status: TaskStatus.inProgress,
    createdAt: day,
    updatedAt: day,
  );

  test('task round-trips through the local database map format', () {
    final restored = Task.fromMap(task.toMap());

    expect(restored.id, task.id);
    expect(restored.date, task.date);
    expect(restored.startTime, task.startTime);
    expect(restored.status, TaskStatus.inProgress);
  });

  test('task state filters by selected date and completion status', () {
    final state = TaskState(
      tasks: [
        task,
        Task(
          id: 'task-2',
          title: task.title,
          description: task.description,
          date: task.date,
          startTime: task.startTime,
          endTime: task.endTime,
          status: TaskStatus.completed,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
        ),
        Task(
          id: 'task-3',
          title: task.title,
          description: task.description,
          date: day.add(const Duration(days: 1)),
          startTime: task.startTime,
          endTime: task.endTime,
          status: task.status,
          createdAt: task.createdAt,
          updatedAt: task.updatedAt,
        ),
      ],
      selectedDate: day,
      filter: TaskFilter.completed,
    );

    expect(state.tasksForSelectedDate.map((task) => task.id), ['task-2']);
    expect(state.completionPercentage, 50);
  });
}
