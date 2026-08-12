import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';

import '../core/errors/app_exception.dart';
import '../core/utils/date_utils.dart';
import '../core/utils/unit_converter.dart';
import '../models/profile_model.dart';
import '../models/weight_history_model.dart';
import 'bmi_service.dart';

/// CSV generation and sharing for health data export.
///
/// Uses [XFile.fromData] so Web can download without `dart:io`.
class ExportService {
  ExportService({BMICalculatorService? bmiService})
      : _bmiService = bmiService ?? const BMICalculatorService();

  final BMICalculatorService _bmiService;

  String buildFileName(ProfileModel profile, {DateTime? asOf}) {
    final date = AppDateUtils.formatIsoDate(asOf ?? DateTime.now());
    final safeName = profile.name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^\w\-]+'), '');
    final base = safeName.isEmpty ? 'profile' : safeName;
    return '${base}_health_history_$date.csv';
  }

  Future<String> generateCsv({
    required ProfileModel profile,
    required List<WeightHistoryModel> history,
  }) async {
    final rows = <List<dynamic>>[
      [
        'Date',
        'Weight',
        'Weight Unit',
        'Normalized Weight KG',
        'Height',
        'Height Unit',
        'Normalized Height CM',
        'BMI',
        'BMI Category',
        'Note',
        'Profile',
      ],
    ];

    final sorted = [...history]
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    for (final entry in sorted) {
      final bmi = _bmiService.calculateBMIFromCm(
        weightKg: entry.weightKg,
        heightCm: profile.heightCm,
      );
      final category = _bmiService.getBMICategory(bmi);
      final rowWeight = UnitConverter.fromKg(
        kg: entry.weightKg,
        toLbs: profile.weightUnit.isLbs,
      );
      final rowHeight = UnitConverter.fromCm(
        cm: profile.heightCm,
        toInches: profile.heightUnit.isInches,
      );

      rows.add([
        AppDateUtils.formatIsoDate(entry.recordedAt),
        rowWeight.toStringAsFixed(2),
        profile.weightUnit.label,
        entry.weightKg.toStringAsFixed(2),
        rowHeight.toStringAsFixed(2),
        profile.heightUnit.label,
        profile.heightCm.toStringAsFixed(2),
        bmi.toStringAsFixed(2),
        category.label,
        entry.note ?? '',
        profile.name,
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  Future<void> shareCsv({
    required ProfileModel profile,
    required List<WeightHistoryModel> history,
  }) async {
    if (history.isEmpty) {
      throw const ValidationException('Nothing to export yet.');
    }

    final csv = await generateCsv(profile: profile, history: history);
    final fileName = buildFileName(profile);
    final bytes = utf8.encode(csv);

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          mimeType: 'text/csv',
          name: fileName,
        ),
      ],
      subject: 'BMI Tracker export: ${profile.name}',
      text: 'Health history export for ${profile.name} only.',
      fileNameOverrides: [fileName],
    );
  }
}
