import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:bmi_tracker/core/constants/bmi_thresholds.dart';
import 'package:bmi_tracker/core/theme/app_colors.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/widgets/dashboard/bmi_gauge.dart';

/// Large BMI summary card with gauge, category text/icon, and vitals.
class BmiCard extends StatelessWidget {
  const BmiCard({
    super.key,
    required this.bmi,
    required this.category,
    this.subtitle,
    this.weightLabel,
    this.heightLabel,
    this.lastUpdated,
  });

  final double bmi;
  final BMICategory category;
  final String? subtitle;
  final String? weightLabel;
  final String? heightLabel;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = AppColors.colorForCategory(category);
    final hasBmi = bmi > 0;

    return Semantics(
      label: hasBmi
          ? 'Current BMI ${bmi.toStringAsFixed(1)}, ${category.label}'
          : 'BMI unavailable. Add height and weight to calculate.',
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        ),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.lg,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withValues(alpha: 0.12),
                scheme.surface,
              ],
            ),
          ),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Current BMI',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.75),
                      ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              if (!hasBmi)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Text(
                    'Add height and weight to see your BMI.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.7),
                        ),
                  ),
                )
              else ...[
                BmiGauge(bmi: bmi, category: category),
                if (weightLabel != null || heightLabel != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      if (weightLabel != null)
                        Expanded(
                          child: _VitalChip(
                            icon: Icons.monitor_weight_outlined,
                            label: 'Weight',
                            value: weightLabel!,
                          ),
                        ),
                      if (weightLabel != null && heightLabel != null)
                        const SizedBox(width: AppSpacing.md),
                      if (heightLabel != null)
                        Expanded(
                          child: _VitalChip(
                            icon: Icons.height_rounded,
                            label: 'Height',
                            value: heightLabel!,
                          ),
                        ),
                    ],
                  ),
                ],
                if (lastUpdated != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'Last updated ${DateFormat.yMMMd().add_jm().format(lastUpdated!)}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: scheme.onSurface.withValues(alpha: 0.55),
                        ),
                  ),
                ],
              ],
              if (subtitle != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.72),
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalChip extends StatelessWidget {
  const _VitalChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.85),
        borderRadius: AppSpacing.borderRadiusMd,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: scheme.primary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.65),
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
