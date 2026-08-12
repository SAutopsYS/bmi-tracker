import 'package:flutter_test/flutter_test.dart';

import 'package:bmi_tracker/services/bmi_service.dart';

void main() {
  test('app BMI service smoke check', () {
    const service = BMICalculatorService();
    final bmi = service.calculateBMIFromCm(weightKg: 72, heightCm: 175);
    expect(bmi, closeTo(23.51, 0.01));
  });
}
