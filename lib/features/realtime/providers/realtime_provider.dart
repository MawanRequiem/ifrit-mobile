import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/realtime/data/websocket_service.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';
import 'package:agniraksha_mobile/features/subscriptions/providers/subscriptions_provider.dart';

/// Singleton WebSocket service provider.
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();

  // Auto-connect when the provider is first read
  service.connect();

  // Cleanup on dispose
  ref.onDispose(() => service.dispose());

  return service;
});

/// Raw stream of real-time telemetry events from the WebSocket.
final realtimeEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.stream;
});

/// Filtered stream: basic users only receive alerts for subscribed rooms.
/// Admin users receive all alerts unchanged.
final filteredRealtimeEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final rawStream = ref.watch(webSocketServiceProvider).stream;
  final auth = ref.watch(authProvider);

  // Admins see everything
  if (auth.user?.role == 'admin') {
    return rawStream;
  }

  // Basic users see only subscribed rooms
  final subState = ref.watch(subscriptionsProvider);
  final subscribedIds = subState.subscribedRoomIds;

  return rawStream.where((msg) {
    final data = msg['data'] as Map<String, dynamic>?;
    final roomId = data?['room_id'] as String?;
    return roomId != null && subscribedIds.contains(roomId);
  });
});
