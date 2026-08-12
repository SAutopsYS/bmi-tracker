import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../models/enums.dart';
import '../models/profile_model.dart';
import '../models/weight_history_model.dart';

/// Pending offline write for later sync.
class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.collection,
    required this.action,
    required this.payload,
    required this.createdAt,
  });

  final String id;
  final String collection; // profiles | weightHistory
  final String action; // upsert | delete
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory SyncQueueItem.fromJson(Map<String, dynamic> json) {
    return SyncQueueItem(
      id: json['id'] as String,
      collection: json['collection'] as String,
      action: json['action'] as String,
      payload: Map<String, dynamic>.from(json['payload'] as Map),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'collection': collection,
        'action': action,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
      };
}

/// Hive wrappers for profiles cache, history, settings, and sync queue.
class LocalStorageService {
  LocalStorageService();

  Box<String>? _profilesBox;
  Box<String>? _historyBox;
  Box<dynamic>? _settingsBox;
  Box<String>? _syncQueueBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _profilesBox = await Hive.openBox<String>(AppConstants.profilesBox);
    _historyBox = await Hive.openBox<String>(AppConstants.historyBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
    _syncQueueBox = await Hive.openBox<String>(AppConstants.syncQueueBox);
  }

  Box<String> get _profiles {
    final box = _profilesBox;
    if (box == null) {
      throw const StorageException('Local storage is not initialized.');
    }
    return box;
  }

  Box<String> get _history {
    final box = _historyBox;
    if (box == null) {
      throw const StorageException('Local storage is not initialized.');
    }
    return box;
  }

  Box<dynamic> get _settings {
    final box = _settingsBox;
    if (box == null) {
      throw const StorageException('Local storage is not initialized.');
    }
    return box;
  }

  Box<String> get _syncQueue {
    final box = _syncQueueBox;
    if (box == null) {
      throw const StorageException('Local storage is not initialized.');
    }
    return box;
  }

  // --- Profiles ---

  Future<void> saveProfiles(List<ProfileModel> profiles) async {
    await _profiles.clear();
    for (final profile in profiles) {
      await _profiles.put(profile.id, jsonEncode(profile.toJson()));
    }
  }

  Future<void> upsertProfile(ProfileModel profile) async {
    await _profiles.put(profile.id, jsonEncode(profile.toJson()));
  }

  Future<void> deleteProfile(String profileId) async {
    await _profiles.delete(profileId);
  }

  List<ProfileModel> getProfiles({String? userId}) {
    final list = _profiles.values
        .map(
          (raw) =>
              ProfileModel.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        )
        .where((p) => userId == null || p.userId == userId)
        .toList()
      ..sort((a, b) {
        if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
        return a.name.compareTo(b.name);
      });
    return list;
  }

  ProfileModel? getProfile(String id) {
    final raw = _profiles.get(id);
    if (raw == null) return null;
    return ProfileModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  // --- Weight history ---

  Future<void> saveHistory(List<WeightHistoryModel> entries) async {
    await _history.clear();
    for (final entry in entries) {
      await _history.put(entry.id, jsonEncode(entry.toJson()));
    }
  }

  Future<void> upsertHistoryEntry(WeightHistoryModel entry) async {
    await _history.put(entry.id, jsonEncode(entry.toJson()));
  }

  Future<void> deleteHistoryEntry(String entryId) async {
    await _history.delete(entryId);
  }

  Future<void> deleteHistoryForProfile(String profileId) async {
    final keys = _history.keys.where((key) {
      final raw = _history.get(key);
      if (raw == null) return false;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return map['profileId'] == profileId;
    }).toList();
    await _history.deleteAll(keys);
  }

  List<WeightHistoryModel> getHistory({
    String? userId,
    String? profileId,
  }) {
    final list = _history.values
        .map(
      (raw) => WeightHistoryModel.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      ),
    )
        .where((e) {
      if (userId != null && e.userId != userId) return false;
      if (profileId != null && e.profileId != profileId) return false;
      return true;
    }).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  // --- Settings ---

  Future<void> setSelectedProfileId(String? id) async {
    if (id == null) {
      await _settings.delete(AppConstants.selectedProfileIdKey);
    } else {
      await _settings.put(AppConstants.selectedProfileIdKey, id);
    }
  }

  String? getSelectedProfileId() {
    return _settings.get(AppConstants.selectedProfileIdKey) as String?;
  }

  Future<void> setThemePreference(ThemePreference preference) async {
    await _settings.put(AppConstants.themePreferenceKey, preference.name);
  }

  ThemePreference getThemePreference() {
    final raw = _settings.get(AppConstants.themePreferenceKey) as String?;
    return ThemePreference.fromString(raw);
  }

  static const String _localSessionKey = 'local_auth_session';

  Future<void> setLocalAuthSession(String? json) async {
    if (json == null) {
      await _settings.delete(_localSessionKey);
    } else {
      await _settings.put(_localSessionKey, json);
    }
  }

  String? getLocalAuthSession() {
    return _settings.get(_localSessionKey) as String?;
  }

  // --- Sync queue ---

  Future<void> enqueueSync(SyncQueueItem item) async {
    await _syncQueue.put(item.id, jsonEncode(item.toJson()));
  }

  List<SyncQueueItem> getSyncQueue() {
    return _syncQueue.values
        .map(
          (raw) =>
              SyncQueueItem.fromJson(jsonDecode(raw) as Map<String, dynamic>),
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> removeSyncItem(String id) async {
    await _syncQueue.delete(id);
  }

  Future<void> clearSyncQueue() async {
    await _syncQueue.clear();
  }

  Future<void> clearUserData() async {
    await clearProfilesHistoryAndQueue();
    await _settings.delete(_localSessionKey);
  }

  /// Clears health data only. Keeps local auth session and theme preference.
  Future<void> clearProfilesHistoryAndQueue() async {
    await _profiles.clear();
    await _history.clear();
    await _syncQueue.clear();
    await _settings.delete(AppConstants.selectedProfileIdKey);
  }
}
