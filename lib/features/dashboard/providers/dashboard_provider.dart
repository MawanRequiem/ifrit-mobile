import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/dashboard/data/dashboard_repository.dart';
import 'package:agniraksha_mobile/features/dashboard/domain/dashboard_models.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(apiClientProvider));
});

/// Auto-refreshing dashboard state.
final dashboardProvider =
    AsyncNotifierProvider<DashboardNotifier, DashboardSummary>(
  DashboardNotifier.new,
);

class DashboardNotifier extends AsyncNotifier<DashboardSummary> {
  Timer? _pollTimer;

  @override
  Future<DashboardSummary> build() async {
    // Start polling every 10 seconds
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) => _refresh());

    // Cancel timer on dispose
    ref.onDispose(() => _pollTimer?.cancel());

    return ref.read(dashboardRepositoryProvider).fetchSummary();
  }

  Future<void> _refresh() async {
    try {
      final data = await ref.read(dashboardRepositoryProvider).fetchSummary();
      state = AsyncData(data);
    } catch (_) {
      // Silently fail on poll — keep stale data
    }
  }

  Future<void> manualRefresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dashboardRepositoryProvider).fetchSummary(),
    );
  }
}
