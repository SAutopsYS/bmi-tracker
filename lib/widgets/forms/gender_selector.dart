import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/models/enums.dart';

/// Accessible gender segmented selector.
class GenderSelector extends StatelessWidget {
  const GenderSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final Gender value;
  final ValueChanged<Gender> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Gender',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Gender', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: Gender.values.map((gender) {
              final selected = gender == value;
              return ChoiceChip(
                label: Text(gender.label),
                selected: selected,
                onSelected: (_) => onChanged(gender),
                showCheckmark: false,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                labelPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
