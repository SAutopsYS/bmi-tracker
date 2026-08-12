import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

/// Emits true when the device appears online.
final connectivityStreamProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.onConnectivityChanged;
});

/// Async online flag for screens using `.valueOrNull`.
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  yield service.isOnline;
  yield* service.onConnectivityChanged;
});

final isOnlineNowProvider = Provider<bool>((ref) {
  final async = ref.watch(isOnlineProvider);
  return async.when(
    data: (online) => online,
    loading: () => ref.watch(connectivityServiceProvider).isOnline,
    error: (_, __) => ref.watch(connectivityServiceProvider).isOnline,
  );
});
