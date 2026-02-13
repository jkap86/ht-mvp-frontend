class RegisterRequest {
  final String username;
  final String email;
  final String password;

  const RegisterRequest({required this.username, required this.email, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'email': email, 'password': password};
}

class LoginRequest {
  final String username;
  final String password;

  const LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() => {'username': username, 'password': password};
}

class RefreshTokenRequest {
  final String refreshToken;

  const RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() => {'refresh_token': refreshToken};
}
