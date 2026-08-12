import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'providers/providers.dart';
import 'services/connectivity_service.dart';
import 'services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnv();

  final localStorage = LocalStorageService();
  await localStorage.init();

  final connectivity = ConnectivityService();
  await connectivity.init();

  await _initFirebase();

  final demoMode = _isDemoMode;

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorage),
        connectivityServiceProvider.overrideWithValue(connectivity),
      ],
      child: BmiTrackerApp(demoMode: demoMode),
    ),
  );
}

Future<void> _loadEnv() async {
  // Web only bundles declared assets (.env is gitignored). Use .env.example.
  if (kIsWeb) {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {
      // Env optional.
    }
    return;
  }

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    try {
      await dotenv.load(fileName: '.env.example');
    } catch (_) {
      // Env optional when not bundled.
    }
  }
}

bool get _isDemoMode {
  final flag = dotenv.env['DEMO_MODE']?.toLowerCase();
  return flag == 'true' || flag == '1';
}

Future<void> _initFirebase() async {
  if (!isFirebaseReady) {
    debugPrint(
      'Firebase not ready (placeholders or kFirebaseConfigured=false). '
      'App runs in local Hive mode. Run flutterfire configure, then set '
      'kFirebaseConfigured=true before enabling cloud auth/sync.',
    );
    return;
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('Firebase init failed: $e');
    debugPrintStack(stackTrace: st);
  }
}

class BmiTrackerApp extends ConsumerWidget {
  const BmiTrackerApp({super.key, this.demoMode = false});

  final bool demoMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        if (!demoMode) return child ?? const SizedBox.shrink();
        return Banner(
          message: 'DEMO',
          location: BannerLocation.topEnd,
          color: Theme.of(context).colorScheme.tertiary,
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
