class AlertModel {
  final String id;
  final String? alertType;
  final String? severity;
  final String? message;
  final String? roomId;
  final String? deviceId;
  final String? imageUrl;
  final bool isAcknowledged;
  final String? acknowledgedAt;
  final String? acknowledgementNote;
  final String createdAt;

  const AlertModel({
    required this.id,
    this.alertType,
    this.severity,
    this.message,
    this.roomId,
    this.deviceId,
    this.imageUrl,
    required this.isAcknowledged,
    this.acknowledgedAt,
    this.acknowledgementNote,
    required this.createdAt,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      alertType: json['alert_type'] as String?,
      severity: json['severity'] as String?,
      message: json['message'] as String?,
      roomId: json['room_id'] as String?,
      deviceId: json['device_id'] as String?,
      imageUrl: json['image_url'] as String?,
      isAcknowledged: json['is_acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledged_at'] as String?,
      acknowledgementNote: json['acknowledgement_note'] as String?,
      createdAt: json['created_at'] as String,
    );
  }
}
