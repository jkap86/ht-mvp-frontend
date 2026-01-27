import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/commissioner/presentation/providers/league_invitations_provider.dart';
import 'package:hypetrain_mvp/features/leagues/data/league_repository.dart';
import 'package:hypetrain_mvp/features/leagues/domain/invitation.dart';

import '../../mocks/mock_repositories.dart';

// Test data helpers
Map<String, dynamic> createMockInvitationData({
  int id = 1,
  String username = 'inviteduser',
  String? message,
}) {
  return {
    'id': id,
    'username': username,
    'message': message,
    'created_at': DateTime.now().toIso8601String(),
    'expires_at': DateTime.now().add(const Duration(days: 7)).toIso8601String(),
  };
}

UserSearchResult createMockSearchResult({
  String id = 'user-1',
  String username = 'testuser',
  bool hasPendingInvite = false,
  bool isMember = false,
}) {
  return UserSearchResult(
    id: id,
    username: username,
    hasPendingInvite: hasPendingInvite,
    isMember: isMember,
  );
}

LeagueInvitation createMockLeagueInvitation({
  int id = 1,
  int leagueId = 1,
  String leagueName = 'Test League',
}) {
  return LeagueInvitation(
    id: id,
    leagueId: leagueId,
    leagueName: leagueName,
    leagueSeason: '2026',
    leagueMode: 'redraft',
    invitedByUsername: 'commissioner',
    memberCount: 5,
    totalRosters: 12,
    message: null,
    createdAt: DateTime.now(),
    expiresAt: DateTime.now().add(const Duration(days: 7)),
  );
}

void main() {
  late MockLeagueRepository mockLeagueRepo;
  ProviderContainer? container;
  const testLeagueId = 1;

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

  group('LeagueInvitationsState', () {
    test('initial state should have empty lists and not loading', () {
      final state = LeagueInvitationsState();
      expect(state.pendingInvitations, isEmpty);
      expect(state.searchResults, isEmpty);
      expect(state.isLoading, false);
      expect(state.isSearching, false);
      expect(state.isSending, false);
      expect(state.error, isNull);
      expect(state.cancellingId, isNull);
    });

    test('copyWith should update specified fields', () {
      final pendingInvitations = [createMockInvitationData()];
      final searchResults = [createMockSearchResult()];
      final state = LeagueInvitationsState().copyWith(
        pendingInvitations: pendingInvitations,
        searchResults: searchResults,
        isLoading: true,
        isSearching: true,
        isSending: true,
        error: 'Test error',
        cancellingId: 1,
      );

      expect(state.pendingInvitations, pendingInvitations);
      expect(state.searchResults, searchResults);
      expect(state.isLoading, true);
      expect(state.isSearching, true);
      expect(state.isSending, true);
      expect(state.error, 'Test error');
      expect(state.cancellingId, 1);
    });

    test('copyWith with clearError should set error to null', () {
      final state = LeagueInvitationsState(error: 'Some error').copyWith(
        clearError: true,
      );
      expect(state.error, isNull);
    });

    test('copyWith with clearCancelling should set cancellingId to null', () {
      final state = LeagueInvitationsState(cancellingId: 5).copyWith(
        clearCancelling: true,
      );
      expect(state.cancellingId, isNull);
    });

    test('copyWith should preserve values when not specified', () {
      final pendingInvitations = [createMockInvitationData()];
      final searchResults = [createMockSearchResult()];
      final state = LeagueInvitationsState(
        pendingInvitations: pendingInvitations,
        searchResults: searchResults,
        isLoading: true,
        cancellingId: 3,
      );
      final newState = state.copyWith();
      expect(newState.pendingInvitations, pendingInvitations);
      expect(newState.searchResults, searchResults);
      expect(newState.isLoading, true);
      expect(newState.cancellingId, 3);
    });
  });

  group('LeagueInvitationsNotifier - loadPendingInvitations', () {
    test('loadPendingInvitations success should set pendingInvitations', () async {
      // Arrange
      final mockInvitations = [
        createMockInvitationData(id: 1, username: 'user1'),
        createMockInvitationData(id: 2, username: 'user2'),
      ];

      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenAnswer((_) async => mockInvitations);

      container = createContainer();

      // Act
      await container!.read(leagueInvitationsProvider(testLeagueId).notifier).loadPendingInvitations();

      // Assert
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.pendingInvitations.length, 2);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('loadPendingInvitations failure should set error', () async {
      // Arrange
      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenThrow(Exception('Network error'));

      container = createContainer();

      // Act
      await container!.read(leagueInvitationsProvider(testLeagueId).notifier).loadPendingInvitations();

      // Assert
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.pendingInvitations, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('loadPendingInvitations should set isLoading during fetch', () async {
      // Arrange
      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });

      container = createContainer();
      final notifier = container!.read(leagueInvitationsProvider(testLeagueId).notifier);

      // Act - start loading but don't await
      final future = notifier.loadPendingInvitations();

      // Give time for loading state to be set
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should be loading
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).isLoading, true);

      // Wait for completion
      await future;
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).isLoading, false);
    });
  });

  group('LeagueInvitationsNotifier - searchUsers', () {
    test('searchUsers success should set searchResults', () async {
      // Arrange
      final mockResults = [
        createMockSearchResult(id: 'user-1', username: 'testuser1'),
        createMockSearchResult(id: 'user-2', username: 'testuser2'),
      ];

      when(() => mockLeagueRepo.searchUsersForInvite(testLeagueId, 'test'))
          .thenAnswer((_) async => mockResults);

      container = createContainer();

      // Act
      await container!.read(leagueInvitationsProvider(testLeagueId).notifier).searchUsers('test');

      // Assert
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.searchResults.length, 2);
      expect(state.isSearching, false);
      expect(state.error, isNull);
    });

    test('searchUsers should clear results when query too short', () async {
      // Arrange
      container = createContainer();

      // First set some results
      final notifier = container!.read(leagueInvitationsProvider(testLeagueId).notifier);

      // Act - search with short query
      await notifier.searchUsers('a');

      // Assert
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.searchResults, isEmpty);
      verifyNever(() => mockLeagueRepo.searchUsersForInvite(any(), any()));
    });

    test('searchUsers failure should set error', () async {
      // Arrange
      when(() => mockLeagueRepo.searchUsersForInvite(testLeagueId, 'test'))
          .thenThrow(Exception('Search failed'));

      container = createContainer();

      // Act
      await container!.read(leagueInvitationsProvider(testLeagueId).notifier).searchUsers('test');

      // Assert
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.searchResults, isEmpty);
      expect(state.isSearching, false);
      expect(state.error, isNotNull);
    });

    test('searchUsers should set isSearching during search', () async {
      // Arrange
      when(() => mockLeagueRepo.searchUsersForInvite(testLeagueId, 'test'))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });

      container = createContainer();
      final notifier = container!.read(leagueInvitationsProvider(testLeagueId).notifier);

      // Act - start searching but don't await
      final future = notifier.searchUsers('test');

      // Give time for searching state to be set
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should be searching
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).isSearching, true);

      // Wait for completion
      await future;
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).isSearching, false);
    });
  });

  group('LeagueInvitationsNotifier - sendInvitation', () {
    test('sendInvitation success should return true and refresh list', () async {
      // Arrange
      when(() => mockLeagueRepo.sendInvitation(testLeagueId, 'newuser', message: null))
          .thenAnswer((_) async => createMockLeagueInvitation());
      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenAnswer((_) async => [createMockInvitationData(username: 'newuser')]);

      container = createContainer();

      // Act
      final result = await container!
          .read(leagueInvitationsProvider(testLeagueId).notifier)
          .sendInvitation('newuser');

      // Assert
      expect(result, true);
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.isSending, false);
      expect(state.searchResults, isEmpty); // Should clear search results
      verify(() => mockLeagueRepo.getLeagueInvitations(testLeagueId)).called(1);
    });

    test('sendInvitation failure should return false and set error', () async {
      // Arrange
      when(() => mockLeagueRepo.sendInvitation(testLeagueId, 'newuser', message: null))
          .thenThrow(Exception('User already invited'));

      container = createContainer();

      // Act
      final result = await container!
          .read(leagueInvitationsProvider(testLeagueId).notifier)
          .sendInvitation('newuser');

      // Assert
      expect(result, false);
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.isSending, false);
      expect(state.error, isNotNull);
    });

    test('sendInvitation should set isSending during send', () async {
      // Arrange
      when(() => mockLeagueRepo.sendInvitation(testLeagueId, 'newuser', message: null))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return createMockLeagueInvitation();
      });
      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenAnswer((_) async => []);

      container = createContainer();
      final notifier = container!.read(leagueInvitationsProvider(testLeagueId).notifier);

      // Act - start sending but don't await
      final future = notifier.sendInvitation('newuser');

      // Give time for sending state to be set
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should be sending
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).isSending, true);

      // Wait for completion
      await future;
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).isSending, false);
    });

    test('sendInvitation with message should pass message to repository', () async {
      // Arrange
      when(() => mockLeagueRepo.sendInvitation(testLeagueId, 'newuser', message: 'Join us!'))
          .thenAnswer((_) async => createMockLeagueInvitation());
      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenAnswer((_) async => []);

      container = createContainer();

      // Act
      await container!
          .read(leagueInvitationsProvider(testLeagueId).notifier)
          .sendInvitation('newuser', message: 'Join us!');

      // Assert
      verify(() => mockLeagueRepo.sendInvitation(testLeagueId, 'newuser', message: 'Join us!')).called(1);
    });
  });

  group('LeagueInvitationsNotifier - cancelInvitation', () {
    test('cancelInvitation success should remove invitation and return true', () async {
      // Arrange
      final mockInvitations = [
        createMockInvitationData(id: 1, username: 'user1'),
        createMockInvitationData(id: 2, username: 'user2'),
      ];

      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenAnswer((_) async => mockInvitations);
      when(() => mockLeagueRepo.cancelInvitation(1))
          .thenAnswer((_) async {});

      container = createContainer();
      await container!.read(leagueInvitationsProvider(testLeagueId).notifier).loadPendingInvitations();

      // Act
      final result = await container!
          .read(leagueInvitationsProvider(testLeagueId).notifier)
          .cancelInvitation(1);

      // Assert
      expect(result, true);
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.pendingInvitations.length, 1);
      expect(state.pendingInvitations[0]['id'], 2); // Only invitation 2 remains
      expect(state.cancellingId, isNull);
    });

    test('cancelInvitation failure should return false and set error', () async {
      // Arrange
      final mockInvitations = [createMockInvitationData(id: 1)];

      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenAnswer((_) async => mockInvitations);
      when(() => mockLeagueRepo.cancelInvitation(1))
          .thenThrow(Exception('Cannot cancel'));

      container = createContainer();
      await container!.read(leagueInvitationsProvider(testLeagueId).notifier).loadPendingInvitations();

      // Act
      final result = await container!
          .read(leagueInvitationsProvider(testLeagueId).notifier)
          .cancelInvitation(1);

      // Assert
      expect(result, false);
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.error, isNotNull);
      expect(state.cancellingId, isNull);
      expect(state.pendingInvitations.length, 1); // Invitation still in list
    });

    test('cancelInvitation should set cancellingId during cancel', () async {
      // Arrange
      when(() => mockLeagueRepo.getLeagueInvitations(testLeagueId))
          .thenAnswer((_) async => [createMockInvitationData(id: 5)]);
      when(() => mockLeagueRepo.cancelInvitation(5))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
      });

      container = createContainer();
      await container!.read(leagueInvitationsProvider(testLeagueId).notifier).loadPendingInvitations();

      // Act - start cancelling but don't await
      final future = container!.read(leagueInvitationsProvider(testLeagueId).notifier).cancelInvitation(5);

      // Give time for cancelling state to be set
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should have cancellingId set
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).cancellingId, 5);

      // Wait for completion
      await future;
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).cancellingId, isNull);
    });
  });

  group('LeagueInvitationsNotifier - clearSearch', () {
    test('clearSearch should clear searchResults', () async {
      // Arrange
      final mockResults = [createMockSearchResult()];
      when(() => mockLeagueRepo.searchUsersForInvite(testLeagueId, 'test'))
          .thenAnswer((_) async => mockResults);

      container = createContainer();
      await container!.read(leagueInvitationsProvider(testLeagueId).notifier).searchUsers('test');

      // Verify results are set
      expect(container!.read(leagueInvitationsProvider(testLeagueId)).searchResults, isNotEmpty);

      // Act
      container!.read(leagueInvitationsProvider(testLeagueId).notifier).clearSearch();

      // Assert
      final state = container!.read(leagueInvitationsProvider(testLeagueId));
      expect(state.searchResults, isEmpty);
    });
  });
}
