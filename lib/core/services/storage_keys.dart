/// Centralized storage keys for the application.
///
/// All SharedPreferences and FlutterSecureStorage keys should be defined here
/// to avoid magic strings scattered across the codebase.
class StorageKeys {
  StorageKeys._();

  // ============================================================
  // Auth (FlutterSecureStorage - sensitive data)
  // ============================================================

  /// JWT access token for API authentication
  static const String accessToken = 'access_token';

  /// JWT refresh token for obtaining new access tokens
  static const String refreshToken = 'refresh_token';

  /// Cached user data (JSON string)
  static const String user = 'user';

  // ============================================================
  // Theme (SharedPreferences - user preferences)
  // ============================================================

  /// Theme mode preference (ThemeMode.index)
  static const String themeMode = 'theme_mode';

  // ============================================================
  // Floating Chat Widget (SharedPreferences - UI state)
  // ============================================================

  /// Chat widget X position
  static const String chatPositionX = 'floating_chat_position_x';

  /// Chat widget Y position
  static const String chatPositionY = 'floating_chat_position_y';

  /// Chat widget width
  static const String chatWidth = 'floating_chat_width';

  /// Chat widget height
  static const String chatHeight = 'floating_chat_height';
}
