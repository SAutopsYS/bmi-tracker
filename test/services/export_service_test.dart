import 'package:bmi_tracker/models/enums.dart';
import 'package:bmi_tracker/models/profile_model.dart';
import 'package:bmi_tracker/models/weight_history_model.dart';
import 'package:bmi_tracker/services/export_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final export = ExportService();

  test('export filename uses profile name and date', () {
    final profile = ProfileModel(
      id: 'p1',
      userId: 'u1',
      name: 'Rahul Sharma',
      gender: Gender.male,
      dateOfBirth: DateTime(1992, 5, 14),
      heightCm: 175,
      weightKg: 72,
      weightUnit: WeightUnit.kg,
      heightUnit: HeightUnit.cm,
      bmi: 23.51,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 8, 13),
    );

    expect(
      export.buildFileName(profile, asOf: DateTime(2026, 8, 13)),
      'rahul_sharma_health_history_2026-08-13.csv',
    );
  });

  test('csv includes normalized columns for selected profile only', () async {
    final profile = ProfileModel(
      id: 'p1',
      userId: 'u1',
      name: 'Rahul Sharma',
      gender: Gender.male,
      dateOfBirth: DateTime(1992, 5, 14),
      heightCm: 175,
      weightKg: 72,
      weightUnit: WeightUnit.kg,
      heightUnit: HeightUnit.cm,
      bmi: 23.51,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 8, 13),
    );
    final history = [
      WeightHistoryModel(
        id: 'h1',
        profileId: 'p1',
        userId: 'u1',
        weightKg: 72,
        recordedAt: DateTime(2026, 8, 13, 8),
        createdAt: DateTime(2026, 8, 13, 8),
      ),
    ];

    final csv = await export.generateCsv(profile: profile, history: history);
    expect(csv, contains('Normalized Weight KG'));
    expect(csv, contains('Normalized Height CM'));
    expect(csv, contains('BMI Category'));
    expect(csv, contains('Rahul Sharma'));
    expect(csv, contains('72.00'));
    expect(csv, contains('175.00'));
  });
}
