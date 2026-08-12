import 'package:bmi_tracker/services/bmi_service.dart';
import 'package:bmi_tracker/services/demo_seed_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const bmi = BMICalculatorService();
  final seed = DemoSeedService(bmiService: bmi);

  test('Rahul and Priya BMI match calculation service', () {
    final data = seed.buildSeedData('user-demo');
    final rahul =
        data.profiles.firstWhere((p) => p.name == DemoSeedService.rahulName);
    final priya =
        data.profiles.firstWhere((p) => p.name == DemoSeedService.priyaName);

    expect(rahul.heightCm, 175);
    expect(rahul.weightKg, 72);
    expect(rahul.bmi, bmi.calculateBMIFromCm(weightKg: 72, heightCm: 175));
    expect(rahul.bmi, closeTo(23.51, 0.01));

    expect(priya.heightCm, 162);
    expect(priya.weightKg, 58);
    expect(priya.bmi, bmi.calculateBMIFromCm(weightKg: 58, heightCm: 162));
    expect(priya.bmi, closeTo(22.10, 0.02));
  });

  test('Rahul history matches assignment weights exactly', () {
    final data = seed.buildSeedData('user-demo');
    final rahul =
        data.profiles.firstWhere((p) => p.name == DemoSeedService.rahulName);
    final history = data.history.where((e) => e.profileId == rahul.id).toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    expect(
      history.map((e) => e.weightKg).toList(),
      DemoSeedService.rahulDailyWeightsKg,
    );
    expect(history.last.weightKg, DemoSeedService.rahulWeightKg);
  });

  test('historical BMI values use recorded weight and profile height', () {
    final data = seed.buildSeedData('user-demo');
    final rahul =
        data.profiles.firstWhere((p) => p.name == DemoSeedService.rahulName);
    final history = data.history.where((e) => e.profileId == rahul.id);

    for (final entry in history) {
      final expected = bmi.calculateBMIFromCm(
        weightKg: entry.weightKg,
        heightCm: rahul.heightCm,
      );
      expect(
        bmi.calculateBMIFromCm(
          weightKg: entry.weightKg,
          heightCm: DemoSeedService.rahulHeightCm,
        ),
        expected,
      );
    }
  });
}
