import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appName = 'HypeTrain FF';

  // API Configuration
  // Build with: --dart-define=API_BASE_URL=https://your-api.com/api
  static const String _apiBaseUrlEnv = String.fromEnvironment('API_BASE_URL');
  static String get apiBaseUrl {
    if (_apiBaseUrlEnv.isNotEmpty) return _apiBaseUrlEnv;
    if (kDebugMode) return 'http://localhost:5000/api';
    throw StateError(
      'API_BASE_URL environment variable is required. '
      'Build with: --dart-define=API_BASE_URL=https://your-api-url.com/api',
    );
  }

  // Socket.IO Configuration
  // Build with: --dart-define=SOCKET_URL=https://your-api.com
  static const String _socketUrlEnv = String.fromEnvironment('SOCKET_URL');
  static String get socketUrl {
    if (_socketUrlEnv.isNotEmpty) return _socketUrlEnv;
    if (kDebugMode) return 'http://localhost:5000';
    throw StateError(
      'SOCKET_URL environment variable is required. '
      'Build with: --dart-define=SOCKET_URL=https://your-api-url.com',
    );
  }

  // Tenor GIF API Configuration
  // Build with: --dart-define=TENOR_API_KEY=your-tenor-api-key
  static const String _tenorApiKeyEnv = String.fromEnvironment('TENOR_API_KEY');
  static String get tenorApiKey {
    if (_tenorApiKeyEnv.isNotEmpty) return _tenorApiKeyEnv;
    if (kDebugMode) return ''; // GIFs disabled without key in debug
    return '';
  }

  static bool get isGifEnabled => tenorApiKey.isNotEmpty;

  // Auth token keys for storage
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
}
