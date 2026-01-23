import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/leagues/presentation/providers/league_detail_provider.dart';
import 'package:hypetrain_mvp/features/leagues/data/league_repository.dart';
import 'package:hypetrain_mvp/features/leagues/domain/league.dart';

import '../../mocks/mock_repositories.dart';

// Test data helpers
League createMockLeague({
  int id = 1,
  String name = 'Test League',
  int commissionerRosterId = 1,
  int userRosterId = 1,
}) {
  return League(
    id: id,
    name: name,
    status: 'active',
    season: 2024,
    commissionerRosterId: commissionerRosterId,
    userRosterId: userRosterId,
    settings: {'total_rosters': 10},
  );
}

Roster createMockRoster({
  int id = 1,
  String username = 'testuser',
}) {
  return Roster(
    id: id,
    leagueId: 1,
    userId: 'user-$id',
    username: username,
  );
}

Draft createMockDraft({
  int id = 1,
  String status = 'not_started',
  String draftType = 'snake',
}) {
  return Draft(
    id: id,
    leagueId: 1,
    draftType: draftType,
    status: status,
    rounds: 15,
    pickTimeSeconds: 90,
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

  group('LeagueDetailState', () {
    test('isCommissioner should return true when user is commissioner', () {
      final league = createMockLeague(commissionerRosterId: 1, userRosterId: 1);
      final state = LeagueDetailState(league: league);
      expect(state.isCommissioner, true);
    });

    test('isCommissioner should return false when user is not commissioner', () {
      final league = createMockLeague(commissionerRosterId: 1, userRosterId: 2);
      final state = LeagueDetailState(league: league);
      expect(state.isCommissioner, false);
    });

    test('activeDraft should return draft with in_progress or not_started status', () {
      final draft1 = createMockDraft(id: 1, status: 'completed');
      final draft2 = createMockDraft(id: 2, status: 'in_progress');
      final state = LeagueDetailState(drafts: [draft1, draft2]);
      expect(state.activeDraft?.id, 2);
    });

    test('activeDraft should return null when no active drafts', () {
      final draft = createMockDraft(id: 1, status: 'completed');
      final state = LeagueDetailState(drafts: [draft]);
      expect(state.activeDraft, isNull);
    });

    test('draftType should return Snake for snake drafts', () {
      final draft = createMockDraft(draftType: 'snake');
      final state = LeagueDetailState(drafts: [draft]);
      expect(state.draftType, 'Snake');
    });

    test('draftType should return Linear for linear drafts', () {
      final draft = createMockDraft(draftType: 'linear');
      final state = LeagueDetailState(drafts: [draft]);
      expect(state.draftType, 'Linear');
    });
  });

  group('LeagueDetailNotifier - loadData', () {
    test('loadData success should set league, members, and drafts', () async {
      // Arrange
      final mockLeague = createMockLeague();
      final mockMembers = [createMockRoster(id: 1), createMockRoster(id: 2)];
      final mockDrafts = [createMockDraft()];

      when(() => mockLeagueRepo.getLeague(1))
          .thenAnswer((_) async => mockLeague);
      when(() => mockLeagueRepo.getLeagueMembers(1))
          .thenAnswer((_) async => mockMembers);
      when(() => mockLeagueRepo.getLeagueDrafts(1))
          .thenAnswer((_) async => mockDrafts);

      container = createContainer();

      // Trigger provider creation (which starts loadData)
      container!.read(leagueDetailProvider(1));

      // Wait for loading to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert
      final state = container!.read(leagueDetailProvider(1));
      expect(state.league?.name, 'Test League');
      expect(state.members.length, 2);
      expect(state.drafts.length, 1);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('loadData failure should set error', () async {
      // Arrange
      when(() => mockLeagueRepo.getLeague(1))
          .thenThrow(Exception('Failed to load'));
      when(() => mockLeagueRepo.getLeagueMembers(1))
          .thenAnswer((_) async => []);
      when(() => mockLeagueRepo.getLeagueDrafts(1))
          .thenAnswer((_) async => []);

      container = createContainer();

      // Trigger provider creation (which starts loadData)
      container!.read(leagueDetailProvider(1));

      // Wait for loading to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert
      final state = container!.read(leagueDetailProvider(1));
      expect(state.error, isNotNull);
      expect(state.isLoading, false);
    });
  });

  group('LeagueDetailNotifier - createDraft', () {
    test('createDraft success should add draft to list', () async {
      // Arrange
      final mockLeague = createMockLeague();
      final mockDraft = createMockDraft();

      when(() => mockLeagueRepo.getLeague(1))
          .thenAnswer((_) async => mockLeague);
      when(() => mockLeagueRepo.getLeagueMembers(1))
          .thenAnswer((_) async => []);
      when(() => mockLeagueRepo.getLeagueDrafts(1))
          .thenAnswer((_) async => []);
      when(() => mockLeagueRepo.createDraft(1))
          .thenAnswer((_) async => mockDraft);

      container = createContainer();
      await Future.delayed(const Duration(milliseconds: 300));

      // Act
      final notifier = container!.read(leagueDetailProvider(1).notifier);
      final success = await notifier.createDraft();

      // Assert
      expect(success, true);
      final state = container!.read(leagueDetailProvider(1));
      expect(state.drafts.length, 1);
    });
  });

  group('LeagueDetailNotifier - startDraft', () {
    test('startDraft success should update draft status', () async {
      // Arrange
      final mockLeague = createMockLeague();
      final initialDraft = createMockDraft(id: 1, status: 'not_started');
      final startedDraft = createMockDraft(id: 1, status: 'in_progress');

      when(() => mockLeagueRepo.getLeague(1))
          .thenAnswer((_) async => mockLeague);
      when(() => mockLeagueRepo.getLeagueMembers(1))
          .thenAnswer((_) async => []);
      when(() => mockLeagueRepo.getLeagueDrafts(1))
          .thenAnswer((_) async => [initialDraft]);
      when(() => mockLeagueRepo.startDraft(1, 1))
          .thenAnswer((_) async => startedDraft);

      container = createContainer();
      await Future.delayed(const Duration(milliseconds: 300));

      // Act
      final notifier = container!.read(leagueDetailProvider(1).notifier);
      final success = await notifier.startDraft(1);

      // Assert
      expect(success, true);
      final state = container!.read(leagueDetailProvider(1));
      expect(state.drafts.first.status, 'in_progress');
    });
  });
}
