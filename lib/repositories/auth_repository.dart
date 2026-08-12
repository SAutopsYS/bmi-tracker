import '../core/errors/app_exception.dart';
import '../core/errors/app_failure.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/demo_seed_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';
import 'profile_repository.dart';

class AuthRepository {
  AuthRepository({
    required AuthService authService,
    required FirestoreService firestoreService,
    required LocalStorageService localStorage,
    required DemoSeedService demoSeedService,
    ProfileRepository? profileRepository,
  })  : _auth = authService,
        _firestore = firestoreService,
        _local = localStorage,
        _demoSeed = demoSeedService,
        _profileRepository = profileRepository;

  final AuthService _auth;
  final FirestoreService _firestore;
  final LocalStorageService _local;
  final DemoSeedService _demoSeed;
  ProfileRepository? _profileRepository;

  void attachProfileRepository(ProfileRepository repo) {
    _profileRepository = repo;
  }

  Stream<UserModel?> authStateChanges() => _auth.authStateChanges;

  UserModel? get currentUser => _auth.currentUser;

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _auth.signInWithEmail(
        email: email,
        password: password,
      );
      await _ensureUserDoc(user);
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw FailureMapper.fromObject(e);
    }
  }

  Future<UserModel> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    try {
      final user = await _auth.registerWithEmail(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _ensureUserDoc(user);
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw FailureMapper.fromObject(e);
    }
  }

  /// Returns null if Google sign-in was cancelled.
  Future<UserModel?> signInWithGoogle() async {
    try {
      final user = await _auth.signInWithGoogle();
      if (user == null) return null;
      await _ensureUserDoc(user);
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw FailureMapper.fromObject(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
    } on AppException {
      rethrow;
    } catch (e) {
      throw FailureMapper.fromObject(e);
    }
  }

  Future<UserModel> signInDemo() async {
    try {
      final user = await _auth.signInDemo();
      await _ensureUserDoc(user);
      await _seedDemoIfNeeded(user.id);
      return user;
    } on AppException {
      rethrow;
    } catch (e) {
      throw FailureMapper.fromObject(e);
    }
  }

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _local.clearUserData();
    } on AppException {
      rethrow;
    } catch (e) {
      throw FailureMapper.fromObject(e);
    }
  }

  /// Restores Rahul/Priya seed data on-device. Local demo mode only.
  /// Never touches production Firebase and never deletes the auth account.
  Future<void> resetLocalDemoData() async {
    if (isFirebaseReady) {
      throw const ValidationException(
        'Demo reset is only available in local demo mode.',
      );
    }
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException('Sign in before resetting demo data.');
    }

    await _local.clearProfilesHistoryAndQueue();
    final seed = _demoSeed.buildSeedData(user.id);
    await _local.saveProfiles(seed.profiles);
    await _local.saveHistory(seed.history);
    if (seed.profiles.isNotEmpty) {
      await _local.setSelectedProfileId(seed.profiles.first.id);
    }
  }

  Future<void> _ensureUserDoc(UserModel user) async {
    try {
      await _firestore.upsertUser(user);
    } catch (_) {
      // Offline-tolerant: local auth still proceeds.
    }
  }

  Future<void> _seedDemoIfNeeded(String userId) async {
    final existing = _local.getProfiles(userId: userId);
    if (existing.isNotEmpty) return;

    final seed = _demoSeed.buildSeedData(userId);
    await _local.saveProfiles(seed.profiles);
    await _local.saveHistory(seed.history);
    if (seed.profiles.isNotEmpty) {
      await _local.setSelectedProfileId(seed.profiles.first.id);
    }

    final repo = _profileRepository;
    if (repo != null) {
      try {
        for (final profile in seed.profiles) {
          await _firestore.upsertProfile(profile);
        }
        for (final entry in seed.history) {
          await _firestore.upsertWeightEntry(entry);
        }
      } catch (_) {
        // Best-effort remote seed.
      }
    }
  }
}
