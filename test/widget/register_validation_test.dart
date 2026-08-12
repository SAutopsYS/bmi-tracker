import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/screens/auth/register/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('register form shows validation for empty required fields',
      (tester) async {
    await pumpTestApp(tester, child: const RegisterScreen());

    expect(find.text(AppStrings.registerTitle), findsOneWidget);

    await tester.tap(find.text(AppStrings.signUp));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name.'), findsOneWidget);
    expect(find.text('Please enter your email.'), findsOneWidget);
    expect(find.text('Please enter a password.'), findsOneWidget);
    expect(find.text('Please confirm your password.'), findsOneWidget);
  });

  testWidgets('register form shows confirm password mismatch', (tester) async {
    await pumpTestApp(tester, child: const RegisterScreen());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Rahul Sharma');
    await tester.enterText(fields.at(1), 'rahul@example.com');
    await tester.enterText(fields.at(2), 'password123');
    await tester.enterText(fields.at(3), 'password999');

    await tester.ensureVisible(find.text(AppStrings.signUp));
    await tester.tap(find.text(AppStrings.signUp));
    await tester.pumpAndSettle();

    expect(find.text('Passwords do not match.'), findsOneWidget);
  });
}
