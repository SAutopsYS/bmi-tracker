import 'package:bmi_tracker/core/constants/app_constants.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnitConverter weight KG ↔ LBS', () {
    test('kgToLbs and lbsToKg round-trip', () {
      expect(UnitConverter.kgToLbs(72), closeTo(158.7328, 0.001));
      expect(UnitConverter.lbsToKg(158.73), closeTo(72.0, 0.01));

      final lbs = UnitConverter.kgToLbs(80);
      expect(UnitConverter.lbsToKg(lbs), closeTo(80, 0.0001));
    });

    test('toKg / fromKg honor unit flag', () {
      expect(UnitConverter.toKg(value: 72, isLbs: false), 72);
      expect(UnitConverter.toKg(value: 158.73, isLbs: true), closeTo(72, 0.01));
      expect(UnitConverter.fromKg(kg: 72, toLbs: false), 72);
      expect(
          UnitConverter.fromKg(kg: 72, toLbs: true), closeTo(158.7328, 0.001));
    });

    test('uses precise AppConstants factors', () {
      expect(UnitConverter.lbsToKg(1), AppConstants.lbToKg);
      expect(UnitConverter.kgToLbs(1), AppConstants.kgToLb);
    });
  });

  group('UnitConverter height CM ↔ Inches ↔ meters', () {
    test('cm to meters and back', () {
      expect(UnitConverter.cmToMeters(175), 1.75);
      expect(UnitConverter.metersToCm(1.75), 175);
    });

    test('175 cm ≈ 68.8976 inches', () {
      expect(UnitConverter.cmToInches(175), closeTo(68.8976, 0.0001));
      expect(UnitConverter.inchesToCm(68.8976), closeTo(175, 0.01));
    });

    test('inches to meters', () {
      expect(UnitConverter.inchesToMeters(68.8976), closeTo(1.75, 0.0001));
      expect(
        UnitConverter.metersToInches(1.75),
        closeTo(68.8976, 0.0001),
      );
    });

    test('toMeters / toCm / fromCm honor unit flag', () {
      expect(UnitConverter.toMeters(value: 175, isInches: false), 1.75);
      expect(
        UnitConverter.toMeters(value: 68.8976, isInches: true),
        closeTo(1.75, 0.0001),
      );
      expect(UnitConverter.toCm(value: 175, isInches: false), 175);
      expect(
        UnitConverter.toCm(value: 68.8976, isInches: true),
        closeTo(175, 0.01),
      );
      expect(UnitConverter.fromCm(cm: 175, toInches: false), 175);
      expect(
        UnitConverter.fromCm(cm: 175, toInches: true),
        closeTo(68.8976, 0.0001),
      );
    });
  });
}
