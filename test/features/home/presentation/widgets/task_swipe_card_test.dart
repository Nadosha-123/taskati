import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:taskati/features/home/presentation/widgets/task_swipe_card.dart';
import 'package:taskati/features/tasks/domain/task.dart';

void main() {
  final task = _task('task-1');

  testWidgets('left swipe reveals Delete and only its tap requests deletion', (
    tester,
  ) async {
    var deleteCount = 0;
    await _showCard(
      tester,
      task: task,
      onTap: () {},
      onEdit: () {},
      onDelete: () async {
        deleteCount++;
      },
      onComplete: () async {},
    );

    await tester.drag(find.byType(TaskSwipeCard), const Offset(-110, 0));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsOneWidget);
    expect(deleteCount, 0);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(deleteCount, 1);
  });

  testWidgets(
    'right swipe reveals Complete and Edit without activating either',
    (tester) async {
      var completionCount = 0;
      var editCount = 0;
      await _showCard(
        tester,
        task: task,
        onTap: () {},
        onEdit: () => editCount++,
        onDelete: () async {},
        onComplete: () async {
          completionCount++;
        },
      );

      await tester.drag(find.byType(TaskSwipeCard), const Offset(110, 0));
      await tester.pumpAndSettle();

      expect(find.text('Complete'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(completionCount, 0);
      expect(editCount, 0);

      await tester.tap(find.text('Edit'));
      await tester.pumpAndSettle();

      expect(editCount, 1);
      expect(completionCount, 0);
    },
  );

  testWidgets('strong right swipe directly completes the task', (tester) async {
    var completionCount = 0;
    await _showCard(
      tester,
      task: task,
      onTap: () {},
      onEdit: () {},
      onDelete: () async {},
      onComplete: () async {
        completionCount++;
      },
    );

    await tester.drag(find.byType(TaskSwipeCard), const Offset(170, 0));
    await tester.pumpAndSettle();

    expect(completionCount, 1);
    expect(find.text('Complete'), findsNothing);
  });

  testWidgets('swiping back or tapping outside closes revealed actions', (
    tester,
  ) async {
    await _showCard(
      tester,
      task: task,
      onTap: () {},
      onEdit: () {},
      onDelete: () async {},
      onComplete: () async {},
    );

    await tester.drag(find.byType(TaskSwipeCard), const Offset(-110, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);

    await tester.drag(find.byType(TaskSwipeCard), const Offset(60, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsNothing);

    await tester.drag(find.byType(TaskSwipeCard), const Offset(-110, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);

    await tester.tapAt(const Offset(20, 20));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsNothing);
  });

  testWidgets('only the most recently swiped card remains revealed', (
    tester,
  ) async {
    String? openTaskId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _coordinatedCard(
                    task: task,
                    isRevealed: openTaskId == task.id,
                    onRevealChanged: (revealed) {
                      setState(() {
                        if (revealed) {
                          openTaskId = task.id;
                        } else if (openTaskId == task.id) {
                          openTaskId = null;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  _coordinatedCard(
                    key: const ValueKey('task-2-card'),
                    task: _task('task-2'),
                    isRevealed: openTaskId == 'task-2',
                    onRevealChanged: (revealed) {
                      setState(() {
                        if (revealed) {
                          openTaskId = 'task-2';
                        } else if (openTaskId == 'task-2') {
                          openTaskId = null;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.byType(TaskSwipeCard).first, const Offset(-110, 0));
    await tester.pumpAndSettle();
    expect(find.text('Delete'), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('task-2-card')),
      const Offset(110, 0),
    );
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsNothing);
    expect(find.text('Complete'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
  });

  testWidgets('small drags do not activate actions and body taps still edit', (
    tester,
  ) async {
    var deleteCount = 0;
    var completionCount = 0;
    var tapCount = 0;
    await _showCard(
      tester,
      task: task,
      onTap: () => tapCount++,
      onEdit: () {},
      onDelete: () async {
        deleteCount++;
      },
      onComplete: () async {
        completionCount++;
      },
    );

    await tester.drag(find.byType(TaskSwipeCard), const Offset(-30, 0));
    await tester.pumpAndSettle();
    expect(deleteCount, 0);
    expect(completionCount, 0);

    await tester.tap(find.text('Review project'));
    await tester.pump();

    expect(tapCount, 1);
  });

  testWidgets('vertical drags do not reveal or activate task actions', (
    tester,
  ) async {
    var deleteCount = 0;
    var completionCount = 0;
    await _showCard(
      tester,
      task: task,
      onTap: () {},
      onEdit: () {},
      onDelete: () async {
        deleteCount++;
      },
      onComplete: () async {
        completionCount++;
      },
    );

    await tester.drag(find.byType(TaskSwipeCard), const Offset(0, 120));
    await tester.pumpAndSettle();

    expect(find.text('Delete'), findsNothing);
    expect(find.text('Complete'), findsNothing);
    expect(deleteCount, 0);
    expect(completionCount, 0);
  });
}

Task _task(String id) => Task(
  id: id,
  title: 'Review project',
  description: 'Check the latest changes',
  date: DateTime(2026, 6, 17),
  startTime: DateTime(2026, 6, 17, 9),
  endTime: DateTime(2026, 6, 17, 10),
  status: TaskStatus.inProgress,
  createdAt: DateTime(2026, 6, 16),
  updatedAt: DateTime(2026, 6, 16),
);

Future<void> _showCard(
  WidgetTester tester, {
  required Task task,
  required VoidCallback onTap,
  required VoidCallback onEdit,
  required Future<void> Function() onDelete,
  required Future<void> Function() onComplete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.only(top: 40),
          child: Center(
            child: SizedBox(
              width: 335,
              child: TaskSwipeCard(
                task: task,
                isRevealed: false,
                onRevealChanged: (_) {},
                onTap: onTap,
                onEdit: onEdit,
                onDelete: onDelete,
                onComplete: onComplete,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _coordinatedCard({
  Key? key,
  required Task task,
  required bool isRevealed,
  required ValueChanged<bool> onRevealChanged,
}) {
  return SizedBox(
    width: 335,
    child: TaskSwipeCard(
      key: key,
      task: task,
      isRevealed: isRevealed,
      onRevealChanged: onRevealChanged,
      onTap: () {},
      onEdit: () {},
      onDelete: () async {},
      onComplete: () async {},
    ),
  );
}
