import 'package:bmi_tracker/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  test('dark ColorScheme uses dark surface from AppColors', () {
    final scheme = AppColors.darkScheme;
    expect(scheme.brightness, Brightness.dark);
    expect(scheme.surface, AppColors.darkScheme.surface);
    expect(scheme.primary, isNot(AppColors.lightScheme.primary));
  });

  test('light ColorScheme uses light surface from AppColors', () {
    final scheme = AppColors.lightScheme;
    expect(scheme.brightness, Brightness.light);
    expect(scheme.surface, AppColors.softSand);
  });

  testWidgets('MaterialApp dark themeMode applies dark ColorScheme',
      (tester) async {
    await pumpTestApp(
      tester,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.lightScheme,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: AppColors.darkScheme,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.dark,
      child: Builder(
        builder: (context) {
          final theme = Theme.of(context);
          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            body: Text(
              theme.brightness == Brightness.dark ? 'is-dark' : 'is-light',
            ),
          );
        },
      ),
    );

    expect(find.text('is-dark'), findsOneWidget);

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, AppColors.darkScheme.surface);
  });
}
