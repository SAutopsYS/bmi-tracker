import 'package:flutter/material.dart';

import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/models/profile_model.dart';
import 'package:bmi_tracker/widgets/profile/profile_avatar.dart';

/// Chip that shows the active profile and opens a switcher sheet.
class ProfileSwitcher extends StatelessWidget {
  const ProfileSwitcher({
    super.key,
    required this.profiles,
    required this.selected,
    required this.onSelected,
  });

  final List<ProfileModel> profiles;
  final ProfileModel? selected;
  final ValueChanged<ProfileModel> onSelected;

  Future<void> _openSheet(BuildContext context) async {
    if (profiles.isEmpty) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.radiusXl),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Text(
                  'Switch profile',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              ...profiles.map((profile) {
                final isSelected = selected?.id == profile.id;
                return ListTile(
                  leading: ProfileAvatar(
                    name: profile.name,
                    gender: profile.gender,
                    imagePath: profile.avatarPath,
                  ),
                  title: Text(profile.name),
                  subtitle: Text(
                    profile.isPrimary
                        ? 'Primary profile'
                        : profile.gender.label,
                  ),
                  trailing: isSelected
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    onSelected(profile);
                    Navigator.of(context).pop();
                  },
                );
              }),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final name = selected?.name ?? 'No profile';

    return Semantics(
      button: true,
      label: 'Active profile $name. Double tap to switch.',
      child: ActionChip(
        avatar: selected == null
            ? Icon(Icons.person_outline, color: scheme.primary)
            : ProfileAvatar(
                name: selected!.name,
                gender: selected!.gender,
                imagePath: selected!.avatarPath,
                radius: 12,
              ),
        label: Text(name),
        onPressed: profiles.isEmpty ? null : () => _openSheet(context),
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.35)),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      ),
    );
  }
}
