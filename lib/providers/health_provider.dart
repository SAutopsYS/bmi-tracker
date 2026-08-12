import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/errors/app_failure.dart';
import '../models/bmi_record_model.dart';
import '../models/weight_history_model.dart';
import 'providers.dart';

/// Repository-backed weight history for the selected profile.
class HistoryController
    extends StateNotifier<AsyncValue<List<WeightHistoryModel>>> {
  HistoryController(this._ref) : super(const AsyncData([])) {
    Future.microtask(refresh);
  }

  final Ref _ref;

  Future<void> refresh() async {
    final user = _ref.read(authStateProvider).valueOrNull;
    final profile = _ref.read(selectedProfileProvider);
    if (user == null || profile == null) {
      state = const AsyncData([]);
      return;
    }
    state = const AsyncLoading();
    try {
      final list = await _ref.read(healthRepositoryProvider).fetchHistory(
            userId: user.id,
            profileId: profile.id,
          );
      state = AsyncData(list);
    } catch (e, st) {
      final cached = _ref.read(healthRepositoryProvider).getCachedHistory(
            userId: user.id,
            profileId: profile.id,
          );
      if (cached.isNotEmpty) {
        state = AsyncData(cached);
      } else {
        state = AsyncError(FailureMapper.fromObject(e), st);
      }
    }
  }

  Future<void> setAll(List<WeightHistoryModel> items) async {
    final sorted = [...items]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    state = AsyncData(sorted);
  }

  Future<void> add(WeightHistoryModel entry) async {
    final profile = _ref.read(selectedProfileProvider);
    if (profile == null) return;
    try {
      final saved = await _ref.read(healthRepositoryProvider).logWeight(
            profile: profile,
            weightKg: entry.weightKg,
            recordedAt: entry.recordedAt,
            note: entry.note,
          );
      final list = <WeightHistoryModel>[saved, ...(state.valueOrNull ?? [])]
        ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      state = AsyncData(list);
      await _ref.read(profilesProvider.notifier).refresh();
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
    }
  }

  Future<void> delete(String id) async {
    final list = state.valueOrNull ?? [];
    WeightHistoryModel? match;
    for (final e in list) {
      if (e.id == id) match = e;
    }
    if (match == null) return;
    try {
      await _ref.read(healthRepositoryProvider).deleteEntry(match);
      final next = [...list]..removeWhere((e) => e.id == id);
      state = AsyncData(next);
    } catch (e, st) {
      state = AsyncError(FailureMapper.fromObject(e), st);
    }
  }
}

final historyProvider = StateNotifierProvider<HistoryController,
    AsyncValue<List<WeightHistoryModel>>>((ref) {
  ref.listen(selectedProfileIdProvider, (prev, next) {
    if (prev != next) ref.invalidateSelf();
  });
  return HistoryController(ref);
});

final weightHistoryProvider =
    FutureProvider.family<List<WeightHistoryModel>, String>(
        (ref, profileId) async {
  final auth = ref.watch(authStateProvider).valueOrNull;
  if (auth == null) return [];
  return ref.read(healthRepositoryProvider).fetchHistory(
        userId: auth.id,
        profileId: profileId,
      );
});

final selectedHistoryProvider = Provider<List<WeightHistoryModel>>((ref) {
  return ref.watch(historyProvider).valueOrNull ?? [];
});

final bmiRecordsProvider = Provider<List<BmiRecordModel>>((ref) {
  final profile = ref.watch(selectedProfileProvider);
  final history = ref.watch(selectedHistoryProvider);
  if (profile == null) return [];
  return ref.read(healthRepositoryProvider).buildBmiRecords(
        profile: profile,
        history: history,
      );
});

final sevenDayStatsProvider = Provider<SevenDayStatistics>((ref) {
  final profile = ref.watch(selectedProfileProvider);
  final history = ref.watch(selectedHistoryProvider);
  if (profile == null) return SevenDayStatistics.empty;
  return ref.read(healthRepositoryProvider).sevenDayStats(
        profile: profile,
        history: history,
      );
});

final dashboardProvider = Provider<AsyncValue<DashboardData?>>((ref) {
  final profileAsync = ref.watch(profilesProvider);
  final historyAsync = ref.watch(historyProvider);
  final profile = ref.watch(selectedProfileProvider);
  final bmi = ref.watch(bmiServiceProvider);

  if (profileAsync.isLoading || historyAsync.isLoading) {
    return const AsyncLoading();
  }
  if (profileAsync.hasError) {
    return AsyncError(profileAsync.error!, profileAsync.stackTrace!);
  }
  if (historyAsync.hasError) {
    return AsyncError(historyAsync.error!, historyAsync.stackTrace!);
  }
  if (profile == null) return const AsyncData(null);

  final history = historyAsync.valueOrNull ?? [];
  final week = bmi.sevenDayStatistics(
    history: history,
    heightCm: profile.heightCm,
  );

  String trend;
  if (week.daysWithData < 2) {
    trend = 'Log a few more weigh-ins this week to see your BMI trend.';
  } else if (week.bmiChange.abs() < 0.1) {
    trend = 'Your BMI has stayed steady over the past 7 days.';
  } else if (week.bmiChange > 0) {
    trend =
        'Your BMI moved up by ${week.bmiChange.abs().toStringAsFixed(1)} over the past 7 days.';
  } else {
    trend =
        'Your BMI moved down by ${week.bmiChange.abs().toStringAsFixed(1)} over the past 7 days.';
  }

  final previous = history.length > 1 ? history[1].weightKg : null;

  return AsyncData(
    DashboardData(
      profile: profile,
      history: history,
      weekStats: week,
      bmiTrendSentence: trend,
      previousWeightKg: previous,
    ),
  );
});

final pendingSyncCountProvider = Provider<int>((ref) {
  final local = ref.watch(localStorageServiceProvider);
  return local.getSyncQueue().length;
});

class HealthActionState {
  const HealthActionState({
    this.isLoading = false,
    this.failure,
    this.message,
  });

  final bool isLoading;
  final AppFailure? failure;
  final String? message;

  HealthActionState copyWith({
    bool? isLoading,
    AppFailure? failure,
    String? message,
    bool clearFailure = false,
    bool clearMessage = false,
  }) {
    return HealthActionState(
      isLoading: isLoading ?? this.isLoading,
      failure: clearFailure ? null : (failure ?? this.failure),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

class HealthNotifier extends StateNotifier<HealthActionState> {
  HealthNotifier(this._ref) : super(const HealthActionState());

  final Ref _ref;

  Future<bool> logWeight({
    required double weightKg,
    DateTime? recordedAt,
    String? note,
  }) async {
    if (state.isLoading) {
      // Prevent duplicate history from rapid double taps.
      return false;
    }

    final profile = _ref.read(selectedProfileProvider);
    if (profile == null) {
      state = state.copyWith(
        failure: const ValidationFailure('Select a profile first.'),
      );
      return false;
    }

    if (weightKg.isNaN || weightKg.isInfinite || weightKg <= 0) {
      state = state.copyWith(
        failure:
            const ValidationFailure('Enter a valid weight greater than zero.'),
      );
      return false;
    }

    state =
        state.copyWith(isLoading: true, clearFailure: true, clearMessage: true);
    try {
      await _ref.read(healthRepositoryProvider).logWeight(
            profile: profile,
            weightKg: weightKg,
            recordedAt: recordedAt,
            note: note,
          );
      await _ref.read(historyProvider.notifier).refresh();
      await _ref.read(profilesProvider.notifier).refresh();
      state = state.copyWith(isLoading: false, message: 'Weight logged.');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return false;
    }
  }

  Future<bool> deleteEntry(WeightHistoryModel entry) async {
    state = state.copyWith(isLoading: true, clearFailure: true);
    try {
      await _ref.read(historyProvider.notifier).delete(entry.id);
      state = state.copyWith(isLoading: false, message: 'Entry deleted.');
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        failure: FailureMapper.fromObject(e),
      );
      return false;
    }
  }

  Future<bool> exportSelectedProfile() async {
    final profile = _ref.read(selectedProfileProvider);
    if (profile == null) {
      state = state.copyWith(
        failure: const ValidationFailure('Select a profile first.'),
      );
      return false;
    }

    state =
        state.copyWith(isLoading: true, clearFailure: true, clearMessage: true);
    try {
      final history = _ref.read(historyProvider).valueOrNull ?? [];
      await _ref.read(healthRepositoryProvider).exportCsv(
            profile: profile,
            history: history,
          );
      state = state.copyWith(
        isLoading: false,
        message: 'Export ready to share.',
      );
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

final healthNotifierProvider =
    StateNotifierProvider<HealthNotifier, HealthActionState>((ref) {
  return HealthNotifier(ref);
});
