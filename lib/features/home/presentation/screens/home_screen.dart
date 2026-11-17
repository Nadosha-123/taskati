import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/route_names.dart';
import '../../../../core/constants/animation_paths.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/app_lottie.dart';
import '../../../../core/widgets/figma_background.dart';
import '../../../../shared/widgets/profile_avatar.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../tasks/domain/task.dart';
import '../../../tasks/presentation/providers/task_provider.dart';
import '../widgets/task_swipe_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String? _revealedTaskId;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider).asData?.value;
    final taskState = ref.watch(taskControllerProvider);

    return Scaffold(
      body: FigmaBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final frameWidth = constraints.maxWidth
                  .clamp(0.0, 375.0)
                  .toDouble();
              return Center(
                child: SizedBox(
                  width: frameWidth,
                  height: constraints.maxHeight,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: taskState.when(
                          loading: () =>
                              const Center(child: CircularProgressIndicator()),
                          error: (error, stackTrace) => _LoadError(
                            message: 'Could not load tasks: $error',
                            onRetry: () =>
                                ref.invalidate(taskControllerProvider),
                          ),
                          data: (data) {
                            final dayTasks = data.tasks
                                .where(
                                  (task) =>
                                      _sameDay(task.date, data.selectedDate),
                                )
                                .toList(growable: false);
                            final completed = dayTasks
                                .where(
                                  (task) => task.status == TaskStatus.completed,
                                )
                                .length;

                            return CustomScrollView(
                              slivers: [
                                SliverPadding(
                                  padding: const EdgeInsets.fromLTRB(
                                    22,
                                    0,
                                    22,
                                    92,
                                  ),
                                  sliver: SliverList.list(
                                    children: [
                                      _HomeHeader(
                                        name: profile?.name ?? 'Taskati',
                                        imagePath: profile?.imagePath,
                                        onProfile: () => context.pushNamed(
                                          RouteNames.profile,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      _ProgressCard(
                                        completedPercentage:
                                            data.completionPercentage,
                                        completed: completed,
                                        total: dayTasks.length,
                                        selectedDate: data.selectedDate,
                                        onTap: () => _pickDate(
                                          context,
                                          data.selectedDate,
                                          _selectDate,
                                        ),
                                      ),
                                      const SizedBox(height: 29),
                                      _DateSelector(
                                        selectedDate: data.selectedDate,
                                        onSelected: _selectDate,
                                        onOpenPicker: () => _pickDate(
                                          context,
                                          data.selectedDate,
                                          _selectDate,
                                        ),
                                      ),
                                      const SizedBox(height: 34),
                                      _FilterRow(
                                        selected: data.filter,
                                        onSelected: _selectFilter,
                                      ),
                                      const SizedBox(height: 30),
                                      if (data.tasksForSelectedDate.isEmpty)
                                        _EmptyTasks(
                                          hasTasksOnDate: dayTasks.isNotEmpty,
                                        )
                                      else
                                        ...data.tasksForSelectedDate.map(
                                          (task) => Padding(
                                            key: ValueKey(task.id),
                                            padding: const EdgeInsets.only(
                                              bottom: 18,
                                            ),
                                            child: TaskSwipeCard(
                                              task: task,
                                              isRevealed:
                                                  _revealedTaskId == task.id,
                                              onRevealChanged: (revealed) =>
                                                  _setRevealedTask(
                                                    task.id,
                                                    revealed,
                                                  ),
                                              onTap: () =>
                                                  _editTask(context, task.id),
                                              onEdit: () =>
                                                  _editTask(context, task.id),
                                              onDelete: () => _deleteTask(
                                                context,
                                                ref,
                                                task,
                                              ),
                                              onComplete: () => _toggleTask(
                                                context,
                                                ref,
                                                task,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      Positioned(
                        right: 22,
                        bottom: 12,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Material(
                            color: AppColors.primary,
                            shape: const CircleBorder(),
                            elevation: 3,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: () {
                                _clearRevealedTask();
                                context.pushNamed(
                                  RouteNames.addTask,
                                  extra: taskState.asData?.value.selectedDate,
                                );
                              },
                              child: const Icon(
                                Icons.add,
                                size: 23,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _setRevealedTask(String id, bool revealed) {
    if (revealed) {
      if (_revealedTaskId != id) setState(() => _revealedTaskId = id);
    } else if (_revealedTaskId == id) {
      setState(() => _revealedTaskId = null);
    }
  }

  void _clearRevealedTask() {
    if (_revealedTaskId != null) setState(() => _revealedTaskId = null);
  }

  void _selectDate(DateTime date) {
    _clearRevealedTask();
    ref.read(taskControllerProvider.notifier).selectDate(date);
  }

  void _selectFilter(TaskFilter filter) {
    _clearRevealedTask();
    ref.read(taskControllerProvider.notifier).selectFilter(filter);
  }

  void _editTask(BuildContext context, String taskId) {
    _clearRevealedTask();
    context.pushNamed(RouteNames.editTask, pathParameters: {'taskId': taskId});
  }

  Future<void> _pickDate(
    BuildContext context,
    DateTime selectedDate,
    ValueChanged<DateTime> onSelected,
  ) async {
    final date = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null) onSelected(date);
  }

  Future<void> _toggleTask(
    BuildContext context,
    WidgetRef ref,
    Task task,
  ) async {
    try {
      await ref.read(taskControllerProvider.notifier).toggleCompleted(task);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not update task: $error')),
        );
      }
    }
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
  });

  final String name;
  final String? imagePath;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      height: 50,
      child: Row(
        children: [
          InkWell(
            onTap: onProfile,
            customBorder: const CircleBorder(),
            child: ProfileAvatar(name: name, imagePath: imagePath, radius: 25),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hello!',
                  style: AppTextStyles.caption.copyWith(
                    color: isDark ? Colors.white : AppColors.darkText,
                    fontSize: 13,
                  ),
                ),
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.title.copyWith(
                    color: isDark ? Colors.white : AppColors.primary,
                    fontSize: 18,
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

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.completedPercentage,
    required this.completed,
    required this.total,
    required this.selectedDate,
    required this.onTap,
  });

  final int completedPercentage;
  final int completed;
  final int total;
  final DateTime selectedDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final progress = (completedPercentage / 100).clamp(0.0, 1.0);
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: SizedBox(
          height: 105,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _formatProgressDate(selectedDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        total == 0
                            ? 'Plan your day'
                            : 'Your today’s task almost done!',
                        maxLines: 2,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          height: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$completed/$total tasks completed',
                        maxLines: 1,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                          height: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                SizedBox.square(
                  dimension: 72,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: progress),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, _) =>
                            CircularProgressIndicator(
                              value: value,
                              backgroundColor: Colors.white24,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 7,
                            ),
                      ),
                      Center(
                        child: Text(
                          '$completedPercentage%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
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
    );
  }
}

class _DateSelector extends StatelessWidget {
  const _DateSelector({
    required this.selectedDate,
    required this.onSelected,
    required this.onOpenPicker,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    final start = selectedDate.subtract(const Duration(days: 2));
    return Row(
      children: List.generate(5, (index) {
        final date = start.add(Duration(days: index));
        final selected = _sameDay(date, selectedDate);
        final textColor = Theme.of(context).colorScheme.onSurface;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () => onSelected(date),
              onLongPress: onOpenPicker,
              borderRadius: BorderRadius.circular(15),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 84,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.primary
                      : Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _shortMonth(date.month),
                      style: TextStyle(
                        color: selected ? Colors.white : textColor,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      '${date.day}',
                      style: TextStyle(
                        color: selected ? Colors.white : textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      _weekday(date.weekday),
                      style: TextStyle(
                        color: selected
                            ? Colors.white
                            : AppColors.secondaryText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelected});

  final TaskFilter selected;
  final ValueChanged<TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final filters = TaskFilter.values;
    return Row(
      children: [
        for (var index = 0; index < filters.length; index++)
          Expanded(
            flex: switch (filters[index]) {
              TaskFilter.all => 10,
              TaskFilter.inProgress => 16,
              TaskFilter.completed => 15,
            },
            child: Padding(
              padding: EdgeInsets.only(
                right: index == filters.length - 1 ? 0 : 8,
              ),
              child: _FilterButton(
                filter: filters[index],
                selected: filters[index] == selected,
                onSelected: onSelected,
              ),
            ),
          ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.filter,
    required this.selected,
    required this.onSelected,
  });

  final TaskFilter filter;
  final bool selected;
  final ValueChanged<TaskFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    final label = switch (filter) {
      TaskFilter.all => 'All',
      TaskFilter.inProgress => 'In Progress',
      TaskFilter.completed => 'Completed',
    };
    return Material(
      color: selected ? AppColors.primary : AppColors.lightAccent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => onSelected(filter),
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          height: 30,
          child: Center(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
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
            style: AppTextStyles.title.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a task to get started.',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.secondaryText,
            ),
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

String _formatProgressDate(DateTime date) =>
    '${_shortWeekday(date.weekday)}, ${date.day} ${_shortMonth(date.month)}';

String _shortMonth(int month) => const [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
][month - 1];

String _shortWeekday(int weekday) =>
    const ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][weekday - 1];

String _weekday(int weekday) => _shortWeekday(weekday);

bool _sameDay(DateTime first, DateTime second) =>
    first.year == second.year &&
    first.month == second.month &&
    first.day == second.day;
