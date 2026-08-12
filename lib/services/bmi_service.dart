import '../core/constants/bmi_thresholds.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/unit_converter.dart';
import '../models/enums.dart';
import '../models/weight_history_model.dart';

/// Result of seven-day weight/BMI statistics.
class SevenDayStatistics {
  const SevenDayStatistics({
    required this.averageWeightKg,
    required this.minWeightKg,
    required this.maxWeightKg,
    required this.averageBmi,
    required this.weightChangeKg,
    required this.bmiChange,
    required this.entries,
    required this.daysWithData,
    this.startingWeightKg = 0,
    this.currentWeightKg = 0,
    this.startingBmi = 0,
    this.currentBmi = 0,
  });

  final double averageWeightKg;
  final double minWeightKg;
  final double maxWeightKg;
  final double averageBmi;
  final double weightChangeKg;
  final double bmiChange;
  final List<WeightHistoryModel> entries;
  final int daysWithData;
  final double startingWeightKg;
  final double currentWeightKg;
  final double startingBmi;
  final double currentBmi;

  /// Honest incomplete-history label, e.g. "3 of 7 days available".
  String get coverageLabel => '$daysWithData of 7 days available';

  static const empty = SevenDayStatistics(
    averageWeightKg: 0,
    minWeightKg: 0,
    maxWeightKg: 0,
    averageBmi: 0,
    weightChangeKg: 0,
    bmiChange: 0,
    entries: [],
    daysWithData: 0,
  );
}

/// BMI calculation and health metric helpers.
class BMICalculatorService {
  const BMICalculatorService({
    this.thresholds = BmiThresholds.adult,
  });

  final BmiThresholds thresholds;

  /// BMI = weight(kg) / height(m)^2. Example: 72kg / 1.75^2 ≈ 23.51.
  double calculateBMI({
    required double weightKg,
    required double heightMeters,
  }) {
    if (weightKg <= 0 || heightMeters <= 0) return 0;
    final bmi = weightKg / (heightMeters * heightMeters);
    return double.parse(bmi.toStringAsFixed(2));
  }

  double calculateBMIFromCm({
    required double weightKg,
    required double heightCm,
  }) {
    return calculateBMI(
      weightKg: weightKg,
      heightMeters: UnitConverter.cmToMeters(heightCm),
    );
  }

  BMICategory getBMICategory(double bmi) => thresholds.categoryFor(bmi);

  double convertWeightToKg(double value, WeightUnit unit) {
    return UnitConverter.toKg(value: value, isLbs: unit.isLbs);
  }

  double convertHeightToMeters(double value, HeightUnit unit) {
    return UnitConverter.toMeters(value: value, isInches: unit.isInches);
  }

  /// Positive means BMI increased.
  double calculateBMIChange({
    required double previousBmi,
    required double currentBmi,
  }) {
    return double.parse((currentBmi - previousBmi).toStringAsFixed(2));
  }

  /// Positive means weight increased (kg).
  double calculateWeightChange({
    required double previousWeightKg,
    required double currentWeightKg,
  }) {
    return double.parse(
      (currentWeightKg - previousWeightKg).toStringAsFixed(2),
    );
  }

  SevenDayStatistics sevenDayStatistics({
    required List<WeightHistoryModel> history,
    required double heightCm,
    DateTime? asOf,
  }) {
    final days = AppDateUtils.lastNDays(7, asOf);
    final start = days.first;
    final end = AppDateUtils.endOfDay(days.last);

    final inWindow = history
        .where(
          (e) => !e.recordedAt.isBefore(start) && !e.recordedAt.isAfter(end),
        )
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    if (inWindow.isEmpty) return SevenDayStatistics.empty;

    final weights = inWindow.map((e) => e.weightKg).toList();
    final sum = weights.fold<double>(0, (a, b) => a + b);
    final avgWeight = sum / weights.length;
    final minW = weights.reduce((a, b) => a < b ? a : b);
    final maxW = weights.reduce((a, b) => a > b ? a : b);

    final bmis = inWindow
        .map(
          (e) => calculateBMIFromCm(weightKg: e.weightKg, heightCm: heightCm),
        )
        .toList();
    final avgBmi = bmis.fold<double>(0, (a, b) => a + b) / bmis.length;

    final weightChange = calculateWeightChange(
      previousWeightKg: inWindow.first.weightKg,
      currentWeightKg: inWindow.last.weightKg,
    );
    final bmiChange = calculateBMIChange(
      previousBmi: bmis.first,
      currentBmi: bmis.last,
    );

    final uniqueDays = inWindow
        .map((e) => AppDateUtils.startOfDay(e.recordedAt))
        .toSet()
        .length;

    return SevenDayStatistics(
      averageWeightKg: double.parse(avgWeight.toStringAsFixed(2)),
      minWeightKg: double.parse(minW.toStringAsFixed(2)),
      maxWeightKg: double.parse(maxW.toStringAsFixed(2)),
      averageBmi: double.parse(avgBmi.toStringAsFixed(2)),
      weightChangeKg: weightChange,
      bmiChange: bmiChange,
      entries: inWindow,
      daysWithData: uniqueDays,
      startingWeightKg:
          double.parse(inWindow.first.weightKg.toStringAsFixed(2)),
      currentWeightKg: double.parse(inWindow.last.weightKg.toStringAsFixed(2)),
      startingBmi: bmis.first,
      currentBmi: bmis.last,
    );
  }
}
