import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/leagues/data/invitations_provider.dart';
import 'package:hypetrain_mvp/features/leagues/data/league_repository.dart';
import 'package:hypetrain_mvp/features/leagues/domain/invitation.dart';
import 'package:hypetrain_mvp/features/leagues/domain/league.dart';

import '../../mocks/mock_repositories.dart';

// Test data helpers
LeagueInvitation createMockInvitation({
  int id = 1,
  int leagueId = 1,
  String leagueName = 'Test League',
  String leagueSeason = '2026',
  String leagueMode = 'redraft',
  String invitedByUsername = 'commissioner',
  int memberCount = 5,
  int totalRosters = 12,
  String? message,
  DateTime? createdAt,
  DateTime? expiresAt,
}) {
  return LeagueInvitation(
    id: id,
    leagueId: leagueId,
    leagueName: leagueName,
    leagueSeason: leagueSeason,
    leagueMode: leagueMode,
    invitedByUsername: invitedByUsername,
    memberCount: memberCount,
    totalRosters: totalRosters,
    message: message,
    createdAt: createdAt ?? DateTime.now(),
    expiresAt: expiresAt ?? DateTime.now().add(const Duration(days: 7)),
  );
}

League createMockLeague({
  int id = 1,
  String name = 'Test League',
  int userRosterId = 1,
}) {
  return League(
    id: id,
    name: name,
    status: 'active',
    season: 2026,
    totalRosters: 12,
    userRosterId: userRosterId,
    settings: {},
    isPublic: false,
  );
}

void main() {
  late MockLeagueRepository mockLeagueRepo;
  ProviderContainer? container;

  setUp(() {
    mockLeagueRepo = MockLeagueRepository();
  });

  tearDown(() {
    container?.dispose();
    container = null;
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        leagueRepositoryProvider.overrideWithValue(mockLeagueRepo),
      ],
    );
  }

  group('InvitationsState', () {
    test('initial state should have empty list and not loading', () {
      final state = InvitationsState();
      expect(state.invitations, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.processingId, isNull);
    });

    test('copyWith should update specified fields', () {
      final invitations = [createMockInvitation()];
      final state = InvitationsState().copyWith(
        invitations: invitations,
        isLoading: true,
        error: 'Test error',
        processingId: 1,
      );

      expect(state.invitations, invitations);
      expect(state.isLoading, true);
      expect(state.error, 'Test error');
      expect(state.processingId, 1);
    });

    test('copyWith with clearProcessing should set processingId to null', () {
      final state = InvitationsState(processingId: 1).copyWith(
        clearProcessing: true,
      );
      expect(state.processingId, isNull);
    });

    test('copyWith should preserve values when not specified', () {
      final invitations = [createMockInvitation()];
      final state = InvitationsState(
        invitations: invitations,
        isLoading: true,
        processingId: 5,
      );
      final newState = state.copyWith();
      expect(newState.invitations, invitations);
      expect(newState.isLoading, true);
      expect(newState.processingId, 5);
    });
  });

  group('LeagueInvitation model', () {
    test('isExpiringSoon should return true when expiring within 24 hours', () {
      final invitation = createMockInvitation(
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
      expect(invitation.isExpiringSoon, true);
    });

    test('isExpiringSoon should return false when expiring in more than 24 hours', () {
      final invitation = createMockInvitation(
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(invitation.isExpiringSoon, false);
    });

    test('isExpired should return true when past expiry date', () {
      final invitation = createMockInvitation(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(invitation.isExpired, true);
    });

    test('isExpired should return false when before expiry date', () {
      final invitation = createMockInvitation(
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      );
      expect(invitation.isExpired, false);
    });

    test('memberCountDisplay should format as "current/total"', () {
      final invitation = createMockInvitation(memberCount: 5, totalRosters: 12);
      expect(invitation.memberCountDisplay, '5/12');
    });

    test('expiryDisplay should show days when more than 24 hours', () {
      final invitation = createMockInvitation(
        expiresAt: DateTime.now().add(const Duration(days: 3)),
      );
      // Due to DateTime rounding, could be 2d or 3d depending on time of day
      expect(invitation.expiryDisplay, matches(RegExp(r'\dd')));
    });

    test('expiryDisplay should show hours when less than 24 hours', () {
      final invitation = createMockInvitation(
        expiresAt: DateTime.now().add(const Duration(hours: 12)),
      );
      expect(invitation.expiryDisplay, contains('h'));
    });

    test('expiryDisplay should show "Expired" when past expiry', () {
      final invitation = createMockInvitation(
        expiresAt: DateTime.now().subtract(const Duration(days: 1)),
      );
      expect(invitation.expiryDisplay, 'Expired');
    });
  });

  group('UserSearchResult model', () {
    test('canInvite should return true when user is not member and has no pending invite', () {
      final user = UserSearchResult(
        id: 'user-1',
        username: 'testuser',
        hasPendingInvite: false,
        isMember: false,
      );
      expect(user.canInvite, true);
    });

    test('canInvite should return false when user is already a member', () {
      final user = UserSearchResult(
        id: 'user-1',
        username: 'testuser',
        hasPendingInvite: false,
        isMember: true,
      );
      expect(user.canInvite, false);
    });

    test('canInvite should return false when user has pending invite', () {
      final user = UserSearchResult(
        id: 'user-1',
        username: 'testuser',
        hasPendingInvite: true,
        isMember: false,
      );
      expect(user.canInvite, false);
    });
  });

  group('InvitationsNotifier - loadInvitations', () {
    test('loadInvitations success should set invitations', () async {
      // Arrange
      final mockInvitations = [
        createMockInvitation(id: 1, leagueName: 'League 1'),
        createMockInvitation(id: 2, leagueName: 'League 2'),
      ];

      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);

      container = createContainer();

      // Act
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Assert
      final state = container!.read(invitationsProvider);
      expect(state.invitations.length, 2);
      expect(state.invitations[0].leagueName, 'League 1');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('loadInvitations failure should set error', () async {
      // Arrange
      when(() => mockLeagueRepo.getPendingInvitations())
          .thenThrow(Exception('Network error'));

      container = createContainer();

      // Act
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Assert
      final state = container!.read(invitationsProvider);
      expect(state.invitations, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('loadInvitations should set isLoading during fetch', () async {
      // Arrange
      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });

      container = createContainer();
      final notifier = container!.read(invitationsProvider.notifier);

      // Act - start loading but don't await
      final future = notifier.loadInvitations();

      // Give time for loading state to be set
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should be loading
      expect(container!.read(invitationsProvider).isLoading, true);

      // Wait for completion
      await future;
      expect(container!.read(invitationsProvider).isLoading, false);
    });
  });

  group('InvitationsNotifier - acceptInvitation', () {
    test('acceptInvitation success should remove invitation and return league', () async {
      // Arrange
      final mockInvitations = [
        createMockInvitation(id: 1, leagueName: 'League 1'),
        createMockInvitation(id: 2, leagueName: 'League 2'),
      ];
      final joinedLeague = createMockLeague(id: 1, name: 'League 1');

      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);
      when(() => mockLeagueRepo.acceptInvitation(1))
          .thenAnswer((_) async => joinedLeague);

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act
      final result = await container!.read(invitationsProvider.notifier).acceptInvitation(1);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 1);
      final state = container!.read(invitationsProvider);
      expect(state.invitations.length, 1);
      expect(state.invitations[0].id, 2); // Only invitation 2 remains
      expect(state.processingId, isNull);
    });

    test('acceptInvitation failure should set error and return null', () async {
      // Arrange
      final mockInvitations = [createMockInvitation(id: 1)];

      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);
      when(() => mockLeagueRepo.acceptInvitation(1))
          .thenThrow(Exception('League is full'));

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act
      final result = await container!.read(invitationsProvider.notifier).acceptInvitation(1);

      // Assert
      expect(result, isNull);
      final state = container!.read(invitationsProvider);
      expect(state.error, isNotNull);
      expect(state.processingId, isNull);
      expect(state.invitations.length, 1); // Invitation still in list
    });

    test('acceptInvitation should set processingId during accept', () async {
      // Arrange
      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => [createMockInvitation(id: 1)]);
      when(() => mockLeagueRepo.acceptInvitation(1))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return createMockLeague(id: 1);
      });

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act - start accepting but don't await
      final future = container!.read(invitationsProvider.notifier).acceptInvitation(1);

      // Give time for processing state to be set
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should have processingId set
      expect(container!.read(invitationsProvider).processingId, 1);

      // Wait for completion
      await future;
      expect(container!.read(invitationsProvider).processingId, isNull);
    });
  });

  group('InvitationsNotifier - declineInvitation', () {
    test('declineInvitation success should remove invitation and return true', () async {
      // Arrange
      final mockInvitations = [
        createMockInvitation(id: 1, leagueName: 'League 1'),
        createMockInvitation(id: 2, leagueName: 'League 2'),
      ];

      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);
      when(() => mockLeagueRepo.declineInvitation(1))
          .thenAnswer((_) async {});

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act
      final result = await container!.read(invitationsProvider.notifier).declineInvitation(1);

      // Assert
      expect(result, true);
      final state = container!.read(invitationsProvider);
      expect(state.invitations.length, 1);
      expect(state.invitations[0].id, 2); // Only invitation 2 remains
      expect(state.processingId, isNull);
    });

    test('declineInvitation failure should set error and return false', () async {
      // Arrange
      final mockInvitations = [createMockInvitation(id: 1)];

      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);
      when(() => mockLeagueRepo.declineInvitation(1))
          .thenThrow(Exception('Network error'));

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act
      final result = await container!.read(invitationsProvider.notifier).declineInvitation(1);

      // Assert
      expect(result, false);
      final state = container!.read(invitationsProvider);
      expect(state.error, isNotNull);
      expect(state.processingId, isNull);
      expect(state.invitations.length, 1); // Invitation still in list
    });
  });

  group('InvitationsNotifier - addInvitation', () {
    test('addInvitation should add invitation to the front of the list', () async {
      // Arrange
      final mockInvitations = [createMockInvitation(id: 1)];
      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act
      container!.read(invitationsProvider.notifier).addInvitation(
        createMockInvitation(id: 2, leagueName: 'New League'),
      );

      // Assert
      final state = container!.read(invitationsProvider);
      expect(state.invitations.length, 2);
      expect(state.invitations[0].id, 2); // New invitation at front
      expect(state.invitations[1].id, 1);
    });

    test('addInvitation should not add duplicate invitations', () async {
      // Arrange
      final mockInvitations = [createMockInvitation(id: 1)];
      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act - try to add duplicate
      container!.read(invitationsProvider.notifier).addInvitation(
        createMockInvitation(id: 1, leagueName: 'Duplicate'),
      );

      // Assert
      final state = container!.read(invitationsProvider);
      expect(state.invitations.length, 1); // No duplicate added
    });
  });

  group('InvitationsNotifier - removeInvitation', () {
    test('removeInvitation should remove invitation from list', () async {
      // Arrange
      final mockInvitations = [
        createMockInvitation(id: 1),
        createMockInvitation(id: 2),
      ];
      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act
      container!.read(invitationsProvider.notifier).removeInvitation(1);

      // Assert
      final state = container!.read(invitationsProvider);
      expect(state.invitations.length, 1);
      expect(state.invitations[0].id, 2);
    });

    test('removeInvitation should handle non-existent invitation gracefully', () async {
      // Arrange
      final mockInvitations = [createMockInvitation(id: 1)];
      when(() => mockLeagueRepo.getPendingInvitations())
          .thenAnswer((_) async => mockInvitations);

      container = createContainer();
      await container!.read(invitationsProvider.notifier).loadInvitations();

      // Act
      container!.read(invitationsProvider.notifier).removeInvitation(999);

      // Assert - no change
      final state = container!.read(invitationsProvider);
      expect(state.invitations.length, 1);
    });
  });
}
