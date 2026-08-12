import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/models/enums.dart';

/// Segmented control for weight or height units.
class WeightUnitSelector extends StatelessWidget {
  const WeightUnitSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final WeightUnit value;
  final ValueChanged<WeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return _UnitSegmented<WeightUnit>(
      label: 'Weight unit',
      value: value,
      values: WeightUnit.values,
      labelFor: (u) => u.label,
      onChanged: onChanged,
    );
  }
}

class HeightUnitSelector extends StatelessWidget {
  const HeightUnitSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final HeightUnit value;
  final ValueChanged<HeightUnit> onChanged;

  @override
  Widget build(BuildContext context) {
    return _UnitSegmented<HeightUnit>(
      label: 'Height unit',
      value: value,
      values: HeightUnit.values,
      labelFor: (u) => u.label,
      onChanged: onChanged,
    );
  }
}

class _UnitSegmented<T extends Object> extends StatelessWidget {
  const _UnitSegmented({
    required this.label,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelFor;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              segments: values
                  .map(
                    (v) => ButtonSegment<T>(
                      value: v,
                      label: Text(labelFor(v)),
                    ),
                  )
                  .toList(),
              selected: {value},
              onSelectionChanged: (set) {
                if (set.isNotEmpty) onChanged(set.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
                visualDensity: VisualDensity.standard,
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
