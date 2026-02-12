import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/api/api_exceptions.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../data/activity_repository.dart';
import '../../domain/activity_item.dart';

/// State for the transactions/activity feed
class TransactionsState {
  final List<ActivityItem> activities;
  final bool isLoading;
  final String? error;
  final bool isForbidden;
  final String typeFilter; // 'all', 'trade', 'waiver', 'add', 'drop', 'draft'
  final bool hasMore; // Whether there are more items to load
  final bool isLoadingMore; // Loading additional pages

  TransactionsState({
    this.activities = const [],
    this.isLoading = true,
    this.error,
    this.isForbidden = false,
    this.typeFilter = 'all',
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  TransactionsState copyWith({
    List<ActivityItem>? activities,
    bool? isLoading,
    String? error,
    bool? isForbidden,
    String? typeFilter,
    bool? hasMore,
    bool? isLoadingMore,
    bool clearError = false,
  }) {
    return TransactionsState(
      activities: activities ?? this.activities,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isForbidden: isForbidden ?? this.isForbidden,
      typeFilter: typeFilter ?? this.typeFilter,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

/// Notifier for managing transaction activity feed
class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final ActivityRepository _activityRepo;
  final int leagueId;

  static const int _pageSize = 50;

  TransactionsNotifier(
    this._activityRepo,
    this.leagueId,
  ) : super(TransactionsState()) {
    loadActivities();
  }

  /// Load the initial set of activities
  Future<void> loadActivities() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final activities = await _activityRepo.getLeagueActivity(
        leagueId,
        type: state.typeFilter,
        limit: _pageSize,
        offset: 0,
      );

      if (!mounted) return;

      state = state.copyWith(
        activities: activities,
        isLoading: false,
        hasMore: activities.length >= _pageSize,
      );
    } on ForbiddenException {
      if (!mounted) return;
      state = state.copyWith(isForbidden: true, isLoading: false, activities: []);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: ErrorSanitizer.sanitize(e), isLoading: false);
    }
  }

  /// Load more activities (pagination)
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final moreActivities = await _activityRepo.getLeagueActivity(
        leagueId,
        type: state.typeFilter,
        limit: _pageSize,
        offset: state.activities.length,
      );

      if (!mounted) return;

      state = state.copyWith(
        activities: [...state.activities, ...moreActivities],
        isLoadingMore: false,
        hasMore: moreActivities.length >= _pageSize,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Change the type filter and reload
  void setTypeFilter(String typeFilter) {
    if (state.typeFilter == typeFilter) return;
    state = state.copyWith(typeFilter: typeFilter);
    loadActivities();
  }
}

/// Provider for transaction activity feed in a specific league
final transactionsProvider =
    StateNotifierProvider.autoDispose.family<TransactionsNotifier, TransactionsState, int>(
  (ref, leagueId) => TransactionsNotifier(
    ref.watch(activityRepositoryProvider),
    leagueId,
  ),
);
