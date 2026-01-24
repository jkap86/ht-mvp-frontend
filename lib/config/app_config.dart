class AppConfig {
  static const String appName = 'HypeTrain FF';

  // Development defaults (used when env vars not provided)
  static const String _devApiBaseUrl = 'http://localhost:5000/api';
  static const String _devSocketUrl = 'http://localhost:5000';

  // API Configuration
  // For production: --dart-define=API_BASE_URL=https://your-api.com/api
  static const String _apiBaseUrlEnv = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl =>
      _apiBaseUrlEnv.isNotEmpty ? _apiBaseUrlEnv : _devApiBaseUrl;

  // Socket.IO Configuration
  // For production: --dart-define=SOCKET_URL=https://your-api.com
  static const String _socketUrlEnv = String.fromEnvironment('SOCKET_URL');
  static String get socketUrl =>
      _socketUrlEnv.isNotEmpty ? _socketUrlEnv : _devSocketUrl;

  // Auth token keys for storage
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
}
