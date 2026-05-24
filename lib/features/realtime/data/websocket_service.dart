import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:agniraksha_mobile/core/network/api_endpoints.dart';

/// Manages a persistent WebSocket connection to the AgniRakhsa backend
/// with automatic reconnection using exponential backoff.
class WebSocketService {
  WebSocketChannel? _channel;
  Timer? _reconnectTimer;
  Timer? _pingTimer;
  int _reconnectAttempts = 0;
  bool _disposed = false;

  final _controller = StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of parsed JSON messages from the server.
  Stream<Map<String, dynamic>> get stream => _controller.stream;

  /// Whether the WebSocket is currently connected.
  bool get isConnected => _channel != null;

  void connect() {
    if (_disposed) return;
    _reconnectAttempts = 0;
    _doConnect();
  }

  void _doConnect() {
    if (_disposed) return;

    try {
      final uri = Uri.parse(ApiEndpoints.wsUrl);
      _channel = WebSocketChannel.connect(uri);

      _channel!.stream.listen(
        (data) {
          _reconnectAttempts = 0;
          try {
            final parsed = jsonDecode(data as String) as Map<String, dynamic>;
            _controller.add(parsed);
          } catch (_) {
            // Ignore non-JSON messages
          }
        },
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: false,
      );

      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 25), (_) {
        try {
          _channel?.sink.add('ping');
        } catch (_) {}
      });
    } catch (_) {
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _channel = null;
    _pingTimer?.cancel();

    if (_disposed) return;

    final delay = Duration(
      seconds: _clamp(1 << _reconnectAttempts, 1, 30),
    );
    _reconnectAttempts++;

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(delay, _doConnect);
  }

  int _clamp(int value, int min, int max) {
    if (value < min) return min;
    if (value > max) return max;
    return value;
  }

  void disconnect() {
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  void dispose() {
    _disposed = true;
    disconnect();
    _controller.close();
  }
}
