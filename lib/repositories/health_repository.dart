import 'package:uuid/uuid.dart';

import '../models/bmi_record_model.dart';
import '../models/enums.dart';
import '../models/profile_model.dart';
import '../models/weight_history_model.dart';
import '../services/bmi_service.dart';
import '../services/connectivity_service.dart';
import '../services/export_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

/// Offline-first weight history and BMI records.
class HealthRepository {
  HealthRepository({
    required LocalStorageService localStorage,
    required FirestoreService firestoreService,
    required ConnectivityService connectivityService,
    required ExportService exportService,
    BMICalculatorService? bmiService,
    Uuid? uuid,
  })  : _local = localStorage,
        _firestore = firestoreService,
        _connectivity = connectivityService,
        _export = exportService,
        _bmi = bmiService ?? const BMICalculatorService(),
        _uuid = uuid ?? const Uuid();

  final LocalStorageService _local;
  final FirestoreService _firestore;
  final ConnectivityService _connectivity;
  final ExportService _export;
  final BMICalculatorService _bmi;
  final Uuid _uuid;

  List<WeightHistoryModel> getCachedHistory({
    String? userId,
    String? profileId,
  }) =>
      _local.getHistory(userId: userId, profileId: profileId);

  Future<List<WeightHistoryModel>> fetchHistory({
    required String userId,
    required String profileId,
  }) async {
    final cached = _local.getHistory(userId: userId, profileId: profileId);

    if (!_connectivity.isOnline) {
      return cached;
    }

    try {
      final remote = await _firestore.getWeightHistory(
        userId: userId,
        profileId: profileId,
      );
      // Merge remote into local without wiping other profiles' history.
      for (final entry in remote) {
        await _local.upsertHistoryEntry(
          entry.copyWith(syncStatus: SyncStatus.synced),
        );
      }
      await _flushHistoryQueue();
      return _local.getHistory(userId: userId, profileId: profileId);
    } catch (_) {
      return cached;
    }
  }

  Future<WeightHistoryModel> logWeight({
    required ProfileModel profile,
    required double weightKg,
    DateTime? recordedAt,
    String? note,
  }) async {
    final at = recordedAt ?? DateTime.now();
    final entry = WeightHistoryModel(
      id: _uuid.v4(),
      profileId: profile.id,
      userId: profile.userId,
      weightKg: weightKg,
      recordedAt: at,
      note: note,
      syncStatus:
          _connectivity.isOnline ? SyncStatus.synced : SyncStatus.pending,
      createdAt: DateTime.now(),
    );

    await _persistEntry(entry);

    final bmi = _bmi.calculateBMIFromCm(
      weightKg: weightKg,
      heightCm: profile.heightCm,
    );
    final updatedProfile = profile.copyWith(
      weightKg: weightKg,
      bmi: bmi,
      updatedAt: DateTime.now(),
      syncStatus:
          _connectivity.isOnline ? SyncStatus.synced : SyncStatus.pending,
    );
    await _local.upsertProfile(updatedProfile);

    if (_connectivity.isOnline) {
      try {
        await _firestore.upsertProfile(
          updatedProfile.copyWith(syncStatus: SyncStatus.synced),
        );
      } catch (_) {
        await _local.enqueueSync(
          SyncQueueItem(
            id: _uuid.v4(),
            collection: 'profiles',
            action: 'upsert',
            payload: updatedProfile.toJson(),
            createdAt: DateTime.now(),
          ),
        );
      }
    } else {
      await _local.enqueueSync(
        SyncQueueItem(
          id: _uuid.v4(),
          collection: 'profiles',
          action: 'upsert',
          payload: updatedProfile.toJson(),
          createdAt: DateTime.now(),
        ),
      );
    }

    return entry;
  }

  Future<void> deleteEntry(WeightHistoryModel entry) async {
    await _local.deleteHistoryEntry(entry.id);

    if (_connectivity.isOnline) {
      try {
        await _firestore.deleteWeightEntry(
          userId: entry.userId,
          profileId: entry.profileId,
          entryId: entry.id,
        );
      } catch (_) {
        await _enqueueDelete(entry);
      }
    } else {
      await _enqueueDelete(entry);
    }
  }

  List<BmiRecordModel> buildBmiRecords({
    required ProfileModel profile,
    required List<WeightHistoryModel> history,
  }) {
    return history.map((entry) {
      final bmi = _bmi.calculateBMIFromCm(
        weightKg: entry.weightKg,
        heightCm: profile.heightCm,
      );
      return BmiRecordModel(
        id: entry.id,
        profileId: profile.id,
        weightKg: entry.weightKg,
        heightCm: profile.heightCm,
        bmi: bmi,
        category: _bmi.getBMICategory(bmi),
        recordedAt: entry.recordedAt,
      );
    }).toList();
  }

  SevenDayStatistics sevenDayStats({
    required ProfileModel profile,
    List<WeightHistoryModel>? history,
  }) {
    final entries = history ??
        _local.getHistory(profileId: profile.id, userId: profile.userId);
    return _bmi.sevenDayStatistics(
      history: entries,
      heightCm: profile.heightCm,
    );
  }

  Future<void> exportCsv({
    required ProfileModel profile,
    List<WeightHistoryModel>? history,
  }) async {
    final entries = history ??
        _local.getHistory(profileId: profile.id, userId: profile.userId);
    await _export.shareCsv(profile: profile, history: entries);
  }

  Future<void> syncPending({
    required String userId,
    required String profileId,
  }) async {
    if (!_connectivity.isOnline) return;
    try {
      final remote = await _firestore.getWeightHistory(
        userId: userId,
        profileId: profileId,
      );
      for (final entry in remote) {
        await _local.upsertHistoryEntry(
          entry.copyWith(syncStatus: SyncStatus.synced),
        );
      }
      await _flushHistoryQueue();
    } catch (_) {
      // Keep cache.
    }
  }

  Future<void> _persistEntry(WeightHistoryModel entry) async {
    await _local.upsertHistoryEntry(entry);

    if (_connectivity.isOnline) {
      try {
        await _firestore.upsertWeightEntry(
          entry.copyWith(syncStatus: SyncStatus.synced),
        );
        await _local.upsertHistoryEntry(
          entry.copyWith(syncStatus: SyncStatus.synced),
        );
        return;
      } catch (_) {
        // Queue below.
      }
    }

    await _local.enqueueSync(
      SyncQueueItem(
        id: _uuid.v4(),
        collection: 'weightHistory',
        action: 'upsert',
        payload: entry.toJson(),
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _enqueueDelete(WeightHistoryModel entry) async {
    await _local.enqueueSync(
      SyncQueueItem(
        id: _uuid.v4(),
        collection: 'weightHistory',
        action: 'delete',
        payload: {
          'userId': entry.userId,
          'profileId': entry.profileId,
          'id': entry.id,
        },
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> _flushHistoryQueue() async {
    final queue = _local
        .getSyncQueue()
        .where((i) => i.collection == 'weightHistory')
        .toList();

    for (final item in queue) {
      try {
        if (item.action == 'delete') {
          await _firestore.deleteWeightEntry(
            userId: item.payload['userId'] as String,
            profileId: item.payload['profileId'] as String,
            entryId: item.payload['id'] as String,
          );
        } else {
          final entry = WeightHistoryModel.fromJson(item.payload);
          await _firestore.upsertWeightEntry(
            entry.copyWith(syncStatus: SyncStatus.synced),
          );
          await _local.upsertHistoryEntry(
            entry.copyWith(syncStatus: SyncStatus.synced),
          );
        }
        await _local.removeSyncItem(item.id);
      } catch (_) {
        // Retry later.
      }
    }
  }
}
