import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:bmi_tracker/core/constants/app_strings.dart';
import 'package:bmi_tracker/core/theme/app_spacing.dart';
import 'package:bmi_tracker/core/utils/date_utils.dart';
import 'package:bmi_tracker/models/profile_model.dart';
import 'package:bmi_tracker/providers/providers.dart';
import 'package:bmi_tracker/widgets/common/empty_state.dart';
import 'package:bmi_tracker/widgets/common/error_view.dart';
import 'package:bmi_tracker/widgets/profile/profile_avatar.dart';

class ProfilesScreen extends ConsumerWidget {
  const ProfilesScreen({super.key});

  static const String routePath = '/profiles';
  static const String routeName = 'profiles';

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    ProfileModel profile,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(AppStrings.deleteProfile),
          content: Text(
            'Delete ${profile.name}? This removes only that profile and its health history. Your account and other profiles stay intact. This cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(AppStrings.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text(AppStrings.delete),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;
    await ref.read(profilesProvider.notifier).delete(profile.id);
    final remaining = ref.read(profilesProvider).valueOrNull ?? [];
    final selectedId = ref.read(selectedProfileIdProvider);
    if (selectedId == profile.id || selectedId == null) {
      if (remaining.isNotEmpty) {
        await ref.read(profilesProvider.notifier).select(remaining.first.id);
      } else {
        ref.read(selectedProfileIdProvider.notifier).state = null;
      }
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.profileDeleted)),
    );
    if (remaining.isEmpty) {
      context.go('/profile-setup');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(profilesProvider);
    final selectedId = ref.watch(selectedProfileIdProvider);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.profilesTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/profile-form'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text(AppStrings.addProfile),
      ),
      body: profilesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.read(profilesProvider.notifier).refresh(),
        ),
        data: (profiles) {
          if (profiles.isEmpty) {
            return EmptyState(
              title: 'No profiles yet',
              message: AppStrings.noProfiles,
              icon: Icons.people_outline_rounded,
              actionLabel: AppStrings.addProfile,
              onAction: () => context.push('/profile-form'),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              96,
            ),
            itemCount: profiles.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final profile = profiles[index];
              final selected = profile.id == selectedId ||
                  (selectedId == null && profile.isPrimary);

              return Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  side: selected
                      ? BorderSide(color: scheme.primary, width: 1.5)
                      : BorderSide.none,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                  onTap: () {
                    ref.read(profilesProvider.notifier).select(profile.id);
                  },
                  child: Padding(
                    padding: AppSpacing.cardPadding,
                    child: Row(
                      children: [
                        ProfileAvatar(
                          name: profile.name,
                          gender: profile.gender,
                          imagePath: profile.avatarPath,
                          radius: 28,
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      profile.name,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                    ),
                                  ),
                                  if (profile.isPrimary)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: AppSpacing.sm,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: scheme.primaryContainer,
                                        borderRadius: AppSpacing.borderRadiusSm,
                                      ),
                                      child: Text(
                                        AppStrings.primaryProfile,
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: scheme.onPrimaryContainer,
                                              fontWeight: FontWeight.w700,
                                            ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                '${profile.gender.label} · Age ${AppDateUtils.ageFromDob(profile.dateOfBirth)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              Text(
                                'BMI ${profile.bmi.toStringAsFixed(1)}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: scheme.primary),
                              ),
                              if (selected)
                                Text(
                                  'Active',
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                        color: scheme.secondary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                ),
                            ],
                          ),
                        ),
                        PopupMenuButton<String>(
                          tooltip: 'Profile actions',
                          onSelected: (value) {
                            switch (value) {
                              case 'edit':
                                context.push(
                                  '/profile-form?id=${profile.id}',
                                );
                              case 'delete':
                                _confirmDelete(context, ref, profile);
                            }
                          },
                          itemBuilder: (context) => const [
                            PopupMenuItem(
                              value: 'edit',
                              child: Text(AppStrings.editProfile),
                            ),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(AppStrings.deleteProfile),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
