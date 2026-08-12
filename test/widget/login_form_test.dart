import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/screens/auth/login/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

Future<void> _tapSignIn(WidgetTester tester) async {
  final signIn = find.text(AppStrings.signIn);
  await tester.ensureVisible(signIn);
  await tester.pumpAndSettle();
  await tester.tap(signIn);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('login form shows validation messages for empty fields',
      (tester) async {
    await pumpTestApp(tester, child: const LoginScreen());

    expect(find.text(AppStrings.loginTitle), findsOneWidget);
    expect(find.text(AppStrings.signIn), findsOneWidget);

    await _tapSignIn(tester);

    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter a password.'), findsOneWidget);
  });

  testWidgets('login form shows email format error', (tester) async {
    await pumpTestApp(tester, child: const LoginScreen());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'not-valid');
    await tester.enterText(fields.at(1), 'short');
    await _tapSignIn(tester);

    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(
      find.textContaining('Password must be at least'),
      findsOneWidget,
    );
  });
}
