import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../config/app_config.dart';
import '../../../core/api/api_client.dart';
import '../../../core/socket/socket_service.dart';
import '../data/auth_repository.dart';
import '../domain/user.dart';

class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _authRepository;
  final SocketService _socketService;
  final ApiClient _apiClient;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthNotifier(this._authRepository, this._socketService, this._apiClient) : super(AuthState()) {
    _checkAuthStatus();
  }

  /// Sets up the token refresh callback on ApiClient
  void _setupTokenRefreshCallback() {
    _apiClient.onTokenRefresh = () => _authRepository.refreshTokens();
  }

  /// Clears the token refresh callback
  void _clearTokenRefreshCallback() {
    _apiClient.onTokenRefresh = null;
  }

  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final token = await _storage.read(key: AppConfig.accessTokenKey);
      if (token != null) {
        _setupTokenRefreshCallback();
        final user = await _authRepository.getCurrentUser();
        state = state.copyWith(user: user, isLoading: false);
        await _socketService.connect();
      } else {
        state = state.copyWith(isLoading: false, clearUser: true);
      }
    } catch (e) {
      _clearTokenRefreshCallback();
      state = state.copyWith(isLoading: false, clearUser: true);
    }
  }

  Future<bool> register(String username, String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.register(username, email, password);
      _setupTokenRefreshCallback();
      state = state.copyWith(user: result.user, isLoading: false);
      await _socketService.connect();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _authRepository.login(username, password);
      _setupTokenRefreshCallback();
      state = state.copyWith(user: result.user, isLoading: false);
      await _socketService.connect();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      _clearTokenRefreshCallback();
      _socketService.disconnect();
      await _authRepository.logout();
    } finally {
      state = AuthState();
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final socketService = ref.watch(socketServiceProvider);
  final apiClient = ref.watch(apiClientProvider);
  return AuthNotifier(authRepository, socketService, apiClient);
});
