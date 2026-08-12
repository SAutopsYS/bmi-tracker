import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';

/// Compact metric tile for weight/height/change stats.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.deltaLabel,
    this.deltaPositive,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final String? deltaLabel;
  final bool? deltaPositive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Color? deltaColor;
    IconData? deltaIcon;
    if (deltaPositive != null) {
      deltaColor = deltaPositive! ? scheme.tertiary : scheme.secondary;
      deltaIcon = deltaPositive!
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded;
    }

    final content = Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: scheme.primary),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface.withValues(alpha: 0.7),
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          if (deltaLabel != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                if (deltaIcon != null)
                  Icon(deltaIcon, size: 14, color: deltaColor),
                if (deltaIcon != null) const SizedBox(width: 2),
                Expanded(
                  child: Text(
                    deltaLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: deltaColor ??
                              scheme.onSurface.withValues(alpha: 0.65),
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Semantics(
          button: onTap != null,
          label: '$label $value${deltaLabel != null ? ', $deltaLabel' : ''}',
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 88),
            child: content,
          ),
        ),
      ),
    );
  }
}
