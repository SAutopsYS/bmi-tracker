import 'package:bmi_tracker/core/constants/bmi_thresholds.dart';
import 'package:bmi_tracker/widgets/dashboard/bmi_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('BMI card renders value, category, and subtitle', (tester) async {
    await pumpTestApp(
      tester,
      child: const Scaffold(
        body: SingleChildScrollView(
          child: BmiCard(
            bmi: 23.51,
            category: BMICategory.normal,
            subtitle: '72 kg · 175 cm',
          ),
        ),
      ),
    );

    expect(find.text('Current BMI'), findsOneWidget);
    expect(find.text('23.5'), findsOneWidget);
    expect(find.text('Normal Weight'), findsOneWidget);
    expect(find.text('72 kg · 175 cm'), findsOneWidget);
  });

  testWidgets('BMI card shows Obese category styling label', (tester) async {
    await pumpTestApp(
      tester,
      child: const Scaffold(
        body: BmiCard(
          bmi: 32.4,
          category: BMICategory.obese,
        ),
      ),
    );

    expect(find.text('32.4'), findsOneWidget);
    expect(find.text('Obese'), findsOneWidget);
  });
}
