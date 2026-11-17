abstract final class RoutePaths {
  static const splash = '/';
  static const completeProfile = '/profile/setup';
  static const home = '/home';
  static const profile = '/profile';
  static const addTask = '/tasks/new';
  static const editTask = '/tasks/:taskId/edit';

  static String editTaskFor(String taskId) =>
      '/tasks/${Uri.encodeComponent(taskId)}/edit';
}
