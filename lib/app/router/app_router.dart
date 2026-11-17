import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/onboarding/presentation/screens/splash_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/tasks/presentation/screens/task_form_screen.dart';
import '../../core/widgets/app_theme_toggle.dart';
import 'route_names.dart';
import 'route_paths.dart';

final appRouter = GoRouter(
  initialLocation: RoutePaths.splash,
  routes: [
    GoRoute(
      path: RoutePaths.splash,
      name: RouteNames.splash,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: RoutePaths.completeProfile,
      name: RouteNames.completeProfile,
      builder: (context, state) => const ProfileScreen(isSetup: true),
    ),
    GoRoute(
      path: RoutePaths.home,
      name: RouteNames.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: RoutePaths.profile,
      name: RouteNames.profile,
      builder: (context, state) => const ProfileScreen(isSetup: false),
    ),
    GoRoute(
      path: RoutePaths.addTask,
      name: RouteNames.addTask,
      builder: (context, state) => TaskFormScreen(
        initialDate: state.extra is DateTime ? state.extra! as DateTime : null,
      ),
    ),
    GoRoute(
      path: RoutePaths.editTask,
      name: RouteNames.editTask,
      builder: (context, state) =>
          TaskFormScreen(taskId: state.pathParameters['taskId']),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    body: SafeArea(
      child: Stack(
        children: [
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Unable to open this page: ${state.error}'),
            ),
          ),
          const PositionedDirectional(top: 8, end: 8, child: AppThemeToggle()),
        ],
      ),
    ),
  ),
);
