/// Configurable adult BMI category thresholds and labels.
enum BMICategory {
  underweight('Underweight'),
  normal('Normal Weight'),
  overweight('Overweight'),
  obese('Obese');

  const BMICategory(this.label);
  final String label;
}

/// Adult BMI thresholds (WHO-aligned defaults, overridable for testing).
class BmiThresholds {
  const BmiThresholds({
    this.underweightMax = 18.5,
    this.normalMax = 25.0,
    this.overweightMax = 30.0,
  });

  /// BMI below this value is underweight.
  final double underweightMax;

  /// BMI below this value (and >= underweightMax) is normal.
  final double normalMax;

  /// BMI below this value (and >= normalMax) is overweight.
  /// Values >= overweightMax are obese.
  final double overweightMax;

  static const BmiThresholds adult = BmiThresholds();

  BMICategory categoryFor(double bmi) {
    if (bmi < underweightMax) return BMICategory.underweight;
    if (bmi < normalMax) return BMICategory.normal;
    if (bmi < overweightMax) return BMICategory.overweight;
    return BMICategory.obese;
  }
}
