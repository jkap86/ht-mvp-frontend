import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/league.dart';
import '../../domain/draft_status.dart';

/// A draft with league context for the drafts list
class DraftsListItem {
  final int leagueId;
  final String leagueName;
  final Draft draft;

  DraftsListItem({
    required this.leagueId,
    required this.leagueName,
    required this.draft,
  });

  bool get isInProgress => draft.status == DraftStatus.inProgress;
  bool get isPaused => draft.status == DraftStatus.paused;
  bool get isNotStarted => draft.status == DraftStatus.notStarted;
  bool get isCompleted => draft.status == DraftStatus.completed;

  /// Sort priority: in_progress > paused > not_started > completed
  int get sortPriority {
    switch (draft.status) {
      case DraftStatus.inProgress:
        return 0;
      case DraftStatus.paused:
        return 1;
      case DraftStatus.notStarted:
        return 2;
      case DraftStatus.completed:
        return 3;
    }
  }
}

/// State for the drafts list screen
class DraftsListState {
  final List<DraftsListItem> drafts;
  final bool isLoading;
  final String? error;

  DraftsListState({
    this.drafts = const [],
    this.isLoading = true,
    this.error,
  });

  DraftsListState copyWith({
    List<DraftsListItem>? drafts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DraftsListState(
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  /// Get drafts grouped by status
  List<DraftsListItem> get inProgressDrafts =>
      drafts.where((d) => d.isInProgress || d.isPaused).toList();

  /// Upcoming drafts sorted by scheduledStart (soonest first), with unscheduled drafts last
  List<DraftsListItem> get upcomingDrafts {
    final upcoming = drafts.where((d) => d.isNotStarted).toList();
    upcoming.sort((a, b) {
      final aScheduled = a.draft.scheduledStart;
      final bScheduled = b.draft.scheduledStart;

      // Both have scheduled times - sort by date ascending (soonest first)
      if (aScheduled != null && bScheduled != null) {
        return aScheduled.compareTo(bScheduled);
      }
      // Only a has scheduled time - a comes first
      if (aScheduled != null && bScheduled == null) {
        return -1;
      }
      // Only b has scheduled time - b comes first
      if (aScheduled == null && bScheduled != null) {
        return 1;
      }
      // Neither has scheduled time - sort by draft ID (newer first)
      return b.draft.id.compareTo(a.draft.id);
    });
    return upcoming;
  }

  List<DraftsListItem> get completedDrafts =>
      drafts.where((d) => d.isCompleted).toList();

  /// Count of active drafts (in_progress or paused)
  int get activeCount => inProgressDrafts.length;
}

class DraftsListNotifier extends StateNotifier<DraftsListState> {
  final LeagueRepository _leagueRepo;

  DraftsListNotifier(this._leagueRepo) : super(DraftsListState()) {
    loadDrafts();
  }

  Future<void> loadDrafts() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Get all user's leagues
      final leagues = await _leagueRepo.getMyLeagues();

      if (leagues.isEmpty) {
        state = state.copyWith(drafts: [], isLoading: false);
        return;
      }

      // Fetch drafts for each league in parallel
      final draftsFutures = <Future<List<DraftsListItem>>>[];
      for (final league in leagues) {
        draftsFutures.add(_getLeagueDrafts(league));
      }

      final draftsResults = await Future.wait(draftsFutures);
      if (!mounted) return;

      // Flatten and sort
      final allDrafts = draftsResults.expand((d) => d).toList();
      allDrafts.sort((a, b) {
        // First by status priority
        final priorityCompare = a.sortPriority.compareTo(b.sortPriority);
        if (priorityCompare != 0) return priorityCompare;
        // Then by draft ID (newer first)
        return b.draft.id.compareTo(a.draft.id);
      });

      state = state.copyWith(drafts: allDrafts, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<List<DraftsListItem>> _getLeagueDrafts(League league) async {
    try {
      final drafts = await _leagueRepo.getLeagueDrafts(league.id);
      return drafts
          .map((d) => DraftsListItem(
                leagueId: league.id,
                leagueName: league.name,
                draft: d,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

final draftsListProvider =
    StateNotifierProvider.autoDispose<DraftsListNotifier, DraftsListState>(
  (ref) => DraftsListNotifier(
    ref.watch(leagueRepositoryProvider),
  ),
);
