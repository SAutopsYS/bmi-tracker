import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/profile_model.dart';
import '../models/weight_history_model.dart';
import 'bmi_service.dart';

/// Seeds demo family profiles: Rahul and Priya Sharma.
///
/// Rahul: 175 cm, 72 kg, BMI ≈ 23.51, exact 7-day history from assignment.
/// Priya: 162 cm, 58 kg, BMI ≈ 22.10, realistic 7-day history.
class DemoSeedService {
  DemoSeedService({
    BMICalculatorService? bmiService,
    Uuid? uuid,
  })  : _bmiService = bmiService ?? const BMICalculatorService(),
        _uuid = uuid ?? const Uuid();

  final BMICalculatorService _bmiService;
  final Uuid _uuid;

  static const String rahulName = 'Rahul Sharma';
  static const String priyaName = 'Priya Sharma';

  static const double rahulHeightCm = 175.0;
  static const double rahulWeightKg = 72.0;

  /// Assignment demo weights (oldest → newest). Last value matches current weight.
  static const List<double> rahulDailyWeightsKg = [
    74.0,
    73.6,
    73.2,
    72.9,
    72.6,
    72.3,
    72.0,
  ];

  static const double priyaHeightCm = 162.0;
  static const double priyaWeightKg = 58.0;

  static const List<double> priyaDailyWeightsKg = [
    58.6,
    58.5,
    58.3,
    58.2,
    58.1,
    58.0,
    58.0,
  ];

  DemoSeedResult buildSeedData(String userId) {
    final now = DateTime.now();
    final rahulId = _uuid.v4();
    final priyaId = _uuid.v4();

    final rahulBmi = _bmiService.calculateBMIFromCm(
      weightKg: rahulWeightKg,
      heightCm: rahulHeightCm,
    );
    final priyaBmi = _bmiService.calculateBMIFromCm(
      weightKg: priyaWeightKg,
      heightCm: priyaHeightCm,
    );

    final rahul = ProfileModel(
      id: rahulId,
      userId: userId,
      name: rahulName,
      gender: Gender.male,
      dateOfBirth: DateTime(1992, 5, 14),
      heightCm: rahulHeightCm,
      weightKg: rahulWeightKg,
      weightUnit: WeightUnit.kg,
      heightUnit: HeightUnit.cm,
      bmi: rahulBmi,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      isPrimary: true,
      syncStatus: SyncStatus.synced,
    );

    final priya = ProfileModel(
      id: priyaId,
      userId: userId,
      name: priyaName,
      gender: Gender.female,
      dateOfBirth: DateTime(1994, 9, 22),
      heightCm: priyaHeightCm,
      weightKg: priyaWeightKg,
      weightUnit: WeightUnit.kg,
      heightUnit: HeightUnit.cm,
      bmi: priyaBmi,
      createdAt: now.subtract(const Duration(days: 28)),
      updatedAt: now,
      isPrimary: false,
      syncStatus: SyncStatus.synced,
    );

    final rahulHistory = _buildHistoryFromWeights(
      userId: userId,
      profileId: rahulId,
      weightsKg: rahulDailyWeightsKg,
      now: now,
    );

    final priyaHistory = _buildHistoryFromWeights(
      userId: userId,
      profileId: priyaId,
      weightsKg: priyaDailyWeightsKg,
      now: now,
    );

    return DemoSeedResult(
      profiles: [rahul, priya],
      history: [...rahulHistory, ...priyaHistory],
    );
  }

  List<WeightHistoryModel> _buildHistoryFromWeights({
    required String userId,
    required String profileId,
    required List<double> weightsKg,
    required DateTime now,
  }) {
    final entries = <WeightHistoryModel>[];
    final days = weightsKg.length;

    for (var i = 0; i < days; i++) {
      final recordedAt = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: days - 1 - i))
          .add(const Duration(hours: 8));

      entries.add(
        WeightHistoryModel(
          id: _uuid.v4(),
          profileId: profileId,
          userId: userId,
          weightKg: weightsKg[i],
          recordedAt: recordedAt,
          note: i == days - 1 ? 'Latest reading' : null,
          syncStatus: SyncStatus.synced,
          createdAt: recordedAt,
        ),
      );
    }
    return entries;
  }
}

class DemoSeedResult {
  const DemoSeedResult({
    required this.profiles,
    required this.history,
  });

  final List<ProfileModel> profiles;
  final List<WeightHistoryModel> history;
}
