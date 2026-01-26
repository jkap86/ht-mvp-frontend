import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/leagues/data/public_leagues_provider.dart';
import 'package:hypetrain_mvp/features/leagues/data/league_repository.dart';
import 'package:hypetrain_mvp/features/leagues/domain/league.dart';

import '../../mocks/mock_repositories.dart';

// Test data helpers
PublicLeague createMockPublicLeague({
  int id = 1,
  String name = 'Test Public League',
  String season = '2024',
  String mode = 'redraft',
  int totalRosters = 12,
  int memberCount = 5,
}) {
  return PublicLeague(
    id: id,
    name: name,
    season: season,
    mode: mode,
    totalRosters: totalRosters,
    memberCount: memberCount,
  );
}

League createMockLeague({
  int id = 1,
  String name = 'Test League',
  int userRosterId = 1,
  bool isPublic = false,
}) {
  return League(
    id: id,
    name: name,
    status: 'active',
    season: 2024,
    totalRosters: 12,
    userRosterId: userRosterId,
    settings: {},
    isPublic: isPublic,
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

  group('PublicLeaguesState', () {
    test('initial state should have empty leagues and not loading', () {
      final state = PublicLeaguesState();
      expect(state.leagues, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      expect(state.joiningLeagueId, isNull);
    });

    test('copyWith should update specified fields', () {
      final leagues = [createMockPublicLeague()];
      final state = PublicLeaguesState().copyWith(
        leagues: leagues,
        isLoading: true,
        error: 'Test error',
        joiningLeagueId: 1,
      );

      expect(state.leagues, leagues);
      expect(state.isLoading, true);
      expect(state.error, 'Test error');
      expect(state.joiningLeagueId, 1);
    });

    test('copyWith with clearJoining should set joiningLeagueId to null', () {
      final state = PublicLeaguesState(joiningLeagueId: 1).copyWith(
        clearJoining: true,
      );
      expect(state.joiningLeagueId, isNull);
    });
  });

  group('PublicLeague model', () {
    test('isFull should return true when memberCount >= totalRosters', () {
      final fullLeague = createMockPublicLeague(memberCount: 12, totalRosters: 12);
      expect(fullLeague.isFull, true);
    });

    test('isFull should return false when memberCount < totalRosters', () {
      final notFullLeague = createMockPublicLeague(memberCount: 5, totalRosters: 12);
      expect(notFullLeague.isFull, false);
    });

    test('memberCountDisplay should format as "current/total"', () {
      final league = createMockPublicLeague(memberCount: 5, totalRosters: 12);
      expect(league.memberCountDisplay, '5/12');
    });
  });

  group('PublicLeaguesNotifier - loadPublicLeagues', () {
    test('loadPublicLeagues success should set leagues', () async {
      // Arrange
      final mockLeagues = [
        createMockPublicLeague(id: 1, name: 'League 1'),
        createMockPublicLeague(id: 2, name: 'League 2'),
      ];

      when(() => mockLeagueRepo.discoverPublicLeagues())
          .thenAnswer((_) async => mockLeagues);

      container = createContainer();

      // Act
      await container!.read(publicLeaguesProvider.notifier).loadPublicLeagues();

      // Assert
      final state = container!.read(publicLeaguesProvider);
      expect(state.leagues.length, 2);
      expect(state.leagues[0].name, 'League 1');
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('loadPublicLeagues failure should set error', () async {
      // Arrange
      when(() => mockLeagueRepo.discoverPublicLeagues())
          .thenThrow(Exception('Network error'));

      container = createContainer();

      // Act
      await container!.read(publicLeaguesProvider.notifier).loadPublicLeagues();

      // Assert
      final state = container!.read(publicLeaguesProvider);
      expect(state.leagues, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });

    test('loadPublicLeagues should set isLoading during fetch', () async {
      // Arrange
      when(() => mockLeagueRepo.discoverPublicLeagues())
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return [];
      });

      container = createContainer();
      final notifier = container!.read(publicLeaguesProvider.notifier);

      // Act - start loading but don't await
      final future = notifier.loadPublicLeagues();

      // Give time for loading state to be set
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should be loading
      expect(container!.read(publicLeaguesProvider).isLoading, true);

      // Wait for completion
      await future;
      expect(container!.read(publicLeaguesProvider).isLoading, false);
    });
  });

  group('PublicLeaguesNotifier - joinLeague', () {
    test('joinLeague success should remove league from list and return joined league', () async {
      // Arrange
      final mockLeagues = [
        createMockPublicLeague(id: 1, name: 'League 1'),
        createMockPublicLeague(id: 2, name: 'League 2'),
      ];
      final joinedLeague = createMockLeague(id: 1, name: 'League 1', isPublic: true);

      when(() => mockLeagueRepo.discoverPublicLeagues())
          .thenAnswer((_) async => mockLeagues);
      when(() => mockLeagueRepo.joinPublicLeague(1))
          .thenAnswer((_) async => joinedLeague);

      container = createContainer();
      await container!.read(publicLeaguesProvider.notifier).loadPublicLeagues();

      // Act
      final result = await container!.read(publicLeaguesProvider.notifier).joinLeague(1);

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 1);
      final state = container!.read(publicLeaguesProvider);
      expect(state.leagues.length, 1);
      expect(state.leagues[0].id, 2); // Only league 2 remains
      expect(state.joiningLeagueId, isNull);
    });

    test('joinLeague failure should set error and clear joining state', () async {
      // Arrange
      final mockLeagues = [createMockPublicLeague(id: 1)];

      when(() => mockLeagueRepo.discoverPublicLeagues())
          .thenAnswer((_) async => mockLeagues);
      when(() => mockLeagueRepo.joinPublicLeague(1))
          .thenThrow(Exception('League is full'));

      container = createContainer();
      await container!.read(publicLeaguesProvider.notifier).loadPublicLeagues();

      // Act
      final result = await container!.read(publicLeaguesProvider.notifier).joinLeague(1);

      // Assert
      expect(result, isNull);
      final state = container!.read(publicLeaguesProvider);
      expect(state.error, isNotNull);
      expect(state.joiningLeagueId, isNull);
      expect(state.leagues.length, 1); // League still in list since join failed
    });

    test('joinLeague should set joiningLeagueId during join', () async {
      // Arrange
      when(() => mockLeagueRepo.discoverPublicLeagues())
          .thenAnswer((_) async => [createMockPublicLeague(id: 1)]);
      when(() => mockLeagueRepo.joinPublicLeague(1))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(milliseconds: 100));
        return createMockLeague(id: 1);
      });

      container = createContainer();
      await container!.read(publicLeaguesProvider.notifier).loadPublicLeagues();

      // Act - start joining but don't await
      final future = container!.read(publicLeaguesProvider.notifier).joinLeague(1);

      // Give time for joining state to be set
      await Future.delayed(const Duration(milliseconds: 10));

      // Assert - should have joiningLeagueId set
      expect(container!.read(publicLeaguesProvider).joiningLeagueId, 1);

      // Wait for completion
      await future;
      expect(container!.read(publicLeaguesProvider).joiningLeagueId, isNull);
    });
  });
}
