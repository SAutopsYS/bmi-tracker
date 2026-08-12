import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../constants/app_strings.dart';
import 'app_exception.dart';

/// Typed failures with user-friendly messages (never raw Firebase text).
sealed class AppFailure extends Equatable {
  const AppFailure(this.message, {this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

class AuthFailure extends AppFailure {
  const AuthFailure(super.message, {super.code});
}

class NetworkFailure extends AppFailure {
  const NetworkFailure({
    String message = AppStrings.errorNetwork,
    String? code,
  }) : super(message, code: code);
}

class StorageFailure extends AppFailure {
  const StorageFailure({
    String message = AppStrings.errorStorage,
    String? code,
  }) : super(message, code: code);
}

class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message, {super.code});
}

class UnknownFailure extends AppFailure {
  const UnknownFailure({
    String message = AppStrings.errorGeneric,
    String? code,
  }) : super(message, code: code);
}

/// Maps exceptions and Firebase Auth codes to friendly [AppFailure]s.
class FailureMapper {
  FailureMapper._();

  static AppFailure fromObject(Object error) {
    if (error is AppFailure) return error;
    if (error is AuthException) {
      return AuthFailure(error.message, code: error.code);
    }
    if (error is NetworkException) {
      return NetworkFailure(message: error.message, code: error.code);
    }
    if (error is StorageException) {
      return StorageFailure(message: error.message, code: error.code);
    }
    if (error is ValidationException) {
      return ValidationFailure(error.message, code: error.code);
    }
    if (error is firebase_auth.FirebaseAuthException) {
      return fromFirebaseAuth(error);
    }
    return const UnknownFailure();
  }

  static AuthFailure fromFirebaseAuth(firebase_auth.FirebaseAuthException e) {
    final message = switch (e.code) {
      'invalid-email' => 'That email address does not look valid.',
      'user-disabled' => 'This account has been disabled. Contact support.',
      'user-not-found' => 'No account found with that email.',
      'wrong-password' => 'Incorrect email or password.',
      'invalid-credential' => 'Incorrect email or password.',
      'email-already-in-use' => 'This email is already registered.',
      'operation-not-allowed' =>
        'This sign-in method is not enabled. Try another option.',
      'weak-password' => 'Password is too weak. Use at least 8 characters.',
      'too-many-requests' => 'Too many attempts. Wait a moment and try again.',
      'network-request-failed' =>
        'We could not connect to the server. Please check your internet connection.',
      'requires-recent-login' =>
        'Please sign in again to complete this action.',
      'account-exists-with-different-credential' =>
        'An account already exists with a different sign-in method.',
      'invalid-verification-code' => 'Invalid verification code.',
      'invalid-verification-id' => 'Verification expired. Request a new code.',
      'popup-closed-by-user' ||
      'canceled' ||
      'cancelled' ||
      'sign_in_canceled' ||
      'sign_in_cancelled' =>
        'Google sign in was cancelled.',
      _ => AppStrings.errorAuth,
    };
    return AuthFailure(message, code: e.code);
  }
}
