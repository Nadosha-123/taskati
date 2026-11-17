import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../tasks/domain/task.dart';

class TaskSwipeCard extends StatefulWidget {
  const TaskSwipeCard({
    required this.task,
    required this.isRevealed,
    required this.onRevealChanged,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onComplete,
    super.key,
  });

  final Task task;
  final bool isRevealed;
  final ValueChanged<bool> onRevealChanged;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;
  final Future<void> Function() onComplete;

  @override
  State<TaskSwipeCard> createState() => _TaskSwipeCardState();
}

class _TaskSwipeCardState extends State<TaskSwipeCard>
    with SingleTickerProviderStateMixin {
  static const _completeRevealExtent = 164.0;
  static const _deleteRevealExtent = 108.0;
  static const _revealThreshold = 58.0;
  static const _actionPreviewThreshold = 4.0;
  static const _flingRevealVelocity = 950.0;
  static const _directCompleteDragThreshold = 150.0;
  static const _directCompleteFlingVelocity = 1400.0;
  static const _minimumFlingTravel = 56.0;

  late final AnimationController _dragController;
  bool _actionInProgress = false;
  bool _pressed = false;
  double _dragStartOffset = 0;
  double _dragDistance = 0;

  double get _dragOffset => _dragController.value;

  @override
  void initState() {
    super.initState();
    _dragController = AnimationController(
      vsync: this,
      lowerBound: -_deleteRevealExtent,
      upperBound: _completeRevealExtent,
      value: 0,
    );
  }

  @override
  void didUpdateWidget(covariant TaskSwipeCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRevealed && !widget.isRevealed) {
      _springTo(0, 0);
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (_actionInProgress) return;
    _dragController.stop();
    _dragStartOffset = _dragOffset;
    _dragDistance = 0;
    setState(() => _pressed = false);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (_actionInProgress) return;
    _dragDistance += details.delta.dx;
    _dragController.value = (_dragOffset + details.delta.dx)
        .clamp(-_deleteRevealExtent, _completeRevealExtent)
        .toDouble();
  }

  Future<void> _onDragEnd(DragEndDetails details) async {
    if (_actionInProgress) return;
    final velocity = details.primaryVelocity ?? 0;
    final beganClosed = _dragStartOffset.abs() < _revealThreshold;
    final strongRightSwipe =
        beganClosed &&
        widget.task.status != TaskStatus.completed &&
        (_dragOffset >= _directCompleteDragThreshold ||
            (velocity >= _directCompleteFlingVelocity &&
                _dragDistance >= _minimumFlingTravel));

    if (strongRightSwipe) {
      await _runAction(widget.onComplete);
      return;
    }

    final startedRevealed = _dragStartOffset.abs() >= _revealThreshold;
    final draggedTowardCenter =
        (_dragStartOffset > 0 && _dragDistance < 0) ||
        (_dragStartOffset < 0 && _dragDistance > 0);
    if (startedRevealed && draggedTowardCenter) {
      _close();
      return;
    }

    final revealCompleteAndEdit =
        _dragOffset >= _revealThreshold ||
        (velocity >= _flingRevealVelocity && _dragOffset >= 40);
    final revealDelete =
        _dragOffset <= -_revealThreshold ||
        (velocity <= -_flingRevealVelocity && _dragOffset <= -40);

    if (revealCompleteAndEdit) {
      widget.onRevealChanged(true);
      _springTo(_completeRevealExtent, velocity);
    } else if (revealDelete) {
      widget.onRevealChanged(true);
      _springTo(-_deleteRevealExtent, velocity);
    } else {
      _close(velocity: velocity);
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    if (_actionInProgress) return;
    setState(() => _actionInProgress = true);
    widget.onRevealChanged(false);
    try {
      await action();
    } finally {
      if (mounted) {
        setState(() => _actionInProgress = false);
        _springTo(0, 0);
      }
    }
  }

  void _edit() {
    if (_actionInProgress) return;
    widget.onRevealChanged(false);
    _springTo(0, 0);
    widget.onEdit();
  }

  void _close({double velocity = 0}) {
    widget.onRevealChanged(false);
    _springTo(0, velocity);
  }

  void _springTo(double target, double velocity) {
    _dragController.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 360, damping: 32),
        _dragOffset,
        target,
        velocity,
      ),
    );
  }

  @override
  void dispose() {
    _dragController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.task;
    final isCompleted = task.status == TaskStatus.completed;
    return TapRegion(
      onTapOutside: (_) {
        if (widget.isRevealed || _dragOffset != 0) _close();
      },
      child: Container(
        height: 94,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(15)),
          boxShadow: [AppColors.cardShadow],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedBuilder(
              animation: _dragController,
              builder: (context, _) {
                final offset = _dragOffset;
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    if (offset > _actionPreviewThreshold)
                      _completeAndEditActions(offset),
                    if (offset < -_actionPreviewThreshold)
                      _deleteAction(offset),
                    Transform.translate(
                      offset: Offset(offset, 0),
                      child: AnimatedScale(
                        scale: _pressed ? 0.99 : 1,
                        duration: const Duration(milliseconds: 110),
                        child: Material(
                          color: Theme.of(context).colorScheme.surface,
                          child: InkWell(
                            onTap: widget.onTap,
                            onTapDown: (_) => setState(() => _pressed = true),
                            onTapUp: (_) => setState(() => _pressed = false),
                            onTapCancel: () => setState(() => _pressed = false),
                            child: _TaskCardContent(
                              task: task,
                              isCompleted: isCompleted,
                              onComplete: widget.onComplete,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _completeAndEditActions(double offset) {
    final progress = (offset / _completeRevealExtent).clamp(0.0, 1.0);
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: SizedBox(
        width: _completeRevealExtent,
        child: Transform.scale(
          alignment: AlignmentDirectional.centerStart,
          scaleX: 0.94 + progress * 0.06,
          child: Opacity(
            opacity: progress,
            child: Row(
              children: [
                Expanded(
                  child: _SwipeAction(
                    icon: widget.task.status == TaskStatus.completed
                        ? Icons.replay_rounded
                        : Icons.check_circle_outline,
                    label: widget.task.status == TaskStatus.completed
                        ? 'Reopen'
                        : 'Complete',
                    color: AppColors.complete,
                    enabled: !_actionInProgress,
                    onTap: () => _runAction(widget.onComplete),
                  ),
                ),
                Expanded(
                  child: _SwipeAction(
                    icon: Icons.edit_outlined,
                    label: 'Edit',
                    color: AppColors.secondaryText,
                    enabled: !_actionInProgress,
                    onTap: _edit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _deleteAction(double offset) {
    final progress = (offset.abs() / _deleteRevealExtent).clamp(0.0, 1.0);
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: SizedBox(
        width: _deleteRevealExtent,
        child: Transform.scale(
          alignment: AlignmentDirectional.centerEnd,
          scaleX: 0.94 + progress * 0.06,
          child: Opacity(
            opacity: progress,
            child: _SwipeAction(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: AppColors.delete,
              enabled: !_actionInProgress,
              onTap: () => _runAction(widget.onDelete),
            ),
          ),
        ),
      ),
    );
  }
}

class _SwipeAction extends StatefulWidget {
  const _SwipeAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_SwipeAction> createState() => _SwipeActionState();
}

class _SwipeActionState extends State<_SwipeAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: widget.color,
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        onTapDown: widget.enabled
            ? (_) => setState(() => _pressed = true)
            : null,
        onTapUp: widget.enabled
            ? (_) => setState(() => _pressed = false)
            : null,
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.96 : 1,
          duration: const Duration(milliseconds: 100),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(widget.icon, color: Colors.white, size: 24),
                const SizedBox(height: 4),
                Text(
                  widget.label,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
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

class _TaskCardContent extends StatelessWidget {
  const _TaskCardContent({
    required this.task,
    required this.isCompleted,
    required this.onComplete,
  });

  final Task task;
  final bool isCompleted;
  final Future<void> Function() onComplete;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 94,
      padding: const EdgeInsets.fromLTRB(14, 7, 12, 7),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 1,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 3),
          Expanded(
            child: Text(
              task.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.secondaryText,
                fontSize: 12,
                height: 1.15,
              ),
            ),
          ),
          Row(
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 16,
                color: AppColors.completedText,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '${_time(context, task.startTime)} - '
                  '${_time(context, task.endTime)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.completedText,
                    fontSize: 11,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: onComplete,
                child: Container(
                  constraints: const BoxConstraints(minWidth: 35),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.lightAccent
                        : AppColors.inProgressBackground,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isCompleted ? 'Done' : 'In Progress',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isCompleted
                          ? AppColors.primary
                          : AppColors.inProgressText,
                      fontSize: 9,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _time(BuildContext context, DateTime value) =>
      MaterialLocalizations.of(context)
          .formatTimeOfDay(TimeOfDay.fromDateTime(value));
}
