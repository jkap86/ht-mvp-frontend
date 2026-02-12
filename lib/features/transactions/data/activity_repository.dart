import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api/api_client.dart';
import '../domain/activity_item.dart';

final activityRepositoryProvider = Provider<ActivityRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ActivityRepository(apiClient);
});

/// Repository for fetching league activity feed
class ActivityRepository {
  final ApiClient _apiClient;

  ActivityRepository(this._apiClient);

  /// Get activity feed for a league
  /// [type] can be 'all', 'trade', 'waiver', 'add', 'drop', 'draft'
  Future<List<ActivityItem>> getLeagueActivity(
    int leagueId, {
    String type = 'all',
    int limit = 50,
    int offset = 0,
    int? week,
  }) async {
    String endpoint = '/leagues/$leagueId/activity?type=$type&limit=$limit&offset=$offset';
    if (week != null) {
      endpoint += '&week=$week';
    }
    final response = await _apiClient.get(endpoint);
    final items = (response as List?)?.cast<Map<String, dynamic>>() ?? [];
    return items.map((json) => ActivityItem.fromJson(json)).toList();
  }

  /// Get activity feed for a specific week
  Future<List<ActivityItem>> getWeekActivity(
    int leagueId,
    int week, {
    String type = 'all',
    int limit = 50,
  }) async {
    final endpoint =
        '/leagues/$leagueId/activity/week/$week?type=$type&limit=$limit';
    final response = await _apiClient.get(endpoint);
    final items = (response as List?)?.cast<Map<String, dynamic>>() ?? [];
    return items.map((json) => ActivityItem.fromJson(json)).toList();
  }
}
