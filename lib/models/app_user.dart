class AppUser {
  final String id;
  final String name;
  final String email;
  final String role;
  final String phoneNumber;
  final String status;
  final DateTime createdAt;
  final String? photo;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.createdAt,
    required this.phoneNumber,
    this.photo,
  });

  bool get isAdmin => role == 'admin' || role == 'admin manager';
  bool get isAdminManager => role == 'admin manager';
  bool get isActive => status == 'active';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['user_id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      phoneNumber: json['phone_number'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      photo: json['photo'] as String?,
    );
  }
}
