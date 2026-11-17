import 'package:sqflite/sqflite.dart';

import '../domain/task.dart';
import '../domain/task_repository.dart' as domain;
import 'task_database.dart';

class SqliteTaskRepository implements domain.TaskRepository {
  const SqliteTaskRepository(this._database);

  final TaskDatabase _database;

  @override
  Future<List<Task>> getAll() async {
    final rows = await _database.database.query(
      'tasks',
      orderBy: 'date ASC, start_time ASC',
    );
    return rows.map(Task.fromMap).toList(growable: false);
  }

  @override
  Future<void> insert(Task task) async {
    await _database.database.insert(
      'tasks',
      task.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> update(Task task) async {
    final changed = await _database.database.update(
      'tasks',
      task.toMap(),
      where: 'id = ?',
      whereArgs: [task.id],
    );
    if (changed != 1) {
      throw StateError('Cannot update missing task "${task.id}".');
    }
  }

  @override
  Future<void> delete(String id) async {
    final changed = await _database.database.delete(
      'tasks',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (changed != 1) {
      throw StateError('Cannot delete missing task "$id".');
    }
  }
}
