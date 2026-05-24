import 'package:agniraksha_mobile/core/network/api_client.dart';
import 'package:agniraksha_mobile/core/network/api_endpoints.dart';
import 'package:agniraksha_mobile/features/rooms/domain/room_model.dart';

class RoomsRepository {
  final ApiClient _client;

  RoomsRepository(this._client);

  Future<List<RoomModel>> fetchRooms() async {
    final res = await _client.dio.get(ApiEndpoints.rooms);
    final list = res.data as List<dynamic>;
    return list.map((e) => RoomModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RoomModel> fetchRoomDetail(String roomId) async {
    final res = await _client.dio.get(ApiEndpoints.roomDetail(roomId));
    return RoomModel.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<SensorModel>> fetchSensors({String? roomId, String? deviceId}) async {
    final params = <String, dynamic>{};
    if (roomId != null) params['room_id'] = roomId;
    if (deviceId != null) params['device_id'] = deviceId;

    final res = await _client.dio.get(
      ApiEndpoints.sensors,
      queryParameters: params,
    );
    final list = res.data as List<dynamic>;
    return list.map((e) => SensorModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Map<String, dynamic>>> fetchSensorHistory({
    required String roomId,
    String range = '30m',
  }) async {
    int minutes = 30;
    if (range == '30m') {
      minutes = 30;
    } else if (range == '1h') {
      minutes = 60;
    } else if (range == '6h') {
      minutes = 360;
    } else if (range == '24h') {
      minutes = 1440;
    }

    final res = await _client.dio.get(
      ApiEndpoints.sensorHistory,
      queryParameters: {'room_id': roomId, 'minutes': minutes},
    );
    return List<Map<String, dynamic>>.from(res.data as List);
  }
}
