/// All API endpoint paths as static constants.
abstract final class ApiEndpoints {
  static const String baseUrl = 'https://ifrit.space';
  static const String apiPrefix = '/api/v1';

  // Auth
  static const String login    = '$apiPrefix/auth/login';
  static const String register = '$apiPrefix/auth/register';
  static const String logout   = '$apiPrefix/auth/logout';
  static const String me       = '$apiPrefix/auth/me';

  // Dashboard
  static const String dashboardSummary = '$apiPrefix/dashboard/summary';
  static const String dashboardAlerts  = '$apiPrefix/dashboard/alerts';

  // Rooms
  static const String rooms    = '$apiPrefix/rooms';
  static String roomDetail(String id) => '$apiPrefix/rooms/$id';

  // Devices
  static const String devices  = '$apiPrefix/devices';
  static String deviceDetail(String id) => '$apiPrefix/devices/$id';

  // Sensors
  static const String sensors        = '$apiPrefix/sensors';
  static const String sensorHistory  = '$apiPrefix/sensors/history';
  static const String sensorHealth   = '$apiPrefix/sensors/health';
  static const String sensorExport   = '$apiPrefix/sensors/export';

  // Alerts
  static const String alerts   = '$apiPrefix/alerts';
  static String acknowledgeAlert(String id) => '$apiPrefix/alerts/$id/acknowledge';

  // Calibration
  static String calibrationCommand(String deviceId) =>
      '$apiPrefix/calibration/$deviceId/command';

  // WebSocket
  static const String ws = '$apiPrefix/dashboard/ws';
  static String get wsUrl =>
      baseUrl.replaceFirst('https://', 'wss://').replaceFirst('http://', 'ws://') + ws;

  // Subscriptions
  static const String roomSubscriptions = '$apiPrefix/user/room-subscriptions';
  static const String availableRooms = '$apiPrefix/user/room-subscriptions/available';
}
