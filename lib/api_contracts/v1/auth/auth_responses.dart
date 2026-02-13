class UserDto {
  final String id;
  final String username;
  final String email;

  const UserDto({required this.id, required this.username, required this.email});

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: (json['userId'] ?? json['id']) as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'username': username, 'email': email};
}

class AuthResponse {
  final UserDto user;
  final String accessToken;
  final String refreshToken;

  const AuthResponse({required this.user, required this.accessToken, required this.refreshToken});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserDto.fromJson(json['user'] as Map<String, dynamic>? ?? {}),
      accessToken: json['access_token'] as String? ?? json['accessToken'] as String? ?? '',
      refreshToken: json['refresh_token'] as String? ?? json['refreshToken'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'access_token': accessToken,
    'refresh_token': refreshToken,
  };
}
