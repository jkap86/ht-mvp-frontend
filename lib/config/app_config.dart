class AppConfig {
  static const String appName = 'HypeTrain FF';

  // API Configuration
  // Default matches backend PORT=5000 from .env.example
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5000/api',
  );

  // Socket.IO Configuration
  // Same host/port as backend - Socket.IO runs on the same server
  static const String socketUrl = String.fromEnvironment(
    'SOCKET_URL',
    defaultValue: 'http://localhost:5000',
  );

  // Auth token keys for storage
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
}
