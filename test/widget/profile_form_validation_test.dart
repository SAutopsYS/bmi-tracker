import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/screens/profiles/profile_form_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('profile form shows validation for empty name/weight/height',
      (tester) async {
    await pumpTestApp(tester, child: const ProfileFormScreen());

    expect(find.text(AppStrings.addProfile), findsOneWidget);

    await tester.ensureVisible(find.text(AppStrings.saveProfile));
    await tester.tap(find.text(AppStrings.saveProfile));
    await tester.pumpAndSettle();

    expect(find.text('Please enter a name.'), findsOneWidget);
    expect(find.text('Please enter a weight.'), findsOneWidget);
    expect(find.text('Please enter a height.'), findsOneWidget);
  });

  testWidgets('profile form rejects zero height', (tester) async {
    await pumpTestApp(tester, child: const ProfileFormScreen());

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Priya');
    await tester.enterText(fields.at(1), '58');
    await tester.enterText(fields.at(2), '0');

    await tester.ensureVisible(find.text(AppStrings.saveProfile));
    await tester.tap(find.text(AppStrings.saveProfile));
    await tester.pumpAndSettle();

    expect(find.textContaining('Height should be between'), findsOneWidget);
  });
}
