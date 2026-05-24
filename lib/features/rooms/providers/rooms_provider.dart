import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:agniraksha_mobile/features/rooms/data/rooms_repository.dart';
import 'package:agniraksha_mobile/features/rooms/domain/room_model.dart';
import 'package:agniraksha_mobile/features/auth/providers/auth_provider.dart';

final roomsRepositoryProvider = Provider<RoomsRepository>((ref) {
  return RoomsRepository(ref.read(apiClientProvider));
});

/// Fetches all rooms.
final roomsListProvider = FutureProvider<List<RoomModel>>((ref) {
  return ref.read(roomsRepositoryProvider).fetchRooms();
});

/// Fetches a single room's detail by ID.
final roomDetailProvider =
    FutureProvider.family<RoomModel, String>((ref, roomId) {
  return ref.read(roomsRepositoryProvider).fetchRoomDetail(roomId);
});

/// Fetches sensors for a given room.
final roomSensorsProvider =
    FutureProvider.family<List<SensorModel>, String>((ref, roomId) {
  return ref.read(roomsRepositoryProvider).fetchSensors(roomId: roomId);
});

/// Fetches sensor history for a given room.
final sensorHistoryProvider =
    FutureProvider.family<List<Map<String, dynamic>>, ({String roomId, String range})>(
  (ref, args) {
    return ref.read(roomsRepositoryProvider).fetchSensorHistory(
      roomId: args.roomId,
      range: args.range,
    );
  },
);
