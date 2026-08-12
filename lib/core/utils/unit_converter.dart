import '../constants/app_constants.dart';

/// Precise unit conversions for weight and height.
class UnitConverter {
  UnitConverter._();

  static double kgToLbs(double kg) => kg * AppConstants.kgToLb;

  static double lbsToKg(double lbs) => lbs * AppConstants.lbToKg;

  static double cmToMeters(double cm) => cm * AppConstants.cmToMeter;

  static double metersToCm(double meters) => meters * AppConstants.meterToCm;

  static double inchesToMeters(double inches) =>
      inches * AppConstants.inchToMeter;

  static double metersToInches(double meters) =>
      meters / AppConstants.inchToMeter;

  static double cmToInches(double cm) => cm * AppConstants.cmToInch;

  static double inchesToCm(double inches) => inches * AppConstants.inchToCm;

  /// Converts any weight display value to kilograms.
  static double toKg({required double value, required bool isLbs}) {
    return isLbs ? lbsToKg(value) : value;
  }

  /// Converts kilograms to the requested display unit.
  static double fromKg({required double kg, required bool toLbs}) {
    return toLbs ? kgToLbs(kg) : kg;
  }

  /// Converts any height display value to centimeters.
  static double toCm({required double value, required bool isInches}) {
    return isInches ? inchesToCm(value) : value;
  }

  /// Converts centimeters to the requested display unit.
  static double fromCm({required double cm, required bool toInches}) {
    return toInches ? cmToInches(cm) : cm;
  }

  /// Height in meters from cm or inches.
  static double toMeters({required double value, required bool isInches}) {
    return isInches ? inchesToMeters(value) : cmToMeters(value);
  }
}
