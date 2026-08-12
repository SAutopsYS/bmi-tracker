import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../screens/auth/forgot_password/forgot_password_screen.dart';
import '../../screens/auth/login/login_screen.dart';
import '../../screens/auth/register/register_screen.dart';
import '../../screens/dashboard/dashboard_screen.dart';
import '../../screens/export/export_screen.dart';
import '../../screens/history/history_screen.dart';
import '../../screens/home/home_shell.dart';
import '../../screens/profile_setup/profile_setup_screen.dart';
import '../../screens/profiles/profile_form_screen.dart';
import '../../screens/profiles/profiles_screen.dart';
import '../../screens/settings/settings_screen.dart';
import '../../screens/splash/splash_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final authListenable = _AuthRefreshListenable(ref);

  ref.onDispose(authListenable.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    refreshListenable: authListenable,
    redirect: (context, state) {
      final authAsync = ref.read(authStateProvider);
      final loc = state.matchedLocation;

      final isSplash = loc == '/splash';
      final isAuthRoute =
          loc == '/login' || loc == '/register' || loc == '/forgot-password';

      // Still resolving auth.
      if (authAsync.isLoading || authAsync.isRefreshing) {
        return isSplash ? null : '/splash';
      }

      final user = authAsync.valueOrNull;
      final loggedIn = user != null;

      if (!loggedIn) {
        if (isAuthRoute || isSplash) {
          if (isSplash) return '/login';
          return null;
        }
        return '/login';
      }

      // Logged in.
      final hasProfiles = ref.read(hasProfilesProvider);
      final needsProfile = !hasProfiles;

      if (isSplash) {
        return needsProfile ? '/profile-setup' : '/home';
      }

      if (isAuthRoute) {
        return needsProfile ? '/profile-setup' : '/home';
      }

      if (needsProfile && loc != '/profile-setup' && loc != '/profile-form') {
        return '/profile-setup';
      }

      if (!needsProfile && loc == '/profile-setup') {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/profile-setup',
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: '/profile-form',
        name: 'profile-form',
        builder: (context, state) {
          final id = state.uri.queryParameters['id'];
          return ProfileFormScreen(profileId: id);
        },
      ),
      GoRoute(
        path: '/export',
        name: 'export',
        builder: (context, state) => const ExportScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profiles',
                name: 'profiles',
                builder: (context, state) => const ProfilesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

/// Notifies [GoRouter] when auth or profile availability changes.
class _AuthRefreshListenable extends ChangeNotifier {
  _AuthRefreshListenable(this._ref) {
    _authSub = _ref.listen(authStateProvider, (_, __) => notifyListeners());
    _profilesSub =
        _ref.listen(hasProfilesProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<dynamic>> _authSub;
  late final ProviderSubscription<bool> _profilesSub;

  @override
  void dispose() {
    _authSub.close();
    _profilesSub.close();
    super.dispose();
  }
}
