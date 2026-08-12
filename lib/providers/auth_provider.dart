import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../models/user_model.dart';
import 'providers.dart';

final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
});

final currentUserProvider = Provider<UserModel?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

class AuthNotifierState {
  const AuthNotifierState({
    this.isLoading = false,
    this.failure,
    this.message,
  });

  final bool isLoading;
  final AppFailure? failure;
  final String? message;

  AuthNotifierState copyWith({
    bool? isLoading,
    AppFailure? failure,
    String? message,
    bool clearFailure = false,
    bool clearMessage = false,
  }) {
    return AuthNotifierState(
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthNotifierState> {
  AuthNotifier(this._ref) : super(const AuthNotifierState());

  final Ref _ref;

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state =
        state.copyWith(isLoading: true, clearFailure: true, clearMessage: true);
    try {
      await _ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    state =
        state.copyWith(isLoading: true, clearFailure: true, clearMessage: true);
    try {
      await _ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            displayName: displayName,
          );
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return false;
    }
  }

  /// Returns true on success, false on failure, null if cancelled.
  Future<bool?> signInWithGoogle() async {
    state =
        state.copyWith(isLoading: true, clearFailure: true, clearMessage: true);
    try {
      final user = await _ref.read(authRepositoryProvider).signInWithGoogle();
      state = state.copyWith(isLoading: false);
      if (user == null) return null;
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state =
        state.copyWith(isLoading: true, clearFailure: true, clearMessage: true);
    try {
      await _ref.read(authRepositoryProvider).sendPasswordReset(email);
      state = state.copyWith(
        isLoading: false,
        message: 'Password reset email sent. Check your inbox.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return false;
    }
  }

  Future<bool> signInDemo() async {
    state =
        state.copyWith(isLoading: true, clearFailure: true, clearMessage: true);
    try {
      await _ref.read(authRepositoryProvider).signInDemo();
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      await _ref.read(authRepositoryProvider).signOut();
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
    }
  }
}

final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthNotifierState>((ref) {
  return AuthNotifier(ref);
});

/// Screen-facing auth controller using AsyncValue (loading/error).
class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController(this._ref) : super(const AsyncData(null));

  final Ref _ref;

  Future<bool> signInWithEmail({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).signIn(
            email: email,
            password: password,
          );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
      return false;
    }
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            displayName: name,
          );
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
      return false;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = const AsyncLoading();
    try {
      final user = await _ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncData(null);
      return user != null;
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
      return false;
    }
  }

  Future<bool> sendPasswordReset(String email) async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).sendPasswordReset(email);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
      return false;
    }
  }

  Future<bool> signInDemo() async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).signInDemo();
      _ref.invalidate(historyProvider);
      await _ref.read(profilesProvider.notifier).refresh();
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
      return false;
    }
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).signOut();
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
    }
  }

  /// Local demo only. Reloads Rahul/Priya seed without signing out.
  Future<bool> resetLocalDemoData() async {
    state = const AsyncLoading();
    try {
      await _ref.read(authRepositoryProvider).resetLocalDemoData();
      _ref.invalidate(profilesProvider);
      _ref.invalidate(historyProvider);
      state = const AsyncData(null);
      return true;
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
      return false;
    }
  }

  void clearError() {
    if (state.hasError) state = const AsyncData(null);
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(ref);
});

final isBusyProvider = Provider<bool>((ref) {
  return ref.watch(authControllerProvider).isLoading;
});
