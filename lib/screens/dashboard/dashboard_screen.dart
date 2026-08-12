import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/charts/weight_trend_chart.dart';
import 'package:bmi_tracker/widgets/common/empty_state.dart';
import 'package:bmi_tracker/widgets/common/error_view.dart';
import 'package:bmi_tracker/widgets/common/skeleton_box.dart';
import 'package:bmi_tracker/widgets/common/status_banner.dart';
import 'package:bmi_tracker/widgets/dashboard/bmi_card.dart';
import 'package:bmi_tracker/widgets/dashboard/recent_history_list.dart';
import 'package:bmi_tracker/widgets/dashboard/stat_tile.dart';
import 'package:bmi_tracker/widgets/dashboard/week_stats_card.dart';
import 'package:bmi_tracker/widgets/forms/update_measurement_sheet.dart';
import 'package:bmi_tracker/widgets/profile/profile_avatar.dart';
import 'package:bmi_tracker/widgets/profile/profile_switcher.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  static const String routePath = '/home';
  static const String routeName = 'dashboard';

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _updateMeasurement(
    BuildContext context,
    WidgetRef ref, {
    required MeasurementType type,
  }) async {
    final profile = ref.read(selectedProfileProvider);
    if (profile == null) return;

    final result = await showUpdateMeasurementSheet(
      context: context,
      type: type,
      initialKg: profile.weightKg,
      initialCm: profile.heightCm,
      weightUnit: profile.weightUnit,
      heightUnit: profile.heightUnit,
    );
    if (result == null) return;

    final bmiService = ref.read(bmiServiceProvider);
    final now = DateTime.now();

    if (result.type == MeasurementType.weight) {
      final kg = result.valueAsKg;
      final ok = await ref
          .read(healthNotifierProvider.notifier)
          .logWeight(weightKg: kg);
      if (!context.mounted) return;
      final latest = ref.read(selectedProfileProvider);
      if (ok && latest != null && latest.weightUnit != result.weightUnit) {
        await ref.read(profilesProvider.notifier).upsert(
              latest.copyWith(weightUnit: result.weightUnit, updatedAt: now),
            );
      }
      if (!context.mounted) return;
      final action = ref.read(healthNotifierProvider);
      final msg = action.message ??
          action.failure?.message ??
          (ok ? 'Weight updated.' : 'Could not update weight.');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } else {
      await ref.read(profilesProvider.notifier).upsert(
            profile.copyWith(
              heightCm: result.valueAsCm,
              heightUnit: result.heightUnit,
              bmi: bmiService.calculateBMIFromCm(
                weightKg: profile.weightKg,
                heightCm: result.valueAsCm,
              ),
              updatedAt: now,
            ),
          );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Height updated. BMI recalculated.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(dashboardProvider);
    final profiles = ref.watch(profilesProvider).valueOrNull ?? [];
    final selected = ref.watch(selectedProfileProvider);
    final online = ref.watch(isOnlineNowProvider);
    final pending = ref.watch(pendingSyncCountProvider);
    final user = ref.watch(currentUserProvider);
    final scheme = Theme.of(context).colorScheme;
    final logging = ref.watch(healthNotifierProvider).isLoading;

    return Scaffold(
      body: Column(
        children: [
          StatusBanner(isOnline: online, pendingSyncCount: pending),
          Expanded(
            child: dashboard.when(
              loading: () => const DashboardSkeleton(),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(profilesProvider),
              ),
              data: (data) {
                if (data == null || selected == null) {
                  return EmptyState(
                    title: 'Welcome to BMI Tracker',
                    message: AppStrings.emptyDashboard,
                    icon: Icons.favorite_outline_rounded,
                    actionLabel: AppStrings.addProfile,
                    onAction: () => context.push('/profile-form'),
                  );
                }

                final profile = data.profile;
                final category =
                    ref.read(bmiServiceProvider).getBMICategory(profile.bmi);
                final weightDisplay = UnitConverter.fromKg(
                  kg: profile.weightKg,
                  toLbs: profile.weightUnit.isLbs,
                );
                final heightDisplay = UnitConverter.fromCm(
                  cm: profile.heightCm,
                  toInches: profile.heightUnit.isInches,
                );
                final change = data.weightChangeKg;
                final changeDisplay = change == null
                    ? null
                    : UnitConverter.fromKg(
                        kg: change,
                        toLbs: profile.weightUnit.isLbs,
                      );

                return RefreshIndicator(
                  onRefresh: () async {
                    await ref.read(profilesProvider.notifier).refresh();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverAppBar(
                        floating: true,
                        title: const Text(AppStrings.dashboardTitle),
                        actions: [
                          Padding(
                            padding:
                                const EdgeInsets.only(right: AppSpacing.md),
                            child: ProfileSwitcher(
                              profiles: profiles,
                              selected: selected,
                              onSelected: (p) {
                                ref
                                    .read(profilesProvider.notifier)
                                    .select(p.id);
                              },
                            ),
                          ),
                        ],
                      ),
                      SliverPadding(
                        padding: AppSpacing.screenPadding,
                        sliver: SliverList(
                          delegate: SliverChildListDelegate([
                            Row(
                              children: [
                                ProfileAvatar(
                                  name: profile.name,
                                  gender: profile.gender,
                                  imagePath: profile.avatarPath,
                                  radius: 28,
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${_greeting()},',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: scheme.onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                      ),
                                      Text(
                                        profile.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineSmall,
                                      ),
                                      if (user?.email != null)
                                        Text(
                                          user!.email,
                                          style: Theme.of(context)
                                              .textTheme
                                              .labelMedium
                                              ?.copyWith(
                                                color: scheme.onSurface
                                                    .withValues(alpha: 0.55),
                                              ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            BmiCard(
                              bmi: profile.bmi,
                              category: category,
                              subtitle: data.bmiTrendSentence,
                              weightLabel:
                                  '${weightDisplay.toStringAsFixed(1)} ${profile.weightUnit.label}',
                              heightLabel:
                                  '${heightDisplay.toStringAsFixed(1)} ${profile.heightUnit.label}',
                              lastUpdated: profile.updatedAt,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final gap = AppSpacing.md;
                                final tileWidth =
                                    (constraints.maxWidth - gap) / 2;
                                return Wrap(
                                  spacing: gap,
                                  runSpacing: gap,
                                  children: [
                                    SizedBox(
                                      width: tileWidth,
                                      child: StatTile(
                                        label: AppStrings.weightChange,
                                        value: changeDisplay == null
                                            ? 'n/a'
                                            : '${changeDisplay >= 0 ? '+' : ''}${changeDisplay.toStringAsFixed(1)} ${profile.weightUnit.label}',
                                        icon: Icons.swap_vert_rounded,
                                        deltaLabel: 'vs prior entry',
                                        deltaPositive:
                                            change == null ? null : change > 0,
                                      ),
                                    ),
                                    SizedBox(
                                      width: tileWidth,
                                      child: StatTile(
                                        label: AppStrings.bmiChange,
                                        value: data.weekStats.daysWithData < 2
                                            ? 'n/a'
                                            : '${data.weekStats.bmiChange >= 0 ? '+' : ''}${data.weekStats.bmiChange.toStringAsFixed(1)}',
                                        icon: Icons.trending_flat_rounded,
                                        deltaLabel: '7-day',
                                        deltaPositive:
                                            data.weekStats.daysWithData < 2
                                                ? null
                                                : data.weekStats.bmiChange > 0,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            WeightTrendChart(
                              history: data.history,
                              weightUnit: profile.weightUnit,
                            ),
                            if (data.weekStats.daysWithData >= 2) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'Weight moved from ${data.weekStats.startingWeightKg.toStringAsFixed(1)} kg to ${data.weekStats.currentWeightKg.toStringAsFixed(1)} kg over the last ${data.weekStats.daysWithData} recorded days.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.65),
                                    ),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            WeekStatsCard(
                              stats: data.weekStats,
                              weightUnit: profile.weightUnit,
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              'Quick actions',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.tonalIcon(
                                    onPressed: logging
                                        ? null
                                        : () => _updateMeasurement(
                                              context,
                                              ref,
                                              type: MeasurementType.weight,
                                            ),
                                    icon: const Icon(Icons.add_rounded),
                                    label: const Text(AppStrings.logWeight),
                                    style: FilledButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: logging
                                        ? null
                                        : () => _updateMeasurement(
                                              context,
                                              ref,
                                              type: MeasurementType.height,
                                            ),
                                    icon: const Icon(Icons.height_rounded),
                                    label: const Text('Update height'),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(48, 48),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                            OutlinedButton.icon(
                              onPressed: () => context.push('/export'),
                              icon: const Icon(Icons.ios_share_rounded),
                              label: const Text(AppStrings.exportData),
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            RecentHistoryList(
                              history: data.history,
                              heightCm: profile.heightCm,
                              weightUnit: profile.weightUnit,
                              onSeeAll: () => context.go('/history'),
                            ),
                            const SizedBox(height: AppSpacing.xxxl),
                          ]),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
