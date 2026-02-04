import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/dues_repository.dart';
import '../../domain/dues.dart';

/// State for dues management
class DuesState {
  final DuesOverview? overview;
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final int? updatingRosterId;

  DuesState({
    this.overview,
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.updatingRosterId,
  });

  DuesState copyWith({
    DuesOverview? overview,
    bool? isLoading,
    bool? isSaving,
    String? error,
    int? updatingRosterId,
    bool clearError = false,
    bool clearUpdating = false,
  }) {
    return DuesState(
      overview: overview ?? this.overview,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : (error ?? this.error),
      updatingRosterId: clearUpdating ? null : (updatingRosterId ?? this.updatingRosterId),
    );
  }

  bool get isEnabled => overview?.isEnabled ?? false;
  LeagueDues? get config => overview?.config;
  List<DuesPayment> get payments => overview?.payments ?? [];
  DuesSummary? get summary => overview?.summary;
  List<PayoutEntry> get payouts => overview?.payouts ?? [];
}

/// Notifier for dues management
class DuesNotifier extends StateNotifier<DuesState> {
  final DuesRepository _repository;
  final int leagueId;

  DuesNotifier(this._repository, this.leagueId) : super(DuesState());

  /// Load dues overview
  Future<void> loadDues() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final overview = await _repository.getDuesOverview(leagueId);
      state = state.copyWith(overview: overview, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Enable or update dues configuration
  Future<bool> saveDuesConfig({
    required double buyInAmount,
    Map<String, num>? payoutStructure,
    String? currency,
    String? notes,
  }) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.upsertDuesConfig(
        leagueId,
        buyInAmount: buyInAmount,
        payoutStructure: payoutStructure,
        currency: currency,
        notes: notes,
      );
      // Reload to get updated data
      await loadDues();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Disable dues tracking
  Future<bool> deleteDuesConfig() async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      await _repository.deleteDuesConfig(leagueId);
      // Clear the overview to show disabled state
      state = state.copyWith(
        isSaving: false,
        overview: DuesOverview(
          config: null,
          payments: [],
          summary: DuesSummary(paidCount: 0, totalCount: 0, totalPot: 0, amountCollected: 0),
          payouts: [],
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  /// Mark payment status for a roster
  Future<bool> markPayment(int rosterId, bool isPaid, {String? notes}) async {
    state = state.copyWith(updatingRosterId: rosterId, clearError: true);
    try {
      await _repository.markPaymentStatus(
        leagueId,
        rosterId,
        isPaid: isPaid,
        notes: notes,
      );
      // Reload to get updated data
      await loadDues();
      state = state.copyWith(clearUpdating: true);
      return true;
    } catch (e) {
      state = state.copyWith(clearUpdating: true, error: e.toString());
      return false;
    }
  }
}

/// Provider for dues state (family by league ID)
final duesProvider = StateNotifierProvider.family<DuesNotifier, DuesState, int>(
  (ref, leagueId) {
    final repository = ref.watch(duesRepositoryProvider);
    return DuesNotifier(repository, leagueId);
  },
);
