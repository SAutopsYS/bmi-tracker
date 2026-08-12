import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/errors/app_exception.dart';
import '../firebase_options.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import '../models/weight_history_model.dart';

/// Firestore access for users/{uid}/profiles/{id}/weightHistory/{id}.
///
/// When Firebase is not configured, methods throw [StorageException] so
/// repositories can keep working from the local cache.
class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _db =
            isFirebaseReady ? (firestore ?? FirebaseFirestore.instance) : null;

  final FirebaseFirestore? _db;

  bool get isAvailable => _db != null;

  FirebaseFirestore get _requireDb {
    final db = _db;
    if (db == null) {
      throw const StorageException(
        'Cloud sync is unavailable until Firebase is configured.',
        code: 'firebase-not-configured',
      );
    }
    return db;
  }

  CollectionReference<Map<String, dynamic>> _users() =>
      _requireDb.collection('users');

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _users().doc(uid);

  CollectionReference<Map<String, dynamic>> _profiles(String uid) =>
      _userDoc(uid).collection('profiles');

  CollectionReference<Map<String, dynamic>> _weightHistory(
    String uid,
    String profileId,
  ) =>
      _profiles(uid).doc(profileId).collection('weightHistory');

  Future<void> upsertUser(UserModel user) async {
    try {
      await _userDoc(user.id).set(user.toJson(), SetOptions(merge: true));
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Could not save user profile.',
        code: e.code,
        cause: e,
      );
    }
  }

  Future<UserModel?> getUser(String uid) async {
    try {
      final snap = await _userDoc(uid).get();
      if (!snap.exists || snap.data() == null) return null;
      final data = snap.data()!;
      data['id'] = uid;
      return UserModel.fromJson(data);
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Could not load user.',
        code: e.code,
        cause: e,
      );
    }
  }

  Future<void> upsertProfile(ProfileModel profile) async {
    try {
      await _profiles(profile.userId)
          .doc(profile.id)
          .set(profile.toJson(), SetOptions(merge: true));
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Could not save profile.',
        code: e.code,
        cause: e,
      );
    }
  }

  Future<void> deleteProfile(String userId, String profileId) async {
    try {
      final history = await _weightHistory(userId, profileId).get();
      final batch = _requireDb.batch();
      for (final doc in history.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_profiles(userId).doc(profileId));
      await batch.commit();
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Could not delete profile.',
        code: e.code,
        cause: e,
      );
    }
  }

  Future<List<ProfileModel>> getProfiles(String userId) async {
    try {
      final snap = await _profiles(userId).get();
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['userId'] = userId;
        return ProfileModel.fromJson(data);
      }).toList();
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Could not load profiles.',
        code: e.code,
        cause: e,
      );
    }
  }

  Stream<List<ProfileModel>> watchProfiles(String userId) {
    if (_db == null) {
      return const Stream.empty();
    }
    return _profiles(userId).snapshots().map((snap) {
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['userId'] = userId;
        return ProfileModel.fromJson(data);
      }).toList();
    });
  }

  Future<void> upsertWeightEntry(WeightHistoryModel entry) async {
    try {
      await _weightHistory(entry.userId, entry.profileId)
          .doc(entry.id)
          .set(entry.toJson(), SetOptions(merge: true));
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Could not save weight entry.',
        code: e.code,
        cause: e,
      );
    }
  }

  Future<void> deleteWeightEntry({
    required String userId,
    required String profileId,
    required String entryId,
  }) async {
    try {
      await _weightHistory(userId, profileId).doc(entryId).delete();
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Could not delete weight entry.',
        code: e.code,
        cause: e,
      );
    }
  }

  Future<List<WeightHistoryModel>> getWeightHistory({
    required String userId,
    required String profileId,
  }) async {
    try {
      final snap = await _weightHistory(userId, profileId)
          .orderBy('recordedAt', descending: true)
          .get();
      return snap.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        data['userId'] = userId;
        data['profileId'] = profileId;
        return WeightHistoryModel.fromJson(data);
      }).toList();
    } on StorageException {
      rethrow;
    } on FirebaseException catch (e) {
      throw StorageException(
        'Could not load weight history.',
        code: e.code,
        cause: e,
      );
    }
  }

  Future<List<WeightHistoryModel>> getAllWeightHistory(String userId) async {
    final profiles = await getProfiles(userId);
    final all = <WeightHistoryModel>[];
    for (final profile in profiles) {
      all.addAll(
        await getWeightHistory(userId: userId, profileId: profile.id),
      );
    }
    all.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return all;
  }
}
