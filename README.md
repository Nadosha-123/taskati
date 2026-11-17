# Taskati

Taskati is a Flutter task manager organized by feature. Routing uses GoRouter,
UI state uses Riverpod, tasks are stored in SQLite, and profile/theme settings
are stored locally with SharedPreferences.

## Project layout

- `lib/app`: app root and named GoRouter routes
- `lib/core`: theme, animation paths, and shared infrastructure
- `lib/features`: onboarding, profile, home, and task features
- `lib/shared`: reusable widgets shared by features

## Lottie assets

The intro uses `assets/animations/task_done.json` and the Home empty state uses
`assets/animations/task_loader.json`. Both supplied files are registered through
the `assets/animations/` directory in `pubspec.yaml`.

## Run and verify

Run `flutter pub get`, `flutter analyze`, and `flutter test` from the project
root. Profile photos are copied into the app's documents directory so the saved
image path survives application restarts.
