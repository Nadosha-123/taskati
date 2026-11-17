import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

class TaskDatabase {
  TaskDatabase._(this.database);

  final Database database;

  static Future<TaskDatabase> open() async {
    final databasePath = await getDatabasesPath();
    final database = await openDatabase(
      path.join(databasePath, 'taskati.db'),
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE tasks (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            date TEXT NOT NULL,
            start_time TEXT NOT NULL,
            end_time TEXT NOT NULL,
            status TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('CREATE INDEX tasks_date_idx ON tasks(date)');
      },
    );
    return TaskDatabase._(database);
  }
}
