import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskati/features/tasks/domain/task.dart';
import 'package:taskati/features/tasks/domain/task_repository.dart';
import 'package:taskati/features/tasks/presentation/providers/task_provider.dart';

void main() {
  test(
    'task edits update the existing item and status changes persist',
    () async {
      final repository = _MemoryTaskRepository();
      final container = ProviderContainer(
        overrides: [taskRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(taskControllerProvider.future);
      final controller = container.read(taskControllerProvider.notifier);
      final now = DateTime(2026, 11, 17);
      final task = Task(
        id: 'existing-id',
        title: 'Original',
        description: '',
        date: now,
        startTime: DateTime(2026, 11, 17, 9),
        endTime: DateTime(2026, 11, 17, 10),
        status: TaskStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      );

      await controller.add(task);
      await controller.updateTask(task.copyWith(title: 'Updated'));
      expect(repository.tasks, hasLength(1));
      expect(repository.tasks.single.title, 'Updated');

      await controller.toggleCompleted(repository.tasks.single);
      expect(repository.tasks.single.status, TaskStatus.completed);
      expect(
        container
            .read(taskControllerProvider)
            .requireValue
            .completionPercentage,
        100,
      );

      await controller.delete(task.id);
      expect(repository.tasks, isEmpty);
      expect(
        container.read(taskControllerProvider).requireValue.tasks,
        isEmpty,
      );
    },
  );
}

class _MemoryTaskRepository implements TaskRepository {
  final Map<String, Task> _tasks = {};

  List<Task> get tasks => _tasks.values.toList(growable: false);

  @override
  Future<List<Task>> getAll() async => tasks;

  @override
  Future<void> insert(Task task) async {
    if (_tasks.containsKey(task.id)) {
      throw StateError('Duplicate task ID: ${task.id}');
    }
    _tasks[task.id] = task;
  }

  @override
  Future<void> update(Task task) async {
    if (!_tasks.containsKey(task.id)) {
      throw StateError('Missing task ID: ${task.id}');
    }
    _tasks[task.id] = task;
  }

  @override
  Future<void> delete(String id) async {
    if (_tasks.remove(id) == null) {
      throw StateError('Missing task ID: $id');
    }
  }
}
