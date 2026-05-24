class RoomModel {
  final String id;
  final String name;
  final String? description;
  final String status;
  final int deviceCount;
  final int sensorCount;
  final List<DeviceModel> devices;

  const RoomModel({
    required this.id,
    required this.name,
    this.description,
    required this.status,
    required this.deviceCount,
    required this.sensorCount,
    required this.devices,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      status: (json['status'] as String?) ?? 'safe',
      deviceCount: json['device_count'] as int? ?? 0,
      sensorCount: json['sensor_count'] as int? ?? 0,
      devices: (json['devices'] as List<dynamic>?)
              ?.map((d) => DeviceModel.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class DeviceModel {
  final String id;
  final String? name;
  final String? macAddress;
  final String status;
  final String? firmwareVersion;
  final String? lastSeen;

  const DeviceModel({
    required this.id,
    this.name,
    this.macAddress,
    required this.status,
    this.firmwareVersion,
    this.lastSeen,
  });

  factory DeviceModel.fromJson(Map<String, dynamic> json) {
    return DeviceModel(
      id: json['id'] as String,
      name: json['name'] as String?,
      macAddress: json['mac_address'] as String?,
      status: (json['status'] as String?) ?? 'offline',
      firmwareVersion: json['firmware_version'] as String?,
      lastSeen: json['last_seen'] as String?,
    );
  }
}

class SensorModel {
  final String id;
  final String deviceId;
  final String? roomId;
  final String sensorType;
  final String unit;
  final String status;
  final double? currentValue;
  final String? lastUpdate;

  const SensorModel({
    required this.id,
    required this.deviceId,
    this.roomId,
    required this.sensorType,
    required this.unit,
    required this.status,
    this.currentValue,
    this.lastUpdate,
  });

  factory SensorModel.fromJson(Map<String, dynamic> json) {
    return SensorModel(
      id: json['id'] as String,
      deviceId: json['device_id'] as String,
      roomId: json['room_id'] as String?,
      sensorType: json['sensor_type'] as String,
      unit: (json['unit'] as String?) ?? 'raw',
      status: (json['status'] as String?) ?? 'active',
      currentValue: (json['current_value'] as num?)?.toDouble(),
      lastUpdate: json['last_update'] as String?,
    );
  }
}
