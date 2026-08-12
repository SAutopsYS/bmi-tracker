import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bmi_tracker/core/constants/app_constants.dart';
import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/core/errors/app_failure.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/firebase_options.dart';
import 'package:bmi_tracker/models/enums.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/common/app_button.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  static const String routePath = '/settings';
  static const String routeName = 'settings';

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  Future<void> _export() async {
    final ok =
        await ref.read(healthNotifierProvider.notifier).exportSelectedProfile();
    if (!mounted) return;
    final state = ref.read(healthNotifierProvider);
    final message = state.message ?? state.failure?.message;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a profile before exporting.')),
      );
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.signOut),
        content: const Text('Sign out of BMI Tracker on this device?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(AppStrings.signOut),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
    if (!mounted) return;
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final themePref = ref.watch(themePreferenceProvider);
    final online = ref.watch(isOnlineNowProvider);
    final pending = ref.watch(pendingSyncCountProvider);
    final user = ref.watch(currentUserProvider);
    final exporting = ref.watch(healthNotifierProvider).isLoading;
    final scheme = Theme.of(context).colorScheme;
    final demoHint = DemoCredentials.isConfigured;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.settingsTitle)),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          Text('Appearance', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.themeLabel,
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<ThemePreference>(
                    segments: const [
                      ButtonSegment(
                        value: ThemePreference.system,
                        label: Text(AppStrings.themeSystem),
                        icon: Icon(Icons.brightness_auto_outlined),
                      ),
                      ButtonSegment(
                        value: ThemePreference.light,
                        label: Text(AppStrings.themeLight),
                        icon: Icon(Icons.light_mode_outlined),
                      ),
                      ButtonSegment(
                        value: ThemePreference.dark,
                        label: Text(AppStrings.themeDark),
                        icon: Icon(Icons.dark_mode_outlined),
                      ),
                    ],
                    selected: {themePref},
                    onSelectionChanged: (set) {
                      if (set.isNotEmpty) {
                        ref
                            .read(themePreferenceProvider.notifier)
                            .setPreference(set.first);
                      }
                    },
                    showSelectedIcon: false,
                    style: const ButtonStyle(
                      minimumSize: WidgetStatePropertyAll(Size(48, 48)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Data', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    !isFirebaseReady
                        ? Icons.storage_outlined
                        : (online
                            ? Icons.cloud_done_outlined
                            : Icons.cloud_off_outlined),
                    color: !isFirebaseReady
                        ? scheme.secondary
                        : (online ? scheme.secondary : scheme.tertiary),
                  ),
                  title: Text(
                    !isFirebaseReady
                        ? AppStrings.localDemoMode
                        : (online ? 'Online' : AppStrings.offlineMode),
                  ),
                  subtitle: Text(
                    !isFirebaseReady
                        ? AppStrings.cloudUnavailable
                        : online
                            ? (pending > 0
                                ? '${AppStrings.syncPending}: $pending'
                                : 'Cloud sync available for this account.')
                            : 'Working offline from cache. Sync resumes when you reconnect.',
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.ios_share_rounded),
                  title: const Text(AppStrings.exportData),
                  subtitle: const Text(AppStrings.exportCsv),
                  trailing: exporting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chevron_right_rounded),
                  onTap: exporting ? null : _export,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Privacy', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.health_and_safety_outlined, color: scheme.primary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      AppStrings.privacyNote,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Account', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.person_outline_rounded),
                  title: Text(user?.displayName ?? user?.email ?? 'Signed in'),
                  subtitle: user?.email != null ? Text(user!.email) : null,
                ),
                if (demoHint) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        Icon(Icons.science_outlined, color: scheme.tertiary),
                    title: const Text('Demo account available'),
                    subtitle: Text(
                      'Use Try demo account on the login screen when DEMO_MODE is enabled in your local .env. The password stays in env and is never hardcoded in the app.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                if (!isFirebaseReady) ...[
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(Icons.restart_alt_rounded,
                        color: scheme.secondary),
                    title: const Text(AppStrings.resetDemoData),
                    subtitle: const Text(AppStrings.resetDemoDataHint),
                    onTap: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text(AppStrings.resetDemoData),
                          content: const Text(
                            'Restore the sample Rahul and Priya profiles on this device? Your sign-in session stays active. This never deletes a Firebase account.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text(AppStrings.cancel),
                            ),
                            FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );
                      if (ok != true || !mounted) return;
                      final success = await ref
                          .read(authControllerProvider.notifier)
                          .resetLocalDemoData();
                      if (!mounted) return;
                      final err = ref.read(authControllerProvider).error;
                      final errMsg = err == null
                          ? 'Unable to reset demo data.'
                          : FailureMapper.fromObject(err).message;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            success ? 'Demo data restored.' : errMsg,
                          ),
                        ),
                      );
                      if (success) {
                        ref.invalidate(profilesProvider);
                        ref.invalidate(historyProvider);
                      }
                    },
                  ),
                ],
                const Divider(height: 1),
                Padding(
                  padding: AppSpacing.cardPadding,
                  child: AppButton(
                    label: AppStrings.signOut,
                    onPressed: _signOut,
                    variant: AppButtonVariant.outlined,
                    icon: Icons.logout_rounded,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            AppStrings.aboutApp,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            ),
            child: Padding(
              padding: AppSpacing.cardPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppConstants.appName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Built by IV Innovations Private Limited',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    'Kundli, Sonipat',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.72),
                        ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${AppStrings.versionLabel} 1.0.0',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.6),
                        ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxxl),
        ],
      ),
    );
  }
}
