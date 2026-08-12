import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../models/enums.dart';
import '../models/profile_model.dart';
import '../models/user_model.dart';
import 'providers.dart';

/// Repository-backed profiles list used by UI screens.
class ProfilesController extends StateNotifier<AsyncValue<List<ProfileModel>>> {
  ProfilesController(this._ref) : super(const AsyncLoading()) {
    Future.microtask(refresh);
  }

  final Ref _ref;

  Future<void> refresh() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    if (user == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    try {
      final list =
          await _ref.read(profileRepositoryProvider).fetchProfiles(user.id);
      state = AsyncData(list);
      final selected = _ref.read(selectedProfileIdProvider);
      if (selected == null && list.isNotEmpty) {
        final primary = list.firstWhere(
          (p) => p.isPrimary,
          orElse: () => list.first,
        );
        _ref.read(selectedProfileIdProvider.notifier).state = primary.id;
        await _ref
            .read(profileRepositoryProvider)
            .setSelectedProfileId(primary.id);
      }
    } catch (e, st) {
      final cached =
          _ref.read(profileRepositoryProvider).getCachedProfiles(user.id);
      if (cached.isNotEmpty) {
        state = AsyncData(cached);
      } else {
        state = AsyncError(FailureMapper.fromObject(e), st);
      }
    }
  }

  Future<void> upsert(ProfileModel profile) async {
    try {
      final saved =
          await _ref.read(profileRepositoryProvider).saveProfile(profile);
      final list = <ProfileModel>[...(state.valueOrNull ?? [])];
      final index = list.indexWhere((p) => p.id == saved.id);
      if (index >= 0) {
        list[index] = saved;
      } else {
        list.add(saved);
      }
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
    }
  }

  Future<void> delete(String profileId) async {
    final list = state.valueOrNull ?? [];
    ProfileModel? match;
    for (final p in list) {
      if (p.id == profileId) match = p;
    }
    match ??= _ref.read(profileRepositoryProvider).getCachedProfile(profileId);
    if (match == null) return;
    try {
      await _ref.read(profileRepositoryProvider).deleteProfile(match);
      final next = [...list]..removeWhere((p) => p.id == profileId);
      state = AsyncData(next);
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
    }
  }

  Future<void> select(String profileId) async {
    _ref.read(selectedProfileIdProvider.notifier).state = profileId;
    await _ref.read(profileRepositoryProvider).setSelectedProfileId(profileId);
  }
}

final profilesProvider =
    StateNotifierProvider<ProfilesController, AsyncValue<List<ProfileModel>>>(
  (ref) {
    ref.listen(authStateProvider, (prev, next) {
      if (prev?.valueOrNull?.id != next.valueOrNull?.id) {
        ref.invalidateSelf();
      }
    });
    return ProfilesController(ref);
  },
);

final selectedProfileIdProvider = StateProvider<String?>((ref) {
  return ref.read(profileRepositoryProvider).getSelectedProfileId();
});

final selectedProfileProvider = Provider<ProfileModel?>((ref) {
  final profiles = ref.watch(profilesProvider).valueOrNull ?? [];
  final selectedId = ref.watch(selectedProfileIdProvider);
  if (profiles.isEmpty) return null;
  if (selectedId != null) {
    final match = profiles.where((p) => p.id == selectedId);
    if (match.isNotEmpty) return match.first;
  }
  final primary = profiles.where((p) => p.isPrimary);
  return primary.isNotEmpty ? primary.first : profiles.first;
});

final hasProfilesProvider = Provider<bool>((ref) {
  final profiles = ref.watch(profilesProvider).valueOrNull;
  if (profiles != null) return profiles.isNotEmpty;
  return ref.watch(profileRepositoryProvider).hasProfiles;
});

class ProfileFormState {
  const ProfileFormState({
    this.isLoading = false,
    this.failure,
    this.savedProfile,
  });

  final bool isLoading;
  final AppFailure? failure;
  final ProfileModel? savedProfile;

  ProfileFormState copyWith({
    bool? isLoading,
    AppFailure? failure,
    ProfileModel? savedProfile,
    bool clearFailure = false,
    bool clearSaved = false,
  }) {
    return ProfileFormState(
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      savedProfile: clearSaved ? null : (savedProfile ?? this.savedProfile),
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileFormState> {
  ProfileNotifier(this._ref) : super(const ProfileFormState());

  final Ref _ref;

  UserModel? get _user => _ref.read(authStateProvider).valueOrNull;

  Future<ProfileModel?> create({
    required String name,
    required Gender gender,
    required DateTime dateOfBirth,
    required double heightCm,
    required double weightKg,
    WeightUnit weightUnit = WeightUnit.kg,
    HeightUnit heightUnit = HeightUnit.cm,
    String? avatarPath,
    bool isPrimary = false,
  }) async {
    final user = _user;
    if (user == null) {
      state = state.copyWith(
        failure: const AuthFailure('Please sign in first.'),
      );
      return null;
    }

    state =
        state.copyWith(isLoading: true, clearFailure: true, clearSaved: true);
    try {
      final profile = await _ref.read(profileRepositoryProvider).createProfile(
            userId: user.id,
            name: name,
            gender: gender,
            dateOfBirth: dateOfBirth,
            heightCm: heightCm,
            weightKg: weightKg,
            weightUnit: weightUnit,
            heightUnit: heightUnit,
            avatarPath: avatarPath,
            isPrimary: isPrimary,
          );
      await _ref.read(profilesProvider.notifier).refresh();
      _ref.read(selectedProfileIdProvider.notifier).state = profile.id;
      state = state.copyWith(isLoading: false, savedProfile: profile);
      return profile;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return null;
    }
  }

  Future<ProfileModel?> update(ProfileModel profile) async {
    state =
        state.copyWith(isLoading: true, clearFailure: true, clearSaved: true);
    try {
      final updated =
          await _ref.read(profileRepositoryProvider).updateProfile(profile);
      await _ref.read(profilesProvider.notifier).refresh();
      state = state.copyWith(isLoading: false, savedProfile: updated);
      return updated;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return null;
    }
  }

  Future<bool> delete(ProfileModel profile) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      await _ref.read(profilesProvider.notifier).delete(profile.id);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return false;
    }
  }
}

final profileNotifierProvider =
    StateNotifierProvider<ProfileNotifier, ProfileFormState>((ref) {
  return ProfileNotifier(ref);
});
