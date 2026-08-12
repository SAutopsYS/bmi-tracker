import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import 'providers.dart';

class ThemeNotifier extends StateNotifier<ThemePreference> {
  ThemeNotifier(this._ref)
      : super(_ref.read(localStorageServiceProvider).getThemePreference());

  final Ref _ref;

  Future<void> setPreference(ThemePreference preference) async {
    state = preference;
    await _ref.read(localStorageServiceProvider).setThemePreference(preference);
  }
}

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, ThemePreference>((ref) {
  return ThemeNotifier(ref);
});

/// Alias used by settings UI.
final themePreferenceProvider = themeNotifierProvider;

final themeModeProvider = Provider<ThemeMode>((ref) {
  final preference = ref.watch(themeNotifierProvider);
  switch (preference) {
    case ThemePreference.light:
      return ThemeMode.light;
    case ThemePreference.dark:
      return ThemeMode.dark;
    case ThemePreference.system:
      return ThemeMode.system;
  }
});
