import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal test host: Riverpod + MaterialApp, no Firebase/Hive.
Widget buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode themeMode = ThemeMode.light,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: theme ?? ThemeData(useMaterial3: true),
      darkTheme: darkTheme,
      themeMode: themeMode,
      home: child,
    ),
  );
}

Future<void> pumpTestApp(
  WidgetTester tester, {
  required Widget child,
  List<Override> overrides = const [],
  ThemeData? theme,
  ThemeData? darkTheme,
  ThemeMode themeMode = ThemeMode.light,
}) async {
  await tester.pumpWidget(
    buildTestApp(
      child: child,
      overrides: overrides,
      theme: theme,
      darkTheme: darkTheme,
      themeMode: themeMode,
    ),
  );
  await tester.pump();
}
