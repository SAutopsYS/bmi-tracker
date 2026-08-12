import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/utils/date_utils.dart';
import 'package:bmi_tracker/core/utils/unit_converter.dart';
import 'package:bmi_tracker/core/validators/input_validators.dart';
import 'package:bmi_tracker/models/enums.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/common/app_button.dart';
import 'package:bmi_tracker/widgets/common/app_text_field.dart';
import 'package:bmi_tracker/widgets/forms/gender_selector.dart';
import 'package:bmi_tracker/widgets/forms/unit_selector.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  static const String routePath = '/profile-setup';
  static const String routeName = 'profileSetup';

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _weight = TextEditingController();
  final _height = TextEditingController();

  WeightUnit _weightUnit = WeightUnit.kg;
  HeightUnit _heightUnit = HeightUnit.cm;
  Gender _gender = Gender.preferNotToSay;
  DateTime? _dob;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _weight.dispose();
    _height.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(now.year - 25),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: AppStrings.dateOfBirthLabel,
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final dobError = InputValidators.dateOfBirth(_dob);
    if (dobError != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(dobError)));
      return;
    }

    setState(() => _saving = true);
    try {
      final weightKg = UnitConverter.toKg(
        value: double.parse(_weight.text.trim()),
        isLbs: _weightUnit.isLbs,
      );
      final heightCm = UnitConverter.toCm(
        value: double.parse(_height.text.trim()),
        isInches: _heightUnit.isInches,
      );

      final created = await ref.read(profileNotifierProvider.notifier).create(
            name: _name.text.trim(),
            gender: _gender,
            dateOfBirth: _dob!,
            heightCm: heightCm,
            weightKg: weightKg,
            weightUnit: _weightUnit,
            heightUnit: _heightUnit,
            isPrimary: true,
          );
      if (!mounted) return;
      if (created != null) {
        context.go('/home');
      } else {
        final failure = ref.read(profileNotifierProvider).failure;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(failure?.message ?? AppStrings.errorGeneric),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profileSetupTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Form(
                key: _formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppStrings.profileSetupSubtitle,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.72),
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppTextField(
                      controller: _name,
                      label: AppStrings.nameLabel,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                      prefixIcon: Icons.badge_outlined,
                      validator: InputValidators.name,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    WeightUnitSelector(
                      value: _weightUnit,
                      onChanged: (u) => setState(() => _weightUnit = u),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _weight,
                      label: '${AppStrings.weightLabel} (${_weightUnit.label})',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      prefixIcon: Icons.monitor_weight_outlined,
                      validator: (v) => InputValidators.weight(
                        v,
                        isLbs: _weightUnit.isLbs,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    HeightUnitSelector(
                      value: _heightUnit,
                      onChanged: (u) => setState(() => _heightUnit = u),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppTextField(
                      controller: _height,
                      label: '${AppStrings.heightLabel} (${_heightUnit.label})',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      prefixIcon: Icons.height_rounded,
                      validator: (v) => InputValidators.height(
                        v,
                        isInches: _heightUnit.isInches,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    GenderSelector(
                      value: _gender,
                      onChanged: (g) => setState(() => _gender = g),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Text(
                      AppStrings.dateOfBirthLabel,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    OutlinedButton.icon(
                      onPressed: _pickDob,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(48, 52),
                        alignment: Alignment.centerLeft,
                      ),
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(
                        _dob == null
                            ? 'Select date of birth'
                            : AppDateUtils.formatDate(_dob!),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppButton(
                      label: AppStrings.continueLabel,
                      onPressed: _saving ? null : _save,
                      isLoading: _saving,
                      icon: Icons.arrow_forward_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
