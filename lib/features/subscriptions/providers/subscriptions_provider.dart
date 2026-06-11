import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/core/network/api_client.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/features/subscriptions/data/subscriptions_repository.dart';

final subscriptionsRepositoryProvider = Provider<SubscriptionsRepository>((ref) {
  return SubscriptionsRepository(ref.read(apiClientProvider));
});

/// State for subscription management.
class SubscriptionsState {
  final List<AvailableRoom> availableRooms;
  final Set<String> subscribedRoomIds;
  final bool isLoading;
  final String? error;

  const SubscriptionsState({
    this.availableRooms = const [],
    this.subscribedRoomIds = const {},
    this.isLoading = false,
    this.error,
  });

  SubscriptionsState copyWith({
    List<AvailableRoom>? availableRooms,
    Set<String>? subscribedRoomIds,
    bool? isLoading,
    String? error,
  }) {
    return SubscriptionsState(
      availableRooms: availableRooms ?? this.availableRooms,
      subscribedRoomIds: subscribedRoomIds ?? this.subscribedRoomIds,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SubscriptionsNotifier extends StateNotifier<SubscriptionsState> {
  final SubscriptionsRepository _repo;

  SubscriptionsNotifier(this._repo) : super(const SubscriptionsState());

  /// Loads available rooms from the API.
  Future<void> loadAvailableRooms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final rooms = await _repo.fetchAvailableRooms();
      final subscribedIds = rooms
          .where((r) => r.isSubscribed)
          .map((r) => r.roomId)
          .toSet();

      state = SubscriptionsState(
        availableRooms: rooms,
        subscribedRoomIds: subscribedIds,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Toggles subscription status for a room (optimistic UI).
  void toggleRoom(String roomId) {
    final current = Set<String>.from(state.subscribedRoomIds);
    if (current.contains(roomId)) {
      current.remove(roomId);
    } else {
      current.add(roomId);
    }
    state = state.copyWith(subscribedRoomIds: current);
  }

  /// Saves the current subscription selections to the API.
  Future<bool> saveSubscriptions() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final roomIds = state.subscribedRoomIds.toList();
      await _repo.updateSubscriptions(roomIds);

      // Refresh the list to get updated is_subscribed flags
      final rooms = await _repo.fetchAvailableRooms();
      final subscribedIds = rooms
          .where((r) => r.isSubscribed)
          .map((r) => r.roomId)
          .toSet();

      state = SubscriptionsState(
        availableRooms: rooms,
        subscribedRoomIds: subscribedIds,
        isLoading: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }
}

final subscriptionsProvider =
    StateNotifierProvider<SubscriptionsNotifier, SubscriptionsState>((ref) {
  return SubscriptionsNotifier(ref.read(subscriptionsRepositoryProvider));
});