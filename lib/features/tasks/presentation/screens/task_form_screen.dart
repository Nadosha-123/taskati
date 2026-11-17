import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
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
    final localizations = MaterialLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Task' : 'Add Task'),
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
                children: [
                  _FieldLabel('Title'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(hintText: 'Task title'),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Enter a title'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel('Description'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    minLines: 3,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      hintText: 'Add details (optional)',
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FieldLabel('Date'),
                  const SizedBox(height: 8),
                  _PickerTile(
                    icon: Icons.calendar_month_outlined,
                    label: localizations.formatMediumDate(_date),
                    onTap: _selectDate,
                  ),
                  const SizedBox(height: 14),
                  _TimeTile(
                    label: 'Start Time',
                    time: _startTime,
                    onTap: () => _selectTime(start: true),
                  ),
                  const SizedBox(height: 14),
                  _TimeTile(
                    label: 'End Time',
                    time: _endTime,
                    onTap: () => _selectTime(start: false),
                  ),
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: _saving ? null : _save,
                    child: _saving
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Save' : 'Add Task'),
                  ),
                ],
              ),
            ),
          ),
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
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: AppColors.secondaryText),
  );
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.keyboard_arrow_down),
        onTap: onTap,
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  const _TimeTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final DateTime time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.access_time, color: AppColors.primary),
        title: Text(label, style: Theme.of(context).textTheme.bodySmall),
        subtitle: Text(
          MaterialLocalizations.of(context)
              .formatTimeOfDay(TimeOfDay.fromDateTime(time)),
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        trailing: const Icon(Icons.keyboard_arrow_down),
        onTap: onTap,
      ),
    );
  }
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime _atTime(DateTime date, TimeOfDay time) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);

DateTime _withDate(DateTime time, DateTime date) =>
    DateTime(date.year, date.month, date.day, time.hour, time.minute);
