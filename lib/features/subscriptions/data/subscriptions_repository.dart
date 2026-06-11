import 'package:agniraksha_mobile/core/network/api_client.dart';
import 'package:agniraksha_mobile/core/network/api_endpoints.dart';

/// Represents a room with subscription status.
class AvailableRoom {
  final String roomId;
  final String roomName;
  final bool isSubscribed;

  const AvailableRoom({
    required this.roomId,
    required this.roomName,
    required this.isSubscribed,
  });

  factory AvailableRoom.fromJson(Map<String, dynamic> json) {
    return AvailableRoom(
      roomId: json['room_id'] as String,
      roomName: (json['room_name'] as String?) ?? 'Unknown Room',
      isSubscribed: json['is_subscribed'] as bool? ?? false,
    );
  }
}

/// Represents a subscribed room (minimal info from GET /user/room-subscriptions).
class SubscribedRoom {
  final String roomId;
  final String roomName;

  const SubscribedRoom({
    required this.roomId,
    required this.roomName,
  });

  factory SubscribedRoom.fromJson(Map<String, dynamic> json) {
    return SubscribedRoom(
      roomId: json['room_id'] as String,
      roomName: (json['room_name'] as String?) ?? 'Unknown Room',
    );
  }
}

class SubscriptionsRepository {
  final ApiClient _client;

  SubscriptionsRepository(this._client);

  /// Fetches the list of rooms the user is currently subscribed to.
  Future<List<SubscribedRoom>> fetchSubscribedRooms() async {
    final res = await _client.dio.get(ApiEndpoints.roomSubscriptions);
    final list = res.data as List<dynamic>;
    return list
        .map((e) => SubscribedRoom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetches all available rooms with their subscription status.
  Future<List<AvailableRoom>> fetchAvailableRooms() async {
    final res = await _client.dio.get(ApiEndpoints.availableRooms);
    final list = res.data as List<dynamic>;
    return list
        .map((e) => AvailableRoom.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Updates the user's room subscriptions.
  Future<void> updateSubscriptions(List<String> roomIds) async {
    await _client.dio.post(
      ApiEndpoints.roomSubscriptions,
      data: {'room_ids': roomIds},
    );
  }
}