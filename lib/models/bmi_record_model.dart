import 'package:equatable/equatable.dart';

import '../core/constants/bmi_thresholds.dart';

/// Snapshot of BMI at a point in time (derived from weight + height).
class BmiRecordModel extends Equatable {
  const BmiRecordModel({
    required this.id,
    required this.profileId,
    required this.weightKg,
    required this.heightCm,
    required this.bmi,
    required this.category,
    required this.recordedAt,
  });

  final String id;
  final String profileId;
  final double weightKg;
  final double heightCm;
  final double bmi;
  final BMICategory category;
  final DateTime recordedAt;

  factory BmiRecordModel.fromJson(Map<String, dynamic> json) {
    final categoryName = json['category'] as String?;
    return BmiRecordModel(
      id: json['id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0,
      category: BMICategory.values.firstWhere(
        (e) => e.name == categoryName,
        orElse: () => BMICategory.normal,
      ),
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'weightKg': weightKg,
        'heightCm': heightCm,
        'bmi': bmi,
        'category': category.name,
        'recordedAt': recordedAt.toIso8601String(),
      };

  BmiRecordModel copyWith({
    String? id,
    String? profileId,
    double? weightKg,
    double? heightCm,
    double? bmi,
    BMICategory? category,
    DateTime? recordedAt,
  }) {
    return BmiRecordModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      bmi: bmi ?? this.bmi,
      category: category ?? this.category,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, profileId, weightKg, heightCm, bmi, category, recordedAt];
}
