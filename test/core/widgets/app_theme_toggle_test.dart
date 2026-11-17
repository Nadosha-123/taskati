import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:taskati/core/theme/app_theme.dart';
import 'package:taskati/core/theme/theme_provider.dart';
import 'package:taskati/core/widgets/app_theme_toggle.dart';

void main() {
  testWidgets('toggles theme immediately and persists the new mode', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
        child: Consumer(
          builder: (context, ref, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: ref.watch(themeModeProvider),
            home: const Scaffold(body: AppThemeToggle()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Switch to dark mode'), findsOneWidget);

    await tester.tap(find.byTooltip('Switch to dark mode'));
    await tester.pumpAndSettle();

    expect(find.byTooltip('Switch to light mode'), findsOneWidget);
    expect(
      Theme.of(tester.element(find.byType(AppThemeToggle))).brightness,
      Brightness.dark,
    );
    expect(preferences.getString('theme_mode'), 'dark');
  });
}
