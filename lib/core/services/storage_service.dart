import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'storage_keys.dart';

/// Centralized storage service that wraps FlutterSecureStorage and SharedPreferences.
///
/// This service provides a single source of truth for all persistent storage
/// operations, reducing scattered FlutterSecureStorage/SharedPreferences instances.
class StorageService {
  final FlutterSecureStorage _secureStorage;
  SharedPreferences? _prefs;

  StorageService({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  /// Initialize SharedPreferences (call during app startup)
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance (lazy init if needed)
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============================================================
  // Secure Storage (Auth tokens)
  // ============================================================

  /// Read access token from secure storage
  Future<String?> getAccessToken() async {
    return _secureStorage.read(key: StorageKeys.accessToken);
  }

  /// Write access token to secure storage
  Future<void> setAccessToken(String token) async {
    await _secureStorage.write(key: StorageKeys.accessToken, value: token);
  }

  /// Read refresh token from secure storage
  Future<String?> getRefreshToken() async {
    return _secureStorage.read(key: StorageKeys.refreshToken);
  }

  /// Write refresh token to secure storage
  Future<void> setRefreshToken(String token) async {
    await _secureStorage.write(key: StorageKeys.refreshToken, value: token);
  }

  /// Read user data from secure storage
  Future<String?> getUser() async {
    return _secureStorage.read(key: StorageKeys.user);
  }

  /// Write user data to secure storage
  Future<void> setUser(String userJson) async {
    await _secureStorage.write(key: StorageKeys.user, value: userJson);
  }

  /// Clear all auth data (logout)
  Future<void> clearAuth() async {
    await _secureStorage.delete(key: StorageKeys.accessToken);
    await _secureStorage.delete(key: StorageKeys.refreshToken);
    await _secureStorage.delete(key: StorageKeys.user);
  }

  // ============================================================
  // SharedPreferences (Non-sensitive data)
  // ============================================================

  /// Get theme mode index
  Future<int?> getThemeMode() async {
    final p = await prefs;
    return p.getInt(StorageKeys.themeMode);
  }

  /// Set theme mode index
  Future<void> setThemeMode(int modeIndex) async {
    final p = await prefs;
    await p.setInt(StorageKeys.themeMode, modeIndex);
  }

  /// Get chat widget position X
  Future<double?> getChatPositionX() async {
    final p = await prefs;
    return p.getDouble(StorageKeys.chatPositionX);
  }

  /// Get chat widget position Y
  Future<double?> getChatPositionY() async {
    final p = await prefs;
    return p.getDouble(StorageKeys.chatPositionY);
  }

  /// Get chat widget width
  Future<double?> getChatWidth() async {
    final p = await prefs;
    return p.getDouble(StorageKeys.chatWidth);
  }

  /// Get chat widget height
  Future<double?> getChatHeight() async {
    final p = await prefs;
    return p.getDouble(StorageKeys.chatHeight);
  }

  /// Save chat widget state
  Future<void> saveChatState({
    required double x,
    required double y,
    required double width,
    required double height,
  }) async {
    final p = await prefs;
    await p.setDouble(StorageKeys.chatPositionX, x);
    await p.setDouble(StorageKeys.chatPositionY, y);
    await p.setDouble(StorageKeys.chatWidth, width);
    await p.setDouble(StorageKeys.chatHeight, height);
  }

  // ============================================================
  // Onboarding (Per-league UI state)
  // ============================================================

  /// Check if league onboarding has been seen for a given league
  Future<bool> hasSeenOnboarding(int leagueId) async {
    final p = await prefs;
    return p.getBool('${StorageKeys.onboardingSeenPrefix}$leagueId') ?? false;
  }

  /// Mark league onboarding as seen for a given league
  Future<void> markOnboardingSeen(int leagueId) async {
    final p = await prefs;
    await p.setBool('${StorageKeys.onboardingSeenPrefix}$leagueId', true);
  }

  /// Clear all preferences (but not secure storage)
  Future<void> clearPreferences() async {
    final p = await prefs;
    await p.clear();
  }

  /// Clear everything (full reset)
  Future<void> clearAll() async {
    await clearAuth();
    await clearPreferences();
  }
}

/// Global StorageService provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});
