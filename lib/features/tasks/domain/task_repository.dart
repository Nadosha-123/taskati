import 'task.dart';

abstract interface class TaskRepository {
  Future<List<Task>> getAll();
  Future<void> insert(Task task);
  Future<void> update(Task task);
  Future<void> delete(String id);
}
