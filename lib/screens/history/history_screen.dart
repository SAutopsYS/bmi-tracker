import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/core/theme/app_colors.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/utils/date_utils.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/common/empty_state.dart';
import 'package:bmi_tracker/widgets/common/error_view.dart';
import 'package:bmi_tracker/widgets/common/offline_banner.dart';
import 'package:bmi_tracker/widgets/common/skeleton_box.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  static const String routePath = '/history';
  static const String routeName = 'history';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historyProvider);
    final profile = ref.watch(selectedProfileProvider);
    final online = ref.watch(isOnlineNowProvider);
    final bmiService = ref.watch(bmiServiceProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.historyTitle)),
      body: Column(
        children: [
          if (!online) const OfflineBanner(),
          Expanded(
            child: historyAsync.when(
              loading: () => ListView.separated(
                padding: AppSpacing.screenPadding,
                itemCount: 6,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.md),
                itemBuilder: (_, __) => const SkeletonBox(
                    height: 72, borderRadius: AppSpacing.radiusLg),
              ),
              error: (e, _) => ErrorView(
                message: e.toString(),
                onRetry: () => ref.invalidate(historyProvider),
              ),
              data: (history) {
                if (profile == null || history.isEmpty) {
                  return const EmptyState(
                    title: AppStrings.noHistory,
                    message: AppStrings.noHistoryHint,
                    icon: Icons.timeline_outlined,
                  );
                }

                return ListView.separated(
                  padding: AppSpacing.screenPadding,
                  itemCount: history.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final prev = index + 1 < history.length
                        ? history[index + 1].weightKg
                        : null;
                    final display = UnitConverter.fromKg(
                      kg: entry.weightKg,
                      toLbs: profile.weightUnit.isLbs,
                    );
                    final bmi = bmiService.calculateBMIFromCm(
                      weightKg: entry.weightKg,
                      heightCm: profile.heightCm,
                    );
                    final category = bmiService.getBMICategory(bmi);
                    final color = AppColors.colorForCategory(category);
                    double? deltaKg;
                    if (prev != null) deltaKg = entry.weightKg - prev;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusLg),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.sm,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          foregroundColor: color,
                          child: Icon(AppColors.iconForCategory(category)),
                        ),
                        title: Text(
                          '${display.toStringAsFixed(1)} ${profile.weightUnit.label}',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${AppDateUtils.formatDateTime(entry.recordedAt)}\n'
                          'BMI ${bmi.toStringAsFixed(1)} · ${category.label}',
                        ),
                        isThreeLine: true,
                        trailing: deltaKg == null
                            ? Text(
                                'First',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(
                                      color: scheme.onSurface
                                          .withValues(alpha: 0.55),
                                    ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Icon(
                                    deltaKg >= 0
                                        ? Icons.arrow_upward_rounded
                                        : Icons.arrow_downward_rounded,
                                    size: 18,
                                    color: deltaKg >= 0
                                        ? scheme.tertiary
                                        : scheme.secondary,
                                  ),
                                  Text(
                                    '${deltaKg >= 0 ? '+' : ''}${UnitConverter.fromKg(kg: deltaKg, toLbs: profile.weightUnit.isLbs).toStringAsFixed(1)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelLarge
                                        ?.copyWith(
                                          color: deltaKg >= 0
                                              ? scheme.tertiary
                                              : scheme.secondary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
