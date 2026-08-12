import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:bmi_tracker/models/enums.dart';
import 'package:bmi_tracker/services/bmi_service.dart';

/// Seven-day overview metrics card with honest coverage messaging.
class WeekStatsCard extends StatelessWidget {
  const WeekStatsCard({
    super.key,
    required this.stats,
    required this.weightUnit,
  });

  final SevenDayStatistics stats;
  final WeightUnit weightUnit;

  String _fmtWeight(double kg) {
    final value = UnitConverter.fromKg(kg: kg, toLbs: weightUnit.isLbs);
    return '${value.toStringAsFixed(1)} ${weightUnit.label}';
  }

  String _fmtDeltaWeight(double kg) {
    final value = UnitConverter.fromKg(kg: kg.abs(), toLbs: weightUnit.isLbs);
    final sign = kg > 0 ? '+' : (kg < 0 ? '−' : '');
    return '$sign${value.toStringAsFixed(1)} ${weightUnit.label}';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (stats.daysWithData == 0) {
      return Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        child: Padding(
          padding: AppSpacing.cardPadding,
          child: Text(
            'No weigh-ins in the last 7 days yet. Log today to start your overview.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.72),
                ),
          ),
        ),
      );
    }

    final items = [
      _Stat('Starting weight', _fmtWeight(stats.startingWeightKg)),
      _Stat('Current weight', _fmtWeight(stats.currentWeightKg)),
      _Stat('Weight change', _fmtDeltaWeight(stats.weightChangeKg)),
      _Stat('Average weight', _fmtWeight(stats.averageWeightKg)),
      _Stat('Highest weight', _fmtWeight(stats.maxWeightKg)),
      _Stat('Lowest weight', _fmtWeight(stats.minWeightKg)),
      _Stat('Starting BMI', stats.startingBmi.toStringAsFixed(1)),
      _Stat('Current BMI', stats.currentBmi.toStringAsFixed(1)),
      _Stat(
        'BMI change',
        '${stats.bmiChange >= 0 ? '+' : ''}${stats.bmiChange.toStringAsFixed(1)}',
      ),
    ];

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
                    '7-day overview',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Semantics(
                  label: stats.coverageLabel,
                  child: Text(
                    stats.coverageLabel,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 360;
                return Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.md,
                  children: items.map((item) {
                    final width = wide
                        ? (constraints.maxWidth - AppSpacing.md) / 2
                        : constraints.maxWidth;
                    return SizedBox(
                      width: width,
                      child: _WeekStatChip(item: item),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat {
  const _Stat(this.label, this.value);
  final String label;
  final String value;
}

class _WeekStatChip extends StatelessWidget {
  const _WeekStatChip({required this.item});
  final _Stat item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.55),
        borderRadius: AppSpacing.borderRadiusMd,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              item.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.7),
                  ),
            ),
          ),
          Text(
            item.value,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
