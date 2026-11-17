import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_provider.dart';

class AppThemeToggle extends ConsumerWidget {
  const AppThemeToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final targetMode = isDark ? ThemeMode.light : ThemeMode.dark;
    final targetLabel = isDark ? 'light' : 'dark';

    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: 'Switch to $targetLabel mode',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints.tightFor(width: 40, height: 40),
        onPressed: () async {
          try {
            await ref.read(themeModeProvider.notifier).setThemeMode(targetMode);
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not change theme: $error')),
              );
            }
          }
        },
        icon: Icon(
          isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
          size: 20,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }
}
