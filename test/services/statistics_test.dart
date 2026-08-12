import 'package:bmi_tracker/models/weight_history_model.dart';
import 'package:bmi_tracker/services/bmi_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = BMICalculatorService();

  group('SevenDayStatistics', () {
    test('aggregates sample week with known expectations', () {
      final asOf = DateTime(2026, 8, 13, 18);
      final history = <WeightHistoryModel>[
        _h('a', 70.0, DateTime(2026, 8, 7, 8)),
        _h('b', 71.0, DateTime(2026, 8, 8, 8)),
        _h('c', 72.0, DateTime(2026, 8, 10, 8)),
        _h('d', 71.5, DateTime(2026, 8, 12, 8)),
        // Outside 7-day window
        _h('old', 80.0, DateTime(2026, 8, 1, 8)),
      ];

      final stats = service.sevenDayStatistics(
        history: history,
        heightCm: 175,
        asOf: asOf,
      );

      expect(stats.entries.map((e) => e.id), ['a', 'b', 'c', 'd']);
      expect(stats.daysWithData, 4);
      expect(stats.minWeightKg, 70.0);
      expect(stats.maxWeightKg, 72.0);
      expect(stats.averageWeightKg, closeTo(71.12, 0.02));
      expect(stats.weightChangeKg, 1.5);

      final startBmi = service.calculateBMIFromCm(weightKg: 70, heightCm: 175);
      final endBmi = service.calculateBMIFromCm(weightKg: 71.5, heightCm: 175);
      expect(stats.bmiChange, closeTo(endBmi - startBmi, 0.01));
      expect(
        stats.averageBmi,
        closeTo(
          [
                startBmi,
                service.calculateBMIFromCm(weightKg: 71, heightCm: 175),
                service.calculateBMIFromCm(weightKg: 72, heightCm: 175),
                endBmi,
              ].reduce((a, b) => a + b) /
              4,
          0.02,
        ),
      );
    });

    test('counts unique calendar days with multiple entries same day', () {
      final asOf = DateTime(2026, 8, 13);
      final history = [
        _h('m1', 72.0, DateTime(2026, 8, 13, 7)),
        _h('m2', 71.8, DateTime(2026, 8, 13, 19)),
        _h('y', 73.0, DateTime(2026, 8, 12, 10)),
      ];

      final stats = service.sevenDayStatistics(
        history: history,
        heightCm: 175,
        asOf: asOf,
      );

      expect(stats.entries.length, 3);
      expect(stats.daysWithData, 2);
      expect(stats.weightChangeKg, closeTo(-1.2, 0.01));
    });

    test('empty constant matches empty window result', () {
      final empty = service.sevenDayStatistics(
        history: const [],
        heightCm: 175,
        asOf: DateTime(2026, 8, 13),
      );
      expect(empty.averageWeightKg, SevenDayStatistics.empty.averageWeightKg);
      expect(empty.daysWithData, SevenDayStatistics.empty.daysWithData);
      expect(empty.entries, isEmpty);
    });
  });
}

WeightHistoryModel _h(String id, double kg, DateTime at) {
  return WeightHistoryModel(
    id: id,
    profileId: 'profile',
    userId: 'user',
    weightKg: kg,
    recordedAt: at,
    createdAt: at,
  );
}
