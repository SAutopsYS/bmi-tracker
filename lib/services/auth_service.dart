import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../core/constants/app_constants.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/app_failure.dart';
import '../firebase_options.dart';
import '../models/user_model.dart';
import 'local_storage_service.dart';

/// Email/password, Google, reset, and auth state.
///
/// When [isFirebaseReady] is false, uses local Hive-backed sessions so the
/// app can run without `flutterfire configure`. That is **local demo mode**,
/// not production Firebase Authentication.
class AuthService {
  AuthService({
    required LocalStorageService localStorage,
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _local = localStorage,
        _firebaseAuth =
            isFirebaseReady ? (auth ?? FirebaseAuth.instance) : null,
        _googleSignIn =
            isFirebaseReady ? (googleSignIn ?? GoogleSignIn()) : null {
    if (!isFirebaseReady) {
      _localUser = _readLocalSession();
    }
  }

  final LocalStorageService _local;
  final FirebaseAuth? _firebaseAuth;
  final GoogleSignIn? _googleSignIn;

  final StreamController<UserModel?> _localController =
      StreamController<UserModel?>.broadcast();
  UserModel? _localUser;

  bool get usesFirebase => _firebaseAuth != null;

  Stream<UserModel?> get authStateChanges {
    final auth = _firebaseAuth;
    if (auth != null) {
      return auth.authStateChanges().map((user) {
        if (user == null) return null;
        return _mapFirebaseUser(user);
      });
    }
    return Stream.multi((controller) {
      controller.add(_localUser);
      final sub = _localController.stream.listen(
        controller.add,
        onError: controller.addError,
        onDone: controller.close,
      );
      controller.onCancel = sub.cancel;
    });
  }

  UserModel? get currentUser {
    final auth = _firebaseAuth;
    if (auth != null) {
      final user = auth.currentUser;
      if (user == null) return null;
      return _mapFirebaseUser(user);
    }
    return _localUser;
  }

  UserModel _mapFirebaseUser(User user) {
    return UserModel(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      photoUrl: user.photoURL,
      createdAt: user.metadata.creationTime,
      isDemo: user.email == AppConstants.demoEmail,
    );
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      return _localSignIn(email: email, password: password);
    }
    try {
      final cred = await auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthException('Sign-in failed. Please try again.');
      }
      return _mapFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        FailureMapper.fromFirebaseAuth(e).message,
        code: e.code,
        cause: e,
      );
    }
  }

  Future<UserModel> registerWithEmail({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      final user = await _localSignIn(email: email, password: password);
      if (displayName != null && displayName.trim().isNotEmpty) {
        final named = user.copyWith(displayName: displayName.trim());
        await _setLocalSession(named);
        return named;
      }
      return user;
    }
    try {
      final cred = await auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final user = cred.user;
      if (user == null) {
        throw const AuthException('Registration failed. Please try again.');
      }
      if (displayName != null && displayName.trim().isNotEmpty) {
        await user.updateDisplayName(displayName.trim());
        await user.reload();
      }
      return _mapFirebaseUser(auth.currentUser ?? user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        FailureMapper.fromFirebaseAuth(e).message,
        code: e.code,
        cause: e,
      );
    }
  }

  /// Returns null when the user cancels Google sign-in.
  Future<UserModel?> signInWithGoogle() async {
    final auth = _firebaseAuth;
    final googleSignIn = _googleSignIn;
    if (auth == null || googleSignIn == null) {
      throw const AuthException(
        'Google sign-in requires Firebase. Run flutterfire configure.',
        code: 'operation-not-allowed',
      );
    }
    try {
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      final cred = await auth.signInWithCredential(credential);
      final user = cred.user;
      if (user == null) {
        throw const AuthException('Google sign-in failed. Please try again.');
      }
      return _mapFirebaseUser(user);
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        FailureMapper.fromFirebaseAuth(e).message,
        code: e.code,
        cause: e,
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      final message = e.toString().toLowerCase();
      if (message.contains('canceled') || message.contains('cancelled')) {
        return null;
      }
      throw AuthException(
        'Google sign-in failed. Please try again.',
        cause: e,
      );
    }
  }

  Future<void> sendPasswordReset(String email) async {
    final auth = _firebaseAuth;
    if (auth == null) {
      if (email.trim().isEmpty) {
        throw const AuthException('Please enter your email.');
      }
      return;
    }
    try {
      await auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw AuthException(
        FailureMapper.fromFirebaseAuth(e).message,
        code: e.code,
        cause: e,
      );
    }
  }

  Future<void> signOut() async {
    final auth = _firebaseAuth;
    if (auth == null) {
      _localUser = null;
      await _local.setLocalAuthSession(null);
      _localController.add(null);
      return;
    }
    try {
      final google = _googleSignIn;
      await Future.wait([
        auth.signOut(),
        if (google != null) google.signOut(),
      ]);
    } catch (e) {
      throw AuthException('Could not sign out. Please try again.', cause: e);
    }
  }

  Future<UserModel> signInDemo() async {
    final email = dotenv.env['DEMO_EMAIL'] ?? AppConstants.demoEmail;
    final password = dotenv.env['DEMO_PASSWORD'] ?? '';

    if (_firebaseAuth == null) {
      // Local demo works without DEMO_PASSWORD.
      final user = UserModel(
        id: _localUserId(email),
        email: email,
        displayName: 'Demo User',
        createdAt: DateTime.now(),
        isDemo: true,
      );
      await _setLocalSession(user);
      return user;
    }

    if (password.isEmpty) {
      throw const AuthException(
        'Demo password is not configured. Set DEMO_PASSWORD in .env.',
      );
    }
    return signInWithEmail(email: email, password: password);
  }

  bool get isDemoMode {
    final flag = dotenv.env['DEMO_MODE']?.toLowerCase();
    return flag == 'true' || flag == '1';
  }

  Future<UserModel> _localSignIn({
    required String email,
    required String password,
  }) async {
    if (password.length < AppConstants.passwordMinLength) {
      throw const AuthException(
        'Password must be at least 8 characters.',
        code: 'weak-password',
      );
    }
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw const AuthException(
        'Enter a valid email address.',
        code: 'invalid-email',
      );
    }
    final user = UserModel(
      id: _localUserId(normalized),
      email: email.trim(),
      displayName: email.split('@').first,
      createdAt: DateTime.now(),
      isDemo: normalized == AppConstants.demoEmail,
    );
    await _setLocalSession(user);
    return user;
  }

  String _localUserId(String email) {
    final normalized = email.trim().toLowerCase();
    return 'local-${normalized.hashCode.toRadixString(16)}';
  }

  Future<void> _setLocalSession(UserModel user) async {
    _localUser = user;
    await _local.setLocalAuthSession(jsonEncode(user.toJson()));
    _localController.add(user);
  }

  UserModel? _readLocalSession() {
    final raw = _local.getLocalAuthSession();
    if (raw == null || raw.isEmpty) return null;
    try {
      return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}
