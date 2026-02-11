import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/error_sanitizer.dart';
import '../../../leagues/data/league_repository.dart';
import '../../../leagues/domain/invitation.dart';

/// State for commissioner's league invitations management
class LeagueInvitationsState {
  final List<dynamic> pendingInvitations;
  final List<UserSearchResult> searchResults;
  final bool isLoading;
  final bool isSearching;
  final bool isSending;
  final String? error;
  final int? cancellingId;

  LeagueInvitationsState({
    this.pendingInvitations = const [],
    this.searchResults = const [],
    this.isLoading = false,
    this.isSearching = false,
    this.isSending = false,
    this.error,
    this.cancellingId,
  });

  LeagueInvitationsState copyWith({
    List<dynamic>? pendingInvitations,
    List<UserSearchResult>? searchResults,
    bool? isLoading,
    bool? isSearching,
    bool? isSending,
    String? error,
    int? cancellingId,
    bool clearError = false,
    bool clearCancelling = false,
  }) {
    return LeagueInvitationsState(
      pendingInvitations: pendingInvitations ?? this.pendingInvitations,
      searchResults: searchResults ?? this.searchResults,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      cancellingId: clearCancelling ? null : (cancellingId ?? this.cancellingId),
    );
  }
}

/// Notifier for commissioner's league invitations management
class LeagueInvitationsNotifier extends StateNotifier<LeagueInvitationsState> {
  final LeagueRepository _repository;
  final int leagueId;

  LeagueInvitationsNotifier(this._repository, this.leagueId)
      : super(LeagueInvitationsState());

  /// Load pending invitations for this league
  Future<void> loadPendingInvitations() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final invitations = await _repository.getLeagueInvitations(leagueId);
      state = state.copyWith(pendingInvitations: invitations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: ErrorSanitizer.sanitize(e));
    }
  }

  /// Search users to invite
  Future<void> searchUsers(String query) async {
    if (query.trim().length < 2) {
      state = state.copyWith(searchResults: []);
      return;
    }

    state = state.copyWith(isSearching: true, clearError: true);
    try {
      final results = await _repository.searchUsersForInvite(leagueId, query);
      state = state.copyWith(searchResults: results, isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: ErrorSanitizer.sanitize(e));
    }
  }

  /// Send an invitation to a user
  Future<bool> sendInvitation(String username, {String? message, String? idempotencyKey}) async {
    state = state.copyWith(isSending: true, clearError: true);
    try {
      await _repository.sendInvitation(leagueId, username, message: message, idempotencyKey: idempotencyKey);
      // Refresh pending invitations
      await loadPendingInvitations();
      // Clear search results to update "already invited" status
      state = state.copyWith(isSending: false, searchResults: []);
      return true;
    } catch (e) {
      state = state.copyWith(isSending: false, error: ErrorSanitizer.sanitize(e));
      return false;
    }
  }

  /// Cancel a pending invitation
  Future<bool> cancelInvitation(int invitationId, {String? idempotencyKey}) async {
    state = state.copyWith(cancellingId: invitationId, clearError: true);
    try {
      await _repository.cancelInvitation(invitationId, idempotencyKey: idempotencyKey);
      // Remove from local state
      final updatedInvitations = state.pendingInvitations
          .where((inv) => inv['id'] != invitationId)
          .toList();
      state = state.copyWith(
        pendingInvitations: updatedInvitations,
        clearCancelling: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(clearCancelling: true, error: ErrorSanitizer.sanitize(e));
      return false;
    }
  }

  /// Clear search results
  void clearSearch() {
    state = state.copyWith(searchResults: []);
  }
}

/// Provider for commissioner's league invitations management
final leagueInvitationsProvider = StateNotifierProvider.family<
    LeagueInvitationsNotifier, LeagueInvitationsState, int>((ref, leagueId) {
  final repository = ref.watch(leagueRepositoryProvider);
  return LeagueInvitationsNotifier(repository, leagueId);
});
