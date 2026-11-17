import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/presentation/providers/profile_provider.dart';
import 'features/tasks/data/task_database.dart';
import 'features/tasks/data/task_repository.dart';
import 'features/tasks/presentation/providers/task_provider.dart';
import 'core/theme/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  final database = await TaskDatabase.open();

  runApp(
    ProviderScope(
      overrides: [
        profileRepositoryProvider.overrideWithValue(
          PreferencesProfileRepository(preferences),
        ),
        taskRepositoryProvider.overrideWithValue(
          SqliteTaskRepository(database),
        ),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
      child: const TaskatiApp(),
    ),
  );
}
