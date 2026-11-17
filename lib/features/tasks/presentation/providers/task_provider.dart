import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/task.dart';
import '../../domain/task_repository.dart';

final taskRepositoryProvider = Provider<TaskRepository>(
  (ref) => throw StateError('TaskRepository has not been initialized.'),
);

final taskControllerProvider = AsyncNotifierProvider<TaskController, TaskState>(
  TaskController.new,
);

enum TaskFilter { all, inProgress, completed }

class TaskState {
  const TaskState({
    required this.tasks,
    required this.selectedDate,
    required this.filter,
  });

  final List<Task> tasks;
  final DateTime selectedDate;
  final TaskFilter filter;

  List<Task> get tasksForSelectedDate => tasks
      .where((task) => _sameDay(task.date, selectedDate))
      .where((task) {
        return switch (filter) {
          TaskFilter.all => true,
          TaskFilter.inProgress => task.status == TaskStatus.inProgress,
          TaskFilter.completed => task.status == TaskStatus.completed,
        };
      })
      .toList(growable: false);

  int get completionPercentage {
    final dayTasks = tasks
        .where((task) => _sameDay(task.date, selectedDate))
        .toList();
    if (dayTasks.isEmpty) return 0;
    final completed = dayTasks
        .where((task) => task.status == TaskStatus.completed)
        .length;
    return (completed * 100 / dayTasks.length).round();
  }

  TaskState copyWith({
    List<Task>? tasks,
    DateTime? selectedDate,
    TaskFilter? filter,
  }) => TaskState(
    tasks: tasks ?? this.tasks,
    selectedDate: selectedDate ?? this.selectedDate,
    filter: filter ?? this.filter,
  );
}

class TaskController extends AsyncNotifier<TaskState> {
  @override
  Future<TaskState> build() async {
    final tasks = _sortTasks(await ref.read(taskRepositoryProvider).getAll());
    return TaskState(
      tasks: tasks,
      selectedDate: DateTime.now(),
      filter: TaskFilter.all,
    );
  }

  void selectDate(DateTime date) {
    state = AsyncData(state.requireValue.copyWith(selectedDate: date));
  }

  void selectFilter(TaskFilter filter) {
    state = AsyncData(state.requireValue.copyWith(filter: filter));
  }

  Future<void> add(Task task) async {
    await ref.read(taskRepositoryProvider).insert(task);
    final current = state.requireValue;
    state = AsyncData(
      current.copyWith(tasks: _sortTasks([...current.tasks, task])),
    );
  }

  Future<void> updateTask(Task task) async {
    await ref.read(taskRepositoryProvider).update(task);
    final current = state.requireValue;
    final tasks = [
      for (final existing in current.tasks)
        if (existing.id == task.id) task else existing,
    ];
    state = AsyncData(current.copyWith(tasks: _sortTasks(tasks)));
  }

  Future<void> delete(String id) async {
    await ref.read(taskRepositoryProvider).delete(id);
    final tasks = state.requireValue.tasks
        .where((task) => task.id != id)
        .toList();
    state = AsyncData(state.requireValue.copyWith(tasks: tasks));
  }

  Future<void> toggleCompleted(Task task) async {
    await updateTask(
      task.copyWith(
        status: task.status == TaskStatus.completed
            ? TaskStatus.inProgress
            : TaskStatus.completed,
        updatedAt: DateTime.now(),
      ),
    );
  }
}

List<Task> _sortTasks(List<Task> tasks) {
  tasks.sort((first, second) {
    final dateOrder = first.date.compareTo(second.date);
    return dateOrder == 0
        ? first.startTime.compareTo(second.startTime)
        : dateOrder;
  });
  return tasks;
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
