import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/figma_background.dart';
import '../../../../core/widgets/figma_back_button.dart';
import '../../../../core/widgets/figma_button.dart';
import '../../../../core/widgets/figma_field.dart';
import '../providers/task_provider.dart';
import '../../domain/task.dart';

class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({this.taskId, this.initialDate, super.key});

  final String? taskId;
  final DateTime? initialDate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(taskControllerProvider);
    return tasks.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Could not load tasks: $error')),
      ),
      data: (data) {
        final task = taskId == null
            ? null
            : data.tasks.where((task) => task.id == taskId).firstOrNull;
        if (taskId != null && task == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('This task no longer exists.')),
          );
        }
        return _TaskFormEditor(
          key: ValueKey(task?.id ?? 'new-task'),
          task: task,
          initialDate: initialDate ?? data.selectedDate,
        );
      },
    );
  }
}

class _TaskFormEditor extends ConsumerStatefulWidget {
  const _TaskFormEditor({
    required this.task,
    required this.initialDate,
    super.key,
  });

  final Task? task;
  final DateTime initialDate;

  @override
  ConsumerState<_TaskFormEditor> createState() => _TaskFormEditorState();
}

class _TaskFormEditorState extends ConsumerState<_TaskFormEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _date;
  late DateTime _startTime;
  late DateTime _endTime;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(
      text: task?.description ?? '',
    );
    _date = _dateOnly(task?.date ?? widget.initialDate);
    _startTime =
        task?.startTime ?? _atTime(_date, const TimeOfDay(hour: 8, minute: 0));
    _endTime =
        task?.endTime ?? _atTime(_date, const TimeOfDay(hour: 9, minute: 0));
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected != null) {
      setState(() {
        _date = _dateOnly(selected);
        _startTime = _withDate(_startTime, _date);
        _endTime = _withDate(_endTime, _date);
      });
    }
  }

  Future<void> _selectTime({required bool start}) async {
    final current = start ? _startTime : _endTime;
    final selected = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (selected == null) return;
    setState(() {
      if (start) {
        _startTime = _atTime(_date, selected);
      } else {
        _endTime = _atTime(_date, selected);
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_endTime.isAfter(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('End time must be after start time.')),
      );
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.task;
    final task = Task(
      id: existing?.id ?? now.microsecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      date: _date,
      startTime: _startTime,
      endTime: _endTime,
      status: existing?.status ?? TaskStatus.inProgress,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      final controller = ref.read(taskControllerProvider.notifier);
      if (existing == null) {
        await controller.add(task);
      } else {
        await controller.updateTask(task);
      }
      if (mounted) context.pop();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Could not save task: $error')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.task != null;
    return Scaffold(
      body: FigmaBackground(
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
                      child: SafeArea(
                        child: Form(
                          key: _formKey,
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(22, 8, 22, 104),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                SizedBox(
                                  height: 24,
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                        isEditing ? 'Edit Task' : 'Add Task',
                                        style: AppTextStyles.title.copyWith(
                                          fontSize: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                      ),
                                      Positioned(
                                        left: 0,
                                        child: FigmaBackButton(
                                          onPressed: () => context.pop(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 40),
                                const _FieldLabel('Title'),
                                const SizedBox(height: 8),
                                FigmaField(
                                  controller: _titleController,
                                  hintText: 'Task title',
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Enter a title'
                                      : null,
                                ),
                                const SizedBox(height: 18),
                                const _FieldLabel('Description'),
                                const SizedBox(height: 8),
                                FigmaField(
                                  controller: _descriptionController,
                                  hintText: 'Add details (optional)',
                                  height: 92,
                                  minLines: 3,
                                  maxLines: 3,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                ),
                                const SizedBox(height: 32),
                                _DateTimeTile(
                                  label: 'Date',
                                  value: _formatDesignDate(_date),
                                  icon: Icons.calendar_month_rounded,
                                  onTap: _selectDate,
                                ),
                                const SizedBox(height: 24),
                                _DateTimeTile(
                                  label: 'Start Time',
                                  value: MaterialLocalizations.of(context)
                                      .formatTimeOfDay(
                                        TimeOfDay.fromDateTime(_startTime),
                                      ),
                                  icon: Icons.access_time_filled_rounded,
                                  onTap: () => _selectTime(start: true),
                                  iconColor: AppColors.completedText,
                                ),
                                const SizedBox(height: 24),
                                _DateTimeTile(
                                  label: 'End Time',
                                  value: MaterialLocalizations.of(context)
                                      .formatTimeOfDay(
                                        TimeOfDay.fromDateTime(_endTime),
                                      ),
                                  icon: Icons.access_time_filled_rounded,
                                  onTap: () => _selectTime(start: false),
                                  iconColor: AppColors.completedText,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 22,
                      right: 22,
                      bottom: 32,
                      child: FigmaButton(
                        label: isEditing ? 'Save' : 'Add Task',
                        onPressed: _saving ? null : _save,
                        isLoading: _saving,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
  );
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 64,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Icon(icon, size: 27, color: iconColor),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: AppTextStyles.caption.copyWith(fontSize: 11),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: AppTextStyles.body.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isDark)
                  Icon(
                    Icons.arrow_drop_down,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _formatDesignDate(DateTime date) {
  const months = [
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
  ];
  return '${date.day.toString().padLeft(2, '0')} '
      '${months[date.month - 1]}, ${date.year}';
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _atTime(DateTime date, TimeOfDay time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

DateTime _withDate(DateTime time, DateTime date) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
