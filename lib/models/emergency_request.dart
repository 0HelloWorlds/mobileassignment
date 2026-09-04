class EmergencyRequest {
  final String requestId;
  final String userId;
  final String emergencyType;
  final String? description;
  final double latitude;
  final double longitude;
  final String? address;
  final DateTime createdAt;

  const EmergencyRequest({
    required this.requestId,
    required this.userId,
    required this.emergencyType,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.description,
    this.address,
  });

  factory EmergencyRequest.fromJson(Map<String, dynamic> json) {
    return EmergencyRequest(
      requestId: json['request_id'] as String,
      userId: json['user_id'] as String,
      emergencyType: json['emergency_type'] as String,
      description: json['description'] as String?,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
