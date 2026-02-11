import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/api_exceptions.dart';
import '../../../core/utils/error_sanitizer.dart';
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
      state = state.copyWith(isLoading: false, error: ErrorSanitizer.sanitize(e));
    }
  }

  /// Accept an invitation and join the league
  Future<League?> acceptInvitation(int invitationId, {String? idempotencyKey}) async {
    state = state.copyWith(processingId: invitationId, error: null);
    try {
      final league = await _repository.acceptInvitation(invitationId, idempotencyKey: idempotencyKey);
      // Remove the accepted invitation from the list
      final updatedInvitations = state.invitations
          .where((inv) => inv.id != invitationId)
          .toList();
      state = state.copyWith(
        invitations: updatedInvitations,
        clearProcessing: true,
      );
      return league;
    } on ForbiddenException {
      state = state.copyWith(
        error: 'This invitation is not valid for your account.',
        clearProcessing: true,
      );
      return null;
    } on NotFoundException {
      // Remove the expired/revoked invitation from the list
      final updatedInvitations = state.invitations
          .where((inv) => inv.id != invitationId)
          .toList();
      state = state.copyWith(
        invitations: updatedInvitations,
        error: 'This invitation has expired or been revoked.',
        clearProcessing: true,
      );
      return null;
    } catch (e) {
      state = state.copyWith(error: ErrorSanitizer.sanitize(e), clearProcessing: true);
      return null;
    }
  }

  /// Decline an invitation
  Future<bool> declineInvitation(int invitationId, {String? idempotencyKey}) async {
    state = state.copyWith(processingId: invitationId, error: null);
    try {
      await _repository.declineInvitation(invitationId, idempotencyKey: idempotencyKey);
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
      state = state.copyWith(error: ErrorSanitizer.sanitize(e), clearProcessing: true);
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
