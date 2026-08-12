import 'package:equatable/equatable.dart';

import 'enums.dart';

class WeightHistoryModel extends Equatable {
  const WeightHistoryModel({
    required this.id,
    required this.profileId,
    required this.userId,
    required this.weightKg,
    required this.recordedAt,
    this.note,
    this.syncStatus = SyncStatus.synced,
    required this.createdAt,
  });

  final String id;
  final String profileId;
  final String userId;
  final double weightKg;
  final DateTime recordedAt;
  final String? note;
  final SyncStatus syncStatus;
  final DateTime createdAt;

  factory WeightHistoryModel.fromJson(Map<String, dynamic> json) {
    return WeightHistoryModel(
      id: json['id'] as String? ?? '',
      profileId: json['profileId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      recordedAt: DateTime.tryParse(json['recordedAt']?.toString() ?? '') ??
          DateTime.now(),
      note: json['note'] as String?,
      syncStatus: SyncStatus.fromString(json['syncStatus'] as String?),
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'profileId': profileId,
        'userId': userId,
        'weightKg': weightKg,
        'recordedAt': recordedAt.toIso8601String(),
        'note': note,
        'syncStatus': syncStatus.name,
        'createdAt': createdAt.toIso8601String(),
      };

  WeightHistoryModel copyWith({
    String? id,
    String? profileId,
    String? userId,
    double? weightKg,
    DateTime? recordedAt,
    String? note,
    SyncStatus? syncStatus,
    DateTime? createdAt,
    bool clearNote = false,
  }) {
    return WeightHistoryModel(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      userId: userId ?? this.userId,
      weightKg: weightKg ?? this.weightKg,
      recordedAt: recordedAt ?? this.recordedAt,
      note: clearNote ? null : (note ?? this.note),
      syncStatus: syncStatus ?? this.syncStatus,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        profileId,
        userId,
        weightKg,
        recordedAt,
        note,
        syncStatus,
        createdAt,
      ];
}
