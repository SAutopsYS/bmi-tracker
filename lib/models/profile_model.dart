import 'package:equatable/equatable.dart';

import 'enums.dart';

class ProfileModel extends Equatable {
  const ProfileModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.gender,
    required this.dateOfBirth,
    required this.heightCm,
    required this.weightKg,
    required this.weightUnit,
    required this.heightUnit,
    required this.bmi,
    this.avatarPath,
    required this.createdAt,
    required this.updatedAt,
    this.isPrimary = false,
    this.syncStatus = SyncStatus.synced,
  });

  final String id;
  final String userId;
  final String name;
  final Gender gender;
  final DateTime dateOfBirth;
  final double heightCm;
  final double weightKg;
  final WeightUnit weightUnit;
  final HeightUnit heightUnit;
  final double bmi;
  final String? avatarPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isPrimary;
  final SyncStatus syncStatus;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      gender: Gender.fromString(json['gender'] as String?),
      dateOfBirth: DateTime.tryParse(json['dateOfBirth']?.toString() ?? '') ??
          DateTime(1990, 1, 1),
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 0,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      weightUnit: WeightUnit.fromString(json['weightUnit'] as String?),
      heightUnit: HeightUnit.fromString(json['heightUnit'] as String?),
      bmi: (json['bmi'] as num?)?.toDouble() ?? 0,
      avatarPath: json['avatarPath'] as String?,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? '') ??
          DateTime.now(),
      isPrimary: json['isPrimary'] as bool? ?? false,
      syncStatus: SyncStatus.fromString(json['syncStatus'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'name': name,
        'gender': gender.name,
        'dateOfBirth': dateOfBirth.toIso8601String(),
        'heightCm': heightCm,
        'weightKg': weightKg,
        'weightUnit': weightUnit.name,
        'heightUnit': heightUnit.name,
        'bmi': bmi,
        'avatarPath': avatarPath,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isPrimary': isPrimary,
        'syncStatus': syncStatus.name,
      };

  ProfileModel copyWith({
    String? id,
    String? userId,
    String? name,
    Gender? gender,
    DateTime? dateOfBirth,
    double? heightCm,
    double? weightKg,
    WeightUnit? weightUnit,
    HeightUnit? heightUnit,
    double? bmi,
    String? avatarPath,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPrimary,
    SyncStatus? syncStatus,
    bool clearAvatar = false,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      weightUnit: weightUnit ?? this.weightUnit,
      heightUnit: heightUnit ?? this.heightUnit,
      bmi: bmi ?? this.bmi,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPrimary: isPrimary ?? this.isPrimary,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        name,
        gender,
        dateOfBirth,
        heightCm,
        weightKg,
        weightUnit,
        heightUnit,
        bmi,
        avatarPath,
        createdAt,
        updatedAt,
        isPrimary,
        syncStatus,
      ];
}
