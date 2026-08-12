import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/constants/app_constants.dart';
import '../firebase_options.dart';
import '../models/profile_model.dart';
import '../models/weight_history_model.dart';
import '../repositories/auth_repository.dart';
import '../repositories/health_repository.dart';
import '../repositories/profile_repository.dart';
import '../services/auth_service.dart';
import '../services/bmi_service.dart';
import '../services/connectivity_service.dart';
import '../services/demo_seed_service.dart';
import '../services/export_service.dart';
import '../services/firestore_service.dart';
import '../services/local_storage_service.dart';

export '../services/bmi_service.dart'
    show SevenDayStatistics, BMICalculatorService;
export 'auth_provider.dart';
export 'connectivity_provider.dart';
export 'health_provider.dart';
export 'profile_provider.dart';
export 'theme_provider.dart';

/// Demo credentials from env. Never hardcode passwords in UI source.
class DemoCredentials {
  DemoCredentials._();

  static Map<String, String> get _env {
    try {
      return dotenv.env;
    } catch (_) {
      return const {};
    }
  }

  static bool get isConfigured {
    final mode = _env['DEMO_MODE']?.toLowerCase();
    final enabled = mode == 'true' || mode == '1';
    final email = _env['DEMO_EMAIL'];
    if (!enabled || email == null || email.isEmpty) return false;
    // Local/Hive demo (incl. Web) works without password. Firebase needs one.
    if (!isFirebaseReady) return true;
    final password = _env['DEMO_PASSWORD'];
    return password != null && password.isNotEmpty;
  }

  static String get email => _env['DEMO_EMAIL'] ?? AppConstants.demoEmail;

  /// Only for controlled fill when [isConfigured]; never log or display.
  static String get password => _env['DEMO_PASSWORD'] ?? '';
}

/// Aggregated dashboard view model for UI screens.
@immutable
class DashboardData {
  const DashboardData({
    required this.profile,
    required this.history,
    required this.weekStats,
    required this.bmiTrendSentence,
    this.previousWeightKg,
  });

  final ProfileModel profile;
  final List<WeightHistoryModel> history;
  final SevenDayStatistics weekStats;
  final String bmiTrendSentence;
  final double? previousWeightKg;

  double? get weightChangeKg {
    if (previousWeightKg == null) return null;
    return double.parse(
      (profile.weightKg - previousWeightKg!).toStringAsFixed(2),
    );
  }
}

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  throw UnimplementedError(
    'localStorageServiceProvider must be overridden in main.dart',
  );
});

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  throw UnimplementedError(
    'connectivityServiceProvider must be overridden in main.dart',
  );
});

final bmiServiceProvider = Provider<BMICalculatorService>((ref) {
  return const BMICalculatorService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    localStorage: ref.watch(localStorageServiceProvider),
  );
});

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(bmiService: ref.watch(bmiServiceProvider));
});

final demoSeedServiceProvider = Provider<DemoSeedService>((ref) {
  return DemoSeedService(bmiService: ref.watch(bmiServiceProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    localStorage: ref.watch(localStorageServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    bmiService: ref.watch(bmiServiceProvider),
  );
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(
    localStorage: ref.watch(localStorageServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    connectivityService: ref.watch(connectivityServiceProvider),
    exportService: ref.watch(exportServiceProvider),
    bmiService: ref.watch(bmiServiceProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    authService: ref.watch(authServiceProvider),
    firestoreService: ref.watch(firestoreServiceProvider),
    localStorage: ref.watch(localStorageServiceProvider),
    demoSeedService: ref.watch(demoSeedServiceProvider),
    profileRepository: ref.watch(profileRepositoryProvider),
  );
});
