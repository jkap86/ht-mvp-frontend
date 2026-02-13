import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_client.dart';

/// Result from the user search API.
class UserSearchResult {
  final String id;
  final String username;

  const UserSearchResult({required this.id, required this.username});

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'] as String? ?? json['userId'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown',
    );
  }
}

/// Repository for searching users (used by DM user search).
class UserSearchRepository {
  final ApiClient _apiClient;

  UserSearchRepository(this._apiClient);

  /// Search users by query string. Returns empty list if query is too short.
  Future<List<UserSearchResult>> searchUsers(String query) async {
    final response = await _apiClient
        .get('/auth/users/search?q=${Uri.encodeComponent(query)}');
    return (response as List)
        .map((json) =>
            UserSearchResult.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}

final userSearchRepositoryProvider = Provider<UserSearchRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return UserSearchRepository(apiClient);
});
