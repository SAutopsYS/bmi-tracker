import 'package:uuid/uuid.dart';

import '../models/enums.dart';
import '../models/profile_model.dart';
import '../services/bmi_service.dart';
import '../services/connectivity_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

/// Offline-first profile repository: cache first, sync when online.
class ProfileRepository {
  ProfileRepository({
    required LocalStorageService localStorage,
    required FirestoreService firestoreService,
    required ConnectivityService connectivityService,
    BMICalculatorService? bmiService,
    Uuid? uuid,
  })  : _local = localStorage,
        _firestore = firestoreService,
        _connectivity = connectivityService,
        _bmi = bmiService ?? const BMICalculatorService(),
        _uuid = uuid ?? const Uuid();

  final LocalStorageService _local;
  final FirestoreService _firestore;
  final ConnectivityService _connectivity;
  final BMICalculatorService _bmi;
  final Uuid _uuid;

  List<ProfileModel> getCachedProfiles(String userId) =>
      _local.getProfiles(userId: userId);

  ProfileModel? getCachedProfile(String id) => _local.getProfile(id);

  String? getSelectedProfileId() => _local.getSelectedProfileId();

  Future<void> setSelectedProfileId(String? id) =>
      _local.setSelectedProfileId(id);

  bool get hasProfiles {
    final selected = _local.getSelectedProfileId();
    if (selected != null && _local.getProfile(selected) != null) return true;
    return _local.getProfiles().isNotEmpty;
  }

  Future<List<ProfileModel>> fetchProfiles(String userId) async {
    final cached = _local.getProfiles(userId: userId);

    if (!_connectivity.isOnline) {
      return cached;
    }

    try {
      final remote = await _firestore.getProfiles(userId);
      await _local.saveProfiles(remote);
      await _flushProfileQueue();
      return _local.getProfiles(userId: userId);
    } catch (_) {
      return cached;
    }
  }

  Future<ProfileModel> createProfile({
    required String userId,
    required String name,
    required Gender gender,
    required DateTime dateOfBirth,
    required double heightCm,
    required double weightKg,
    WeightUnit weightUnit = WeightUnit.kg,
    HeightUnit heightUnit = HeightUnit.cm,
    String? avatarPath,
    bool isPrimary = false,
  }) async {
    final now = DateTime.now();
    final bmi = _bmi.calculateBMIFromCm(
      weightKg: weightKg,
      heightCm: heightCm,
    );

    var profiles = _local.getProfiles(userId: userId);
    final makePrimary = isPrimary || profiles.isEmpty;

    if (makePrimary) {
      for (final p in profiles.where((p) => p.isPrimary)) {
        await _persist(
          p.copyWith(isPrimary: false, updatedAt: now),
          enqueueIfOffline: true,
        );
      }
    }

    final profile = ProfileModel(
      id: _uuid.v4(),
      userId: userId,
      name: name.trim(),
      gender: gender,
      dateOfBirth: dateOfBirth,
      heightCm: heightCm,
      weightKg: weightKg,
      weightUnit: weightUnit,
      heightUnit: heightUnit,
      bmi: bmi,
      avatarPath: avatarPath,
      createdAt: now,
      updatedAt: now,
      isPrimary: makePrimary,
      syncStatus:
          _connectivity.isOnline ? SyncStatus.synced : SyncStatus.pending,
    );

    await _persist(profile, enqueueIfOffline: true);

    if (makePrimary || _local.getSelectedProfileId() == null) {
      await _local.setSelectedProfileId(profile.id);
    }

    return profile;
  }

  /// Upserts an existing [ProfileModel] identity (keeps [profile.id]).
  Future<ProfileModel> saveProfile(ProfileModel profile) async {
    return updateProfile(profile);
  }

  Future<ProfileModel> updateProfile(ProfileModel profile) async {
    final bmi = _bmi.calculateBMIFromCm(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
    );
    final updated = profile.copyWith(
      bmi: bmi,
      updatedAt: DateTime.now(),
      syncStatus:
          _connectivity.isOnline ? SyncStatus.synced : SyncStatus.pending,
    );

    if (updated.isPrimary) {
      final others = _local
          .getProfiles(userId: updated.userId)
          .where((p) => p.id != updated.id && p.isPrimary);
      for (final p in others) {
        await _persist(
          p.copyWith(isPrimary: false, updatedAt: DateTime.now()),
          enqueueIfOffline: true,
        );
      }
    }

    await _persist(updated, enqueueIfOffline: true);
    return updated;
  }

  Future<void> deleteProfile(ProfileModel profile) async {
    await _local.deleteProfile(profile.id);
    await _local.deleteHistoryForProfile(profile.id);

    if (_local.getSelectedProfileId() == profile.id) {
      final remaining = _local.getProfiles(userId: profile.userId);
      await _local.setSelectedProfileId(
        remaining.isEmpty ? null : remaining.first.id,
      );
    }

    if (_connectivity.isOnline) {
      try {
        await _firestore.deleteProfile(profile.userId, profile.id);
      } catch (e) {
        await _local.enqueueSync(
          SyncQueueItem(
            id: _uuid.v4(),
            collection: 'profiles',
            action: 'delete',
            payload: {'userId': profile.userId, 'id': profile.id},
            createdAt: DateTime.now(),
          ),
        );
      }
    } else {
      await _local.enqueueSync(
        SyncQueueItem(
          id: _uuid.v4(),
          collection: 'profiles',
          action: 'delete',
          payload: {'userId': profile.userId, 'id': profile.id},
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> syncPending(String userId) async {
    if (!_connectivity.isOnline) return;
    try {
      final remote = await _firestore.getProfiles(userId);
      await _local.saveProfiles(remote);
      await _flushProfileQueue();
    } catch (_) {
      // Keep cache.
    }
  }

  Future<void> _persist(
    ProfileModel profile, {
    required bool enqueueIfOffline,
  }) async {
    await _local.upsertProfile(profile);

    if (_connectivity.isOnline) {
      try {
        await _firestore.upsertProfile(
          profile.copyWith(syncStatus: SyncStatus.synced),
        );
        await _local.upsertProfile(
          profile.copyWith(syncStatus: SyncStatus.synced),
        );
        return;
      } catch (_) {
        // Fall through to queue.
      }
    }

    if (enqueueIfOffline) {
      await _local.enqueueSync(
        SyncQueueItem(
          id: _uuid.v4(),
          collection: 'profiles',
          action: 'upsert',
          payload: profile.toJson(),
          createdAt: DateTime.now(),
        ),
      );
    }
  }

  Future<void> _flushProfileQueue() async {
    final queue =
        _local.getSyncQueue().where((i) => i.collection == 'profiles').toList();

    for (final item in queue) {
      try {
        if (item.action == 'delete') {
          final userId = item.payload['userId'] as String;
          final id = item.payload['id'] as String;
          await _firestore.deleteProfile(userId, id);
        } else {
          final profile = ProfileModel.fromJson(item.payload);
          await _firestore.upsertProfile(
            profile.copyWith(syncStatus: SyncStatus.synced),
          );
          final local = _local.getProfile(profile.id);
          if (local != null) {
            await _local.upsertProfile(
              local.copyWith(syncStatus: SyncStatus.synced),
            );
          }
        }
        await _local.removeSyncItem(item.id);
      } catch (_) {
        // Retry later.
      }
    }
  }

  Future<ProfileModel> recalculateBmi(ProfileModel profile) async {
    final bmi = _bmi.calculateBMIFromCm(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
    );
    return updateProfile(profile.copyWith(bmi: bmi));
  }
}
