import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/playoff_repository.dart';
import '../../domain/playoff.dart';

class PlayoffBracketState {
  final PlayoffBracketView? bracketView;
  final bool isLoading;
  final bool isProcessing;
  final String? error;
  final String? successMessage;

  PlayoffBracketState({
    this.bracketView,
    this.isLoading = true,
    this.isProcessing = false,
    this.error,
    this.successMessage,
  });

  bool get hasPlayoffs => bracketView?.hasPlayoffs ?? false;
  bool get isChampionshipDecided => bracketView?.isChampionshipDecided ?? false;

  PlayoffBracketState copyWith({
    PlayoffBracketView? bracketView,
    bool? isLoading,
    bool? isProcessing,
    String? error,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return PlayoffBracketState(
      bracketView: bracketView ?? this.bracketView,
      isLoading: isLoading ?? this.isLoading,
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

class PlayoffBracketNotifier extends StateNotifier<PlayoffBracketState> {
  final PlayoffRepository _playoffRepo;
  final int leagueId;

  PlayoffBracketNotifier(this._playoffRepo, this.leagueId)
      : super(PlayoffBracketState()) {
    loadBracket();
  }

  Future<void> loadBracket() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final bracketView = await _playoffRepo.getBracket(leagueId);
      state = state.copyWith(
        bracketView: bracketView,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isLoading: false,
      );
    }
  }

  Future<bool> generateBracket({
    required int playoffTeams,
    required int startWeek,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final bracketView = await _playoffRepo.generateBracket(
        leagueId,
        playoffTeams: playoffTeams,
        startWeek: startWeek,
      );
      state = state.copyWith(
        bracketView: bracketView,
        isProcessing: false,
        successMessage: 'Playoff bracket generated successfully',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> advanceWinners(int week) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);

    try {
      final bracketView = await _playoffRepo.advanceWinners(leagueId, week);
      state = state.copyWith(
        bracketView: bracketView,
        isProcessing: false,
        successMessage: 'Winners advanced to next round',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        error: e.toString(),
        isProcessing: false,
      );
      return false;
    }
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }
}

final playoffBracketProvider = StateNotifierProvider.autoDispose.family<
    PlayoffBracketNotifier, PlayoffBracketState, int>(
  (ref, leagueId) => PlayoffBracketNotifier(
    ref.watch(playoffRepositoryProvider),
    leagueId,
  ),
);
