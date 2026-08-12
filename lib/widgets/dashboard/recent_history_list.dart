import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/utils/date_utils.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:bmi_tracker/models/enums.dart';
import 'package:bmi_tracker/models/weight_history_model.dart';
import 'package:bmi_tracker/services/bmi_service.dart';

/// Compact recent weigh-in list for the dashboard.
class RecentHistoryList extends StatelessWidget {
  const RecentHistoryList({
    super.key,
    required this.history,
    required this.heightCm,
    required this.weightUnit,
    this.limit = 5,
    this.onSeeAll,
  });

  final List<WeightHistoryModel> history;
  final double heightCm;
  final WeightUnit weightUnit;
  final int limit;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bmiService = const BMICalculatorService();
    final items = history.take(limit).toList();

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Padding(
        padding: AppSpacing.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Recent history',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (onSeeAll != null)
                  TextButton(
                    onPressed: onSeeAll,
                    child: const Text('See all'),
                  ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Text(
                  'No entries yet. Log your weight to build history.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              )
            else
              ...List.generate(items.length, (index) {
                final entry = items[index];
                final prev = index + 1 < history.length
                    ? history[index + 1].weightKg
                    : null;
                final display = UnitConverter.fromKg(
                  kg: entry.weightKg,
                  toLbs: weightUnit.isLbs,
                );
                final bmi = bmiService.calculateBMIFromCm(
                  weightKg: entry.weightKg,
                  heightCm: heightCm,
                );
                double? delta;
                if (prev != null) {
                  delta = entry.weightKg - prev;
                }

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: AppSpacing.sm,
                  title: Text(
                    '${display.toStringAsFixed(1)} ${weightUnit.label}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  subtitle: Text(AppDateUtils.formatDateTime(entry.recordedAt)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'BMI ${bmi.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                      if (delta != null)
                        Text(
                          '${delta >= 0 ? '+' : ''}${UnitConverter.fromKg(kg: delta, toLbs: weightUnit.isLbs).toStringAsFixed(1)} ${weightUnit.label}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: delta >= 0
                                        ? scheme.tertiary
                                        : scheme.secondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
