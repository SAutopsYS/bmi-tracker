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
import 'package:bmi_tracker/models/profile_model.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/common/app_button.dart';
import 'package:bmi_tracker/widgets/common/app_text_field.dart';
import 'package:bmi_tracker/widgets/forms/gender_selector.dart';
import 'package:bmi_tracker/widgets/forms/unit_selector.dart';

class ProfileFormScreen extends ConsumerStatefulWidget {
  const ProfileFormScreen({super.key, this.profileId, this.existing});

  final String? profileId;
  final ProfileModel? existing;

  static const String routePath = '/profile-form';
  static const String routeName = 'profileForm';

  @override
  ConsumerState<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends ConsumerState<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _weight;
  late final TextEditingController _height;

  late WeightUnit _weightUnit;
  late HeightUnit _heightUnit;
  late Gender _gender;
  DateTime? _dob;
  bool _isPrimary = false;
  bool _initialized = false;

  ProfileModel? get _existing {
    if (widget.existing != null) return widget.existing;
    final id = widget.profileId;
    if (id == null) return null;
    final profiles = ref.read(profilesProvider).valueOrNull ?? [];
    for (final p in profiles) {
      if (p.id == id) return p;
    }
    return null;
  }

  bool get _isEditing => widget.profileId != null || widget.existing != null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _weight = TextEditingController();
    _height = TextEditingController();
    _weightUnit = WeightUnit.kg;
    _heightUnit = HeightUnit.cm;
    _gender = Gender.preferNotToSay;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final p = _existing;
    if (p != null) {
      _name.text = p.name;
      _weightUnit = p.weightUnit;
      _heightUnit = p.heightUnit;
      _gender = p.gender;
      _dob = p.dateOfBirth;
      _isPrimary = p.isPrimary;
      _weight.text = UnitConverter.fromKg(
        kg: p.weightKg,
        toLbs: _weightUnit.isLbs,
      ).toStringAsFixed(1);
      _height.text = UnitConverter.fromCm(
        cm: p.heightCm,
        toInches: _heightUnit.isInches,
      ).toStringAsFixed(1);
    }
  }

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

    final weightKg = UnitConverter.toKg(
      value: double.parse(_weight.text.trim()),
      isLbs: _weightUnit.isLbs,
    );
    final heightCm = UnitConverter.toCm(
      value: double.parse(_height.text.trim()),
      isInches: _heightUnit.isInches,
    );

    final existing = _existing;
    ProfileModel? saved;
    if (existing == null) {
      saved = await ref.read(profileNotifierProvider.notifier).create(
            name: _name.text.trim(),
            gender: _gender,
            dateOfBirth: _dob!,
            heightCm: heightCm,
            weightKg: weightKg,
            weightUnit: _weightUnit,
            heightUnit: _heightUnit,
            isPrimary: _isPrimary,
          );
    } else {
      final bmi = ref.read(bmiServiceProvider).calculateBMIFromCm(
            weightKg: weightKg,
            heightCm: heightCm,
          );
      saved = await ref.read(profileNotifierProvider.notifier).update(
            existing.copyWith(
              name: _name.text.trim(),
              gender: _gender,
              dateOfBirth: _dob!,
              heightCm: heightCm,
              weightKg: weightKg,
              weightUnit: _weightUnit,
              heightUnit: _heightUnit,
              bmi: bmi,
              isPrimary: _isPrimary || existing.isPrimary,
              updatedAt: DateTime.now(),
              syncStatus: SyncStatus.pending,
            ),
          );
    }

    if (!mounted) return;
    if (saved != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.profileSaved)),
      );
      context.pop();
    } else {
      final failure = ref.read(profileNotifierProvider).failure;
      if (failure != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final saving = ref.watch(profileNotifierProvider).isLoading;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? AppStrings.editProfile : AppStrings.addProfile,
        ),
      ),
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
                    AppTextField(
                      controller: _name,
                      label: AppStrings.nameLabel,
                      textCapitalization: TextCapitalization.words,
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
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
                    const SizedBox(height: AppSpacing.lg),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(AppStrings.setAsPrimary),
                      value: _isPrimary,
                      onChanged: (v) => setState(() => _isPrimary = v),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    AppButton(
                      label: AppStrings.saveProfile,
                      onPressed: saving ? null : _save,
                      isLoading: saving,
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
