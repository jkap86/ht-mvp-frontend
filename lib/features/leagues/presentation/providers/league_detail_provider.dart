import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../drafts/domain/draft_status.dart';
import '../../data/league_repository.dart';
import '../../domain/league.dart';

class LeagueDetailState {
  final League? league;
  final List<Roster> members;
  final List<Draft> drafts;
  final bool isLoading;
  final String? error;

  LeagueDetailState({
    this.league,
    this.members = const [],
    this.drafts = const [],
    this.isLoading = true,
    this.error,
  });

  bool get isCommissioner {
    if (league == null) return false;
    return league!.userRosterId == league!.commissionerRosterId;
  }

  Draft? get activeDraft {
    try {
      return drafts.firstWhere(
        (d) => d.status == DraftStatus.inProgress || d.status == DraftStatus.notStarted,
      );
    } catch (_) {
      return null;
    }
  }

  String get draftTypeLabel {
    if (drafts.isEmpty) return 'Snake';
    return drafts.first.draftType.label;
  }

  LeagueDetailState copyWith({
    League? league,
    List<Roster>? members,
    List<Draft>? drafts,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LeagueDetailState(
      league: league ?? this.league,
      members: members ?? this.members,
      drafts: drafts ?? this.drafts,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LeagueDetailNotifier extends StateNotifier<LeagueDetailState> {
  final LeagueRepository _leagueRepo;
  final int leagueId;

  LeagueDetailNotifier(this._leagueRepo, this.leagueId) : super(LeagueDetailState()) {
    loadData();
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _leagueRepo.getLeague(leagueId),
        _leagueRepo.getLeagueMembers(leagueId),
        _leagueRepo.getLeagueDrafts(leagueId),
      ]);

      state = state.copyWith(
        league: results[0] as League,
        members: results[1] as List<Roster>,
        drafts: results[2] as List<Draft>,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> createDraft() async {
    try {
      final draft = await _leagueRepo.createDraft(leagueId);
      state = state.copyWith(drafts: [...state.drafts, draft]);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> startDraft(int draftId) async {
    try {
      final updatedDraft = await _leagueRepo.startDraft(leagueId, draftId);
      final index = state.drafts.indexWhere((d) => d.id == draftId);
      if (index != -1) {
        final updatedDrafts = [...state.drafts];
        updatedDrafts[index] = updatedDraft;
        state = state.copyWith(drafts: updatedDrafts);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}

final leagueDetailProvider =
    StateNotifierProvider.family<LeagueDetailNotifier, LeagueDetailState, int>(
  (ref, leagueId) => LeagueDetailNotifier(
    ref.watch(leagueRepositoryProvider),
    leagueId,
  ),
);
