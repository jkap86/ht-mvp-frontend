import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../data/commissioner_tools_repository.dart';

/// State for commissioner admin tools
class CommissionerToolsState {
  final bool isProcessing;
  final String? error;
  final String? successMessage;
  final bool tradingLocked;

  CommissionerToolsState({
    this.isProcessing = false,
    this.error,
    this.successMessage,
    this.tradingLocked = false,
  });

  CommissionerToolsState copyWith({
    bool? isProcessing,
    String? error,
    String? successMessage,
    bool? tradingLocked,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return CommissionerToolsState(
      isProcessing: isProcessing ?? this.isProcessing,
      error: clearError ? null : (error ?? this.error),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
      tradingLocked: tradingLocked ?? this.tradingLocked,
    );
  }
}

/// Notifier for commissioner admin tool actions
class CommissionerToolsNotifier extends StateNotifier<CommissionerToolsState> {
  final CommissionerToolsRepository _repo;
  final int leagueId;

  CommissionerToolsNotifier(this._repo, this.leagueId)
      : super(CommissionerToolsState());

  /// Initialize from league settings (call from widget)
  void setTradingLocked(bool locked) {
    state = state.copyWith(tradingLocked: locked);
  }

  void clearMessages() {
    state = state.copyWith(clearError: true, clearSuccess: true);
  }

  // ============================================================
  // Draft Admin
  // ============================================================

  Future<bool> adjustChessClock(
    int draftId,
    int rosterId,
    int deltaSeconds, {
    String? reason,
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      await _repo.adjustChessClock(
        leagueId, draftId, rosterId, deltaSeconds,
        reason: reason,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return false;
      final direction = deltaSeconds > 0 ? 'Added' : 'Removed';
      final seconds = deltaSeconds.abs();
      state = state.copyWith(
        isProcessing: false,
        successMessage: '$direction ${_formatSeconds(seconds)} on chess clock',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> forceAutopick(
    int draftId, {
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      await _repo.forceAutopick(leagueId, draftId, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Autopick forced successfully',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> undoLastPick(
    int draftId, {
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      await _repo.undoLastPick(leagueId, draftId, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Last pick undone successfully',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  // ============================================================
  // Waiver Admin
  // ============================================================

  Future<bool> resetWaiverPriority({String? idempotencyKey}) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      await _repo.resetWaiverPriority(leagueId, idempotencyKey: idempotencyKey);
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Waiver priority reset to default order',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> setWaiverPriority(
    int rosterId,
    int priority, {
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      await _repo.setWaiverPriority(
        leagueId, rosterId, priority,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Waiver priority updated to #$priority',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> setFaabBudget(
    int rosterId,
    num setTo, {
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      await _repo.setFaabBudget(
        leagueId, rosterId, setTo,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'FAAB budget set to \$${setTo.toStringAsFixed(0)}',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  // ============================================================
  // Trade Admin
  // ============================================================

  Future<bool> adminCancelTrade(
    int tradeId, {
    String? reason,
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      await _repo.adminCancelTrade(
        leagueId, tradeId,
        reason: reason,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Trade cancelled by commissioner',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  Future<bool> updateTradingLocked(
    bool tradingLocked, {
    String? idempotencyKey,
  }) async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      await _repo.updateTradingLocked(
        leagueId, tradingLocked,
        idempotencyKey: idempotencyKey,
      );
      if (!mounted) return false;
      state = state.copyWith(
        isProcessing: false,
        tradingLocked: tradingLocked,
        successMessage: tradingLocked ? 'Trading locked' : 'Trading unlocked',
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return false;
    }
  }

  // ============================================================
  // Dues Admin
  // ============================================================

  /// Export dues CSV. Returns the CSV string on success.
  Future<String?> exportDuesCsv() async {
    state = state.copyWith(isProcessing: true, clearError: true, clearSuccess: true);
    try {
      final csv = await _repo.exportDuesCsv(leagueId);
      if (!mounted) return null;
      state = state.copyWith(
        isProcessing: false,
        successMessage: 'Dues CSV exported',
      );
      return csv;
    } catch (e) {
      if (!mounted) return null;
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isProcessing: false,
      );
      return null;
    }
  }

  // ============================================================
  // Helpers
  // ============================================================

  String _formatSeconds(int totalSeconds) {
    if (totalSeconds >= 60) {
      final minutes = totalSeconds ~/ 60;
      final seconds = totalSeconds % 60;
      if (seconds == 0) return '${minutes}m';
      return '${minutes}m ${seconds}s';
    }
    return '${totalSeconds}s';
  }
}

/// Provider for commissioner tools
final commissionerToolsProvider = StateNotifierProvider.autoDispose
    .family<CommissionerToolsNotifier, CommissionerToolsState, int>(
  (ref, leagueId) => CommissionerToolsNotifier(
    ref.watch(commissionerToolsRepositoryProvider),
    leagueId,
  ),
);
