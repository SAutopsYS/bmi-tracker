import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:bmi_tracker/core/validators/input_validators.dart';
import 'package:bmi_tracker/models/enums.dart';
import 'package:bmi_tracker/widgets/common/app_button.dart';
import 'package:bmi_tracker/widgets/common/app_text_field.dart';
import 'package:bmi_tracker/widgets/forms/unit_selector.dart';

enum MeasurementType { weight, height }

class MeasurementUpdateResult {
  const MeasurementUpdateResult({
    required this.type,
    required this.value,
    required this.weightUnit,
    required this.heightUnit,
  });

  final MeasurementType type;
  final double value;
  final WeightUnit weightUnit;
  final HeightUnit heightUnit;

  double get valueAsKg =>
      UnitConverter.toKg(value: value, isLbs: weightUnit.isLbs);

  double get valueAsCm =>
      UnitConverter.toCm(value: value, isInches: heightUnit.isInches);
}

/// Bottom sheet for updating weight or height with unit selectors.
Future<MeasurementUpdateResult?> showUpdateMeasurementSheet({
  required BuildContext context,
  required MeasurementType type,
  required double initialKg,
  required double initialCm,
  required WeightUnit weightUnit,
  required HeightUnit heightUnit,
}) {
  return showModalBottomSheet<MeasurementUpdateResult>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppSpacing.radiusXl),
      ),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: _UpdateMeasurementSheet(
          type: type,
          initialKg: initialKg,
          initialCm: initialCm,
          weightUnit: weightUnit,
          heightUnit: heightUnit,
        ),
      );
    },
  );
}

class _UpdateMeasurementSheet extends StatefulWidget {
  const _UpdateMeasurementSheet({
    required this.type,
    required this.initialKg,
    required this.initialCm,
    required this.weightUnit,
    required this.heightUnit,
  });

  final MeasurementType type;
  final double initialKg;
  final double initialCm;
  final WeightUnit weightUnit;
  final HeightUnit heightUnit;

  @override
  State<_UpdateMeasurementSheet> createState() =>
      _UpdateMeasurementSheetState();
}

class _UpdateMeasurementSheetState extends State<_UpdateMeasurementSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _controller;
  late WeightUnit _weightUnit = widget.weightUnit;
  late HeightUnit _heightUnit = widget.heightUnit;

  @override
  void initState() {
    super.initState();
    final initial = widget.type == MeasurementType.weight
        ? UnitConverter.fromKg(kg: widget.initialKg, toLbs: _weightUnit.isLbs)
        : UnitConverter.fromCm(
            cm: widget.initialCm,
            toInches: _heightUnit.isInches,
          );
    _controller = TextEditingController(text: initial.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final value = double.parse(_controller.text.trim());
    Navigator.of(context).pop(
      MeasurementUpdateResult(
        type: widget.type,
        value: value,
        weightUnit: _weightUnit,
        heightUnit: _heightUnit,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWeight = widget.type == MeasurementType.weight;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWeight ? 'Update weight' : 'Update height',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isWeight)
                WeightUnitSelector(
                  value: _weightUnit,
                  onChanged: (unit) {
                    final current = double.tryParse(_controller.text.trim());
                    setState(() {
                      if (current != null) {
                        final kg = UnitConverter.toKg(
                          value: current,
                          isLbs: _weightUnit.isLbs,
                        );
                        _weightUnit = unit;
                        _controller.text = UnitConverter.fromKg(
                          kg: kg,
                          toLbs: unit.isLbs,
                        ).toStringAsFixed(1);
                      } else {
                        _weightUnit = unit;
                      }
                    });
                  },
                )
              else
                HeightUnitSelector(
                  value: _heightUnit,
                  onChanged: (unit) {
                    final current = double.tryParse(_controller.text.trim());
                    setState(() {
                      if (current != null) {
                        final cm = UnitConverter.toCm(
                          value: current,
                          isInches: _heightUnit.isInches,
                        );
                        _heightUnit = unit;
                        _controller.text = UnitConverter.fromCm(
                          cm: cm,
                          toInches: unit.isInches,
                        ).toStringAsFixed(1);
                      } else {
                        _heightUnit = unit;
                      }
                    });
                  },
                ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                controller: _controller,
                label: isWeight ? 'Weight' : 'Height',
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                validator: (v) => isWeight
                    ? InputValidators.weight(v, isLbs: _weightUnit.isLbs)
                    : InputValidators.height(v, isInches: _heightUnit.isInches),
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                label: 'Save',
                onPressed: _submit,
                icon: Icons.check_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
