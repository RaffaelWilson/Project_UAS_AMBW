class UserProfile {
  final String id;
  final String email;
  final String role;
  final String? fcmToken;

  UserProfile({
    required this.id,
    required this.email,
    required this.role,
    this.fcmToken,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'],
      email: json['email'],
      role: json['role'] ?? 'user',
      fcmToken: json['fcm_token'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'role': role,
      'fcm_token': fcmToken,
    };
  }

  bool get isAdmin => role == 'admin';
}