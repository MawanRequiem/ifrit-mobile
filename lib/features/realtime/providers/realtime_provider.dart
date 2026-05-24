import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/realtime/data/websocket_service.dart';

/// Singleton WebSocket service provider.
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();

  // Auto-connect when the provider is first read
  service.connect();

  // Cleanup on dispose
  ref.onDispose(() => service.dispose());

  return service;
});

/// Stream of real-time telemetry events from the WebSocket.
final realtimeEventsProvider = StreamProvider<Map<String, dynamic>>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.stream;
});
