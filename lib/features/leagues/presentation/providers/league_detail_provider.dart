import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../../core/services/invalidation_service.dart';
import '../../../drafts/domain/draft_order_entry.dart';
import '../../../drafts/domain/draft_status.dart';
import '../../../drafts/data/draft_repository.dart';
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
    final l = league;
    if (l == null) return false;
    return l.userRosterId == l.commissionerRosterId;
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

  /// Count of pending trades requiring user's attention (for badge)
  int get pendingTradesCount => 0; // TODO: Implement when trades data is added to state

  /// Count of unread messages (for badge)
  int get unreadMessagesCount => 0; // TODO: Implement when chat data is added to state

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
  final DraftRepository _draftRepo;
  final SocketService _socketService;
  final InvalidationService _invalidationService;
  final int leagueId;
  VoidCallback? _memberJoinedDisposer;
  VoidCallback? _memberKickedDisposer;
  VoidCallback? _draftCreatedDisposer;
  VoidCallback? _invalidationDisposer;

  LeagueDetailNotifier(this._leagueRepo, this._draftRepo, this._socketService, this._invalidationService, this.leagueId) : super(LeagueDetailState()) {
    _setupSocketListeners();
    _registerInvalidationCallback();
    loadData();
  }

  void _registerInvalidationCallback() {
    _invalidationDisposer = _invalidationService.register(
      InvalidationType.leagueDetail,
      leagueId,
      loadData,
    );
  }

  void _setupSocketListeners() {
    _socketService.joinLeague(leagueId);
    _memberJoinedDisposer = _socketService.onMemberJoined((data) {
      if (!mounted) return;
      _refreshMembers();
    });
    _memberKickedDisposer = _socketService.onMemberKicked((data) {
      if (!mounted) return;
      _refreshMembers();
    });
    _draftCreatedDisposer = _socketService.onDraftCreated((data) {
      if (!mounted) return;
      _refreshDrafts();
    });
  }

  Future<void> _refreshMembers() async {
    try {
      final members = await _leagueRepo.getLeagueMembers(leagueId);
      state = state.copyWith(members: members);
    } catch (_) {}
  }

  Future<void> _refreshDrafts() async {
    try {
      final drafts = await _leagueRepo.getLeagueDrafts(leagueId);
      state = state.copyWith(drafts: drafts);
    } catch (_) {}
  }

  @override
  void dispose() {
    _memberJoinedDisposer?.call();
    _memberKickedDisposer?.call();
    _draftCreatedDisposer?.call();
    _invalidationDisposer?.call();
    _socketService.leaveLeague(leagueId);
    super.dispose();
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

  Future<bool> createDraft({
    String draftType = 'snake',
    int rounds = 15,
    int pickTimeSeconds = 90,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final draft = await _leagueRepo.createDraft(
        leagueId,
        draftType: draftType,
        rounds: rounds,
        pickTimeSeconds: pickTimeSeconds,
        settings: settings,
      );
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

  Future<List<DraftOrderEntry>?> randomizeDraftOrder(int draftId) async {
    try {
      final order = await _draftRepo.randomizeDraftOrder(leagueId, draftId);
      // Update the draft to mark orderConfirmed as true
      final index = state.drafts.indexWhere((d) => d.id == draftId);
      if (index != -1) {
        final updatedDrafts = [...state.drafts];
        updatedDrafts[index] = updatedDrafts[index].copyWith(orderConfirmed: true);
        state = state.copyWith(drafts: updatedDrafts);
      }
      return order;
    } catch (e) {
      return null;
    }
  }

  /// Update draft settings (commissioner only)
  Future<void> updateDraftSettings(
    int draftId, {
    String? draftType,
    int? rounds,
    int? pickTimeSeconds,
    Map<String, dynamic>? auctionSettings,
  }) async {
    final updatedDraft = await _draftRepo.updateDraftSettings(
      leagueId,
      draftId,
      draftType: draftType,
      rounds: rounds,
      pickTimeSeconds: pickTimeSeconds,
      auctionSettings: auctionSettings,
    );
    // Update the draft in state
    final index = state.drafts.indexWhere((d) => d.id == draftId);
    if (index != -1) {
      final updatedDrafts = [...state.drafts];
      updatedDrafts[index] = updatedDraft;
      state = state.copyWith(drafts: updatedDrafts);
    }
  }
}

final leagueDetailProvider =
    StateNotifierProvider.family<LeagueDetailNotifier, LeagueDetailState, int>(
  (ref, leagueId) => LeagueDetailNotifier(
    ref.watch(leagueRepositoryProvider),
    ref.watch(draftRepositoryProvider),
    ref.watch(socketServiceProvider),
    ref.watch(invalidationServiceProvider),
    leagueId,
  ),
);
