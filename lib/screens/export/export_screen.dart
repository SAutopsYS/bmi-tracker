import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/common/app_button.dart';
import 'package:bmi_tracker/widgets/common/empty_state.dart';

/// Standalone export route; Settings also exposes the same CSV share action.
class ExportScreen extends ConsumerWidget {
  const ExportScreen({super.key});

  static const String routePath = '/export';
  static const String routeName = 'export';

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final ok =
        await ref.read(healthNotifierProvider.notifier).exportSelectedProfile();
    if (!context.mounted) return;
    final state = ref.read(healthNotifierProvider);
    final message = state.message ?? state.failure?.message;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } else if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.exportEmpty)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(selectedProfileProvider);
    final history = ref.watch(historyProvider).valueOrNull ?? [];
    final busy = ref.watch(healthNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.exportTitle),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/settings');
            }
          },
        ),
      ),
      body: Padding(
        padding: AppSpacing.screenPadding,
        child: profile == null
            ? EmptyState(
                icon: Icons.person_off_outlined,
                title: AppStrings.noProfiles,
                message: 'Select or create a profile, then export again.',
                actionLabel: AppStrings.profilesTitle,
                onAction: () => context.go('/profiles'),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Export ${profile.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    history.isEmpty
                        ? AppStrings.exportEmpty
                        : '${history.length} weight entries will be shared as CSV.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  AppButton(
                    label: AppStrings.exportCsv,
                    icon: Icons.ios_share_rounded,
                    isLoading: busy,
                    onPressed: history.isEmpty || busy
                        ? null
                        : () => _export(context, ref),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    AppStrings.privacyNote,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
      ),
    );
  }
}
