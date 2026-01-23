import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../leagues/domain/league.dart';
import '../../../players/data/player_repository.dart';
import '../../../players/domain/player.dart';
import '../../data/draft_repository.dart';

class DraftRoomState {
  final Draft? draft;
  final List<Player> players;
  final List<Map<String, dynamic>> picks;
  final bool isLoading;
  final String? error;

  DraftRoomState({
    this.draft,
    this.players = const [],
    this.picks = const [],
    this.isLoading = true,
    this.error,
  });

  /// Get drafted player IDs as a set for filtering
  Set<int> get draftedPlayerIds =>
      picks.map((p) => p['player_id'] as int).toSet();

  DraftRoomState copyWith({
    Draft? draft,
    List<Player>? players,
    List<Map<String, dynamic>>? picks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DraftRoomState(
      draft: draft ?? this.draft,
      players: players ?? this.players,
      picks: picks ?? this.picks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Composite key for DraftRoomProvider
typedef DraftRoomKey = ({int leagueId, int draftId});

class DraftRoomNotifier extends StateNotifier<DraftRoomState> {
  final DraftRepository _draftRepo;
  final PlayerRepository _playerRepo;
  final SocketService _socketService;
  final int leagueId;
  final int draftId;

  DraftRoomNotifier(
    this._draftRepo,
    this._playerRepo,
    this._socketService,
    this.leagueId,
    this.draftId,
  ) : super(DraftRoomState()) {
    _setupSocketListeners();
    loadData();
  }

  void _setupSocketListeners() {
    _socketService.joinDraft(draftId);

    _socketService.onDraftPick((data) {
      if (!mounted) return;
      state = state.copyWith(
        picks: [...state.picks, Map<String, dynamic>.from(data)],
      );
    });

    _socketService.onNextPick((data) {
      if (!mounted) return;
      final currentDraft = state.draft;
      if (currentDraft != null) {
        state = state.copyWith(
          draft: Draft(
            id: currentDraft.id,
            leagueId: currentDraft.leagueId,
            draftType: currentDraft.draftType,
            status: 'in_progress',
            rounds: currentDraft.rounds,
            pickTimeSeconds: currentDraft.pickTimeSeconds,
            currentPick: data['currentPick'] as int?,
            currentRound: data['currentRound'] as int?,
            currentRosterId: data['currentRosterId'] as int?,
            pickDeadline: data['pickDeadline'] != null
                ? DateTime.parse(data['pickDeadline'])
                : null,
          ),
        );
      }
    });

    _socketService.onDraftCompleted((data) {
      if (!mounted) return;
      state = state.copyWith(draft: Draft.fromJson(data));
    });
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final draft = await _draftRepo.getDraft(leagueId, draftId);
      final players = await _playerRepo.getPlayers();

      state = state.copyWith(
        draft: draft,
        players: players,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> makePick(int playerId) async {
    try {
      await _draftRepo.makePick(leagueId, draftId, playerId);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  void dispose() {
    _socketService.leaveDraft(draftId);
    _socketService.offAll();
    super.dispose();
  }
}

final draftRoomProvider =
    StateNotifierProvider.family<DraftRoomNotifier, DraftRoomState, DraftRoomKey>(
  (ref, key) => DraftRoomNotifier(
    ref.watch(draftRepositoryProvider),
    ref.watch(playerRepositoryProvider),
    ref.watch(socketServiceProvider),
    key.leagueId,
    key.draftId,
  ),
);
