class AppConfig {
  static const String appName = 'HypeTrain FF';

  // API Configuration
  // REQUIRED: Set API_BASE_URL at compile time (e.g., --dart-define=API_BASE_URL=https://api.example.com)
  static const String _apiBaseUrlEnv = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl {
    if (_apiBaseUrlEnv.isEmpty) {
      throw StateError(
        'API_BASE_URL environment variable is required. '
        'Build with: --dart-define=API_BASE_URL=https://your-api-url.com/api',
      );
    }
    return _apiBaseUrlEnv;
  }

  // Socket.IO Configuration
  // REQUIRED: Set SOCKET_URL at compile time (e.g., --dart-define=SOCKET_URL=https://api.example.com)
  static const String _socketUrlEnv = String.fromEnvironment('SOCKET_URL');
  static String get socketUrl {
    if (_socketUrlEnv.isEmpty) {
      throw StateError(
        'SOCKET_URL environment variable is required. '
        'Build with: --dart-define=SOCKET_URL=https://your-api-url.com',
      );
    }
    return _socketUrlEnv;
  }

  // Auth token keys for storage
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
}
