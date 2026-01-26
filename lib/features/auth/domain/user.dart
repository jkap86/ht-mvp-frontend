class User {
  final String id;
  final String username;
  final String email;

  User({
    required this.id,
    required this.username,
    required this.email,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Backend returns 'userId', fallback to 'id' for compatibility
    final userId = (json['userId'] ?? json['id']) as String?;
    if (userId == null || userId.isEmpty) {
      throw FormatException('Invalid user data: missing or empty user ID');
    }
    return User(
      id: userId,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
    };
  }
}
