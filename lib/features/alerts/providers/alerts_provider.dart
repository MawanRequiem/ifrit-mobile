import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/alerts/data/alerts_repository.dart';
import 'package:agniraksha_mobile/features/alerts/domain/alert_model.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepository(ref.read(apiClientProvider));
});

/// Paginated alerts provider.
class AlertsState {
  final List<AlertModel> items;
  final int total;
  final int page;
  final bool isLoading;
  final String? severityFilter;

  const AlertsState({
    this.items = const [],
    this.total = 0,
    this.page = 1,
    this.isLoading = false,
    this.severityFilter,
  });

  AlertsState copyWith({
    List<AlertModel>? items,
    int? total,
    int? page,
    bool? isLoading,
    String? severityFilter,
  }) {
    return AlertsState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      severityFilter: severityFilter,
    );
  }
}

class AlertsNotifier extends StateNotifier<AlertsState> {
  final AlertsRepository _repo;

  AlertsNotifier(this._repo) : super(const AlertsState()) {
    fetchAlerts();
  }

  Future<void> fetchAlerts({bool reset = true}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true);
    final page = reset ? 1 : state.page + 1;

    try {
      final result = await _repo.fetchAlerts(
        page: page,
        severity: state.severityFilter,
        acknowledged: false, // Only show unacknowledged
      );

      state = state.copyWith(
        items: reset ? result.items : [...state.items, ...result.items],
        total: result.total,
        page: page,
        isLoading: false,
      );
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void setSeverityFilter(String? severity) {
    state = AlertsState(severityFilter: severity);
    fetchAlerts();
  }

  Future<void> acknowledge(String alertId) async {
    await _repo.acknowledgeAlert(alertId);
    state = state.copyWith(
      items: state.items.where((a) => a.id != alertId).toList(),
      total: state.total - 1,
    );
  }
}

final alertsProvider =
    StateNotifierProvider<AlertsNotifier, AlertsState>((ref) {
  return AlertsNotifier(ref.read(alertsRepositoryProvider));
});
