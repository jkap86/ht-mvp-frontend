import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/invitation.dart';
import '../domain/league.dart';
import 'league_repository.dart';

/// State for user's pending invitations
class InvitationsState {
  final List<LeagueInvitation> invitations;
  final bool isLoading;
  final String? error;
  final int? processingId;

  InvitationsState({
    this.invitations = const [],
    this.isLoading = false,
    this.error,
    this.processingId,
  });

  InvitationsState copyWith({
    List<LeagueInvitation>? invitations,
    bool? isLoading,
    String? error,
    int? processingId,
    bool clearProcessing = false,
  }) {
    return InvitationsState(
      invitations: invitations ?? this.invitations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      processingId: clearProcessing ? null : (processingId ?? this.processingId),
    );
  }
}

/// Notifier for user's pending invitations
class InvitationsNotifier extends StateNotifier<InvitationsState> {
  final LeagueRepository _repository;

  InvitationsNotifier(this._repository) : super(InvitationsState());

  /// Load pending invitations for the current user
  Future<void> loadInvitations() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final invitations = await _repository.getPendingInvitations();
      state = state.copyWith(invitations: invitations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Accept an invitation and join the league
  Future<League?> acceptInvitation(int invitationId) async {
    state = state.copyWith(processingId: invitationId, error: null);
    try {
      final league = await _repository.acceptInvitation(invitationId);
      // Remove the accepted invitation from the list
      final updatedInvitations = state.invitations
          .where((inv) => inv.id != invitationId)
          .toList();
      state = state.copyWith(
        invitations: updatedInvitations,
        clearProcessing: true,
      );
      return league;
    } catch (e) {
      state = state.copyWith(error: e.toString(), clearProcessing: true);
      return null;
    }
  }

  /// Decline an invitation
  Future<bool> declineInvitation(int invitationId) async {
    state = state.copyWith(processingId: invitationId, error: null);
    try {
      await _repository.declineInvitation(invitationId);
      // Remove the declined invitation from the list
      final updatedInvitations = state.invitations
          .where((inv) => inv.id != invitationId)
          .toList();
      state = state.copyWith(
        invitations: updatedInvitations,
        clearProcessing: true,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString(), clearProcessing: true);
      return false;
    }
  }

  /// Add an invitation received via socket
  void addInvitation(LeagueInvitation invitation) {
    // Avoid duplicates
    if (state.invitations.any((inv) => inv.id == invitation.id)) return;
    state = state.copyWith(
      invitations: [invitation, ...state.invitations],
    );
  }

  /// Remove an invitation (e.g., when cancelled by commissioner)
  void removeInvitation(int invitationId) {
    final updatedInvitations = state.invitations
        .where((inv) => inv.id != invitationId)
        .toList();
    state = state.copyWith(invitations: updatedInvitations);
  }
}

/// Provider for user's pending invitations
final invitationsProvider =
    StateNotifierProvider<InvitationsNotifier, InvitationsState>((ref) {
  final repository = ref.watch(leagueRepositoryProvider);
  return InvitationsNotifier(repository);
});
