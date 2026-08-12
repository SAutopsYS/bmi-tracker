import 'package:bmi_tracker/core/constants/bmi_thresholds.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:bmi_tracker/core/validators/input_validators.dart';
import 'package:bmi_tracker/models/enums.dart';
import 'package:bmi_tracker/models/weight_history_model.dart';
import 'package:bmi_tracker/services/bmi_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BMICalculatorService();

  group('BMICalculatorService.calculateBMI', () {
    test('72 kg + 175 cm ≈ 23.51 BMI', () {
      final bmi = service.calculateBMIFromCm(weightKg: 72, heightCm: 175);
      expect(bmi, closeTo(23.51, 0.01));
      expect(bmi, 23.51);
    });

    test('returns 0 for zero or negative height/weight', () {
      expect(
        service.calculateBMI(weightKg: 72, heightMeters: 0),
        0,
      );
      expect(
        service.calculateBMI(weightKg: 72, heightMeters: -1.75),
        0,
      );
      expect(
        service.calculateBMI(weightKg: 0, heightMeters: 1.75),
        0,
      );
      expect(
        service.calculateBMI(weightKg: -70, heightMeters: 1.75),
        0,
      );
    });
  });

  group('unit helpers via service', () {
    test('158.73 lbs ≈ 72 kg', () {
      final kg = service.convertWeightToKg(158.73, WeightUnit.lbs);
      expect(kg, closeTo(72.0, 0.01));
    });

    test('175 cm ≈ 68.8976 inches', () {
      final inches = UnitConverter.cmToInches(175);
      expect(inches, closeTo(68.8976, 0.0001));
    });
  });

  group('BMI categories', () {
    test('underweight / normal / overweight / obese', () {
      expect(service.getBMICategory(17.0), BMICategory.underweight);
      expect(service.getBMICategory(18.49), BMICategory.underweight);
      expect(service.getBMICategory(18.5), BMICategory.normal);
      expect(service.getBMICategory(23.51), BMICategory.normal);
      expect(service.getBMICategory(24.99), BMICategory.normal);
      expect(service.getBMICategory(25.0), BMICategory.overweight);
      expect(service.getBMICategory(29.99), BMICategory.overweight);
      expect(service.getBMICategory(30.0), BMICategory.obese);
      expect(service.getBMICategory(35.0), BMICategory.obese);
    });
  });

  group('change helpers', () {
    test('weight change and BMI change', () {
      expect(
        service.calculateWeightChange(
          previousWeightKg: 74,
          currentWeightKg: 72,
        ),
        -2.0,
      );
      expect(
        service.calculateBMIChange(previousBmi: 24.16, currentBmi: 23.51),
        -0.65,
      );
      expect(
        service.calculateBMIChange(previousBmi: 22.0, currentBmi: 23.5),
        1.5,
      );
    });
  });

  group('seven day statistics', () {
    test('computes averages, min/max, and changes from sample data', () {
      final asOf = DateTime(2026, 8, 13);
      final history = [
        _entry('1', 74.0, DateTime(2026, 8, 7, 9)),
        _entry('2', 73.5, DateTime(2026, 8, 9, 9)),
        _entry('3', 72.0, DateTime(2026, 8, 13, 9)),
      ];

      final stats = service.sevenDayStatistics(
        history: history,
        heightCm: 175,
        asOf: asOf,
      );

      expect(stats.daysWithData, 3);
      expect(stats.entries.length, 3);
      expect(stats.minWeightKg, 72.0);
      expect(stats.maxWeightKg, 74.0);
      expect(stats.averageWeightKg, closeTo(73.17, 0.01));
      expect(stats.weightChangeKg, -2.0);

      final firstBmi = service.calculateBMIFromCm(weightKg: 74, heightCm: 175);
      final lastBmi = service.calculateBMIFromCm(weightKg: 72, heightCm: 175);
      expect(stats.bmiChange, closeTo(lastBmi - firstBmi, 0.01));
      expect(stats.averageBmi, greaterThan(0));
    });

    test('returns empty when no entries in window', () {
      final stats = service.sevenDayStatistics(
        history: [_entry('x', 70, DateTime(2020, 1, 1))],
        heightCm: 175,
        asOf: DateTime(2026, 8, 13),
      );
      expect(stats.daysWithData, 0);
      expect(stats.entries, isEmpty);
    });
  });

  group('zero/negative height never accepted', () {
    test('validators reject zero and negative height', () {
      expect(InputValidators.height('0', isInches: false), isNotNull);
      expect(InputValidators.height('-10', isInches: false), isNotNull);
      expect(InputValidators.height('0', isInches: true), isNotNull);
      expect(InputValidators.height('-5', isInches: true), isNotNull);
    });

    test('service never produces positive BMI for invalid height', () {
      expect(service.calculateBMIFromCm(weightKg: 72, heightCm: 0), 0);
      expect(service.calculateBMIFromCm(weightKg: 72, heightCm: -175), 0);
    });
  });
}

WeightHistoryModel _entry(String id, double kg, DateTime at) {
  return WeightHistoryModel(
    id: id,
    profileId: 'p1',
    userId: 'u1',
    weightKg: kg,
    recordedAt: at,
    createdAt: at,
  );
}
