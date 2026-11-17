import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/animation_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/widgets/app_lottie.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/providers/task_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    final taskState = ref.watch(taskControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: taskState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => _LoadError(
                message: 'Could not load tasks: $error',
                onRetry: () => ref.invalidate(taskControllerProvider),
              ),
              data: (data) => CustomScrollView(
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 28),
                    sliver: SliverList.list(
                      children: [
                        _HomeHeader(
                          name: profile?.name ?? 'Taskati',
                          imagePath: profile?.imagePath,
                          onProfile: () =>
                              context.pushNamed(RouteNames.profile),
                          onToggleTheme: () {
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            ref
                                .read(themeModeProvider.notifier)
                                .setThemeMode(
                                  isDark ? ThemeMode.light : ThemeMode.dark,
                                );
                          },
                        ),
                        const SizedBox(height: 22),
                        _ProgressCard(
                          completedPercentage: data.completionPercentage,
                          total: data.tasks
                              .where(
                                (task) =>
                                    _sameDay(task.date, data.selectedDate),
                              )
                              .length,
                        ),
                        const SizedBox(height: 24),
                        _DateSelector(
                          selectedDate: data.selectedDate,
                          onSelected: ref
                              .read(taskControllerProvider.notifier)
                              .selectDate,
                        ),
                        const SizedBox(height: 24),
                        _FilterRow(
                          selected: data.filter,
                          onSelected: ref
                              .read(taskControllerProvider.notifier)
                              .selectFilter,
                        ),
                        const SizedBox(height: 16),
                        if (data.tasksForSelectedDate.isEmpty)
                          _EmptyTasks(
                            hasTasksOnDate: data.tasks.any(
                              (task) => _sameDay(task.date, data.selectedDate),
                            ),
                          )
                        else
                          ...data.tasksForSelectedDate.map(
                            (task) => Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _TaskCard(
                                task: task,
                                onToggle: () => ref
                                    .read(taskControllerProvider.notifier)
                                    .toggleCompleted(task),
                                onEdit: () => context.pushNamed(
                                  RouteNames.editTask,
                                  pathParameters: {'taskId': task.id},
                                ),
                                onDelete: () => _deleteTask(context, ref, task),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final selectedDate = taskState.asData?.value.selectedDate;
          context.pushNamed(RouteNames.addTask, extra: selectedDate);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _deleteTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('“${task.title}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(taskControllerProvider.notifier).delete(task.id);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete task: $error')),
        );
      }
    }
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.name,
    required this.imagePath,
    required this.onProfile,
    required this.onToggleTheme,
  });

  final String name;
  final String? imagePath;
  final VoidCallback onProfile;
  final VoidCallback onToggleTheme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ProfileAvatar(name: name, imagePath: imagePath),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello!', style: Theme.of(context).textTheme.bodySmall),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Switch theme',
          onPressed: onToggleTheme,
          icon: Icon(
            Theme.of(context).brightness == Brightness.dark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
          ),
        ),
        IconButton(
          tooltip: 'Profile',
          onPressed: onProfile,
          icon: const Icon(Icons.person_outline),
        ),
      ],
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.completedPercentage, required this.total});

  final int completedPercentage;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  MaterialLocalizations.of(context)
                      .formatFullDate(DateTime.now()),
                  style: Theme.of(context).textTheme.bodySmall
                      ?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  total == 0
                      ? 'Plan your day'
                      : '$completedPercentage% of your tasks completed',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox.square(
            dimension: 64,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: completedPercentage / 100,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 6,
                ),
                Center(
                  child: Text(
                    '$completedPercentage%',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({required this.selectedDate, required this.onSelected});

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(const Duration(days: 2));
    return Column(
      children: [
        Row(
          children: List.generate(5, (index) {
            final date = start.add(Duration(days: index));
            final selected = _sameDay(date, selectedDate);
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onSelected(date),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.primary
                          : Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        Text(
                          _weekday(date.weekday),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: selected ? Colors.white70 : null,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${date.day}',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                color: selected ? Colors.white : null,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: TextButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (date != null) onSelected(date);
            },
            icon: const Icon(Icons.calendar_month_outlined, size: 18),
            label: const Text('Choose date'),
          ),
        ),
      ],
    );
  }

  String _weekday(int weekday) => switch (weekday) {
    DateTime.monday => 'Mon',
    DateTime.tuesday => 'Tue',
    DateTime.wednesday => 'Wed',
    DateTime.thursday => 'Thu',
    DateTime.friday => 'Fri',
    DateTime.saturday => 'Sat',
    _ => 'Sun',
  };
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: TaskFilter.values.map((filter) {
        final label = switch (filter) {
          TaskFilter.all => 'All',
          TaskFilter.inProgress => 'In Progress',
          TaskFilter.completed => 'Completed',
        };
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: filter == selected,
              onSelected: (_) => onSelected(filter),
              showCheckmark: false,
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(
                color: filter == selected ? Colors.white : null,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TaskCard extends StatelessWidget {
  const _TaskCard({
    required this.task,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time = MaterialLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
        child: Row(
          children: [
            Checkbox(
              value: task.status == TaskStatus.completed,
              onChanged: (_) => onToggle(),
              activeColor: AppColors.primary,
            ),
            Expanded(
              child: InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: task.status == TaskStatus.completed
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          task.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '${time.formatTimeOfDay(TimeOfDay.fromDateTime(task.startTime))} – '
                        '${time.formatTimeOfDay(TimeOfDay.fromDateTime(task.endTime))}',
                        style: Theme.of(context).textTheme.labelSmall
                            ?.copyWith(color: AppColors.secondaryText),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') onEdit();
                if (value == 'delete') onDelete();
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyTasks extends StatelessWidget {
  const _EmptyTasks({required this.hasTasksOnDate});

  final bool hasTasksOnDate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 28),
      child: Column(
        children: [
          const AppLottie(assetPath: AnimationPaths.emptyTasks, repeat: true),
          Text(
            hasTasksOnDate
                ? 'No tasks in this filter'
                : 'No tasks for this day',
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a task to get started.',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.secondaryText),
          ),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
