class DashboardSummary {
  final int totalRooms;
  final int totalDevices;
  final int onlineDevices;
  final int activeAlerts;
  final int highRiskRooms;
  final Map<String, int> roomStatusCounts;
  final Map<String, int> deviceStatusCounts;
  final List<Map<String, dynamic>> recentCriticalEvents;

  const DashboardSummary({
    required this.totalRooms,
    required this.totalDevices,
    required this.onlineDevices,
    required this.activeAlerts,
    required this.highRiskRooms,
    required this.roomStatusCounts,
    required this.deviceStatusCounts,
    required this.recentCriticalEvents,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      totalRooms: json['totalRooms'] as int? ?? 0,
      totalDevices: json['totalDevices'] as int? ?? 0,
      onlineDevices: json['onlineDevices'] as int? ?? 0,
      activeAlerts: json['activeAlerts'] as int? ?? 0,
      highRiskRooms: json['highRiskRooms'] as int? ?? 0,
      roomStatusCounts: Map<String, int>.from(json['room_status_counts'] ?? {}),
      deviceStatusCounts: Map<String, int>.from(json['device_status_counts'] ?? {}),
      recentCriticalEvents: List<Map<String, dynamic>>.from(
        json['recent_critical_events'] ?? [],
      ),
    );
  }
}
