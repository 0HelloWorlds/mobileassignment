class EmergencyContact {
  final String contactId;
  final String userId;
  final String fullName;
  final String contactNumber;
  final String relationship;
  final DateTime createdAt;

  const EmergencyContact({
    required this.contactId,
    required this.userId,
    required this.fullName,
    required this.contactNumber,
    required this.relationship,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      contactId: json['contact_id'] as String,
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      contactNumber: json['contact_number'] as String,
      relationship: json['relationship'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
