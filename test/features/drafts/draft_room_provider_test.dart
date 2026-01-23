import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/drafts/presentation/providers/draft_room_provider.dart';
import 'package:hypetrain_mvp/features/drafts/data/draft_repository.dart';
import 'package:hypetrain_mvp/features/drafts/domain/draft_pick.dart';
import 'package:hypetrain_mvp/features/players/data/player_repository.dart';
import 'package:hypetrain_mvp/features/players/domain/player.dart';
import 'package:hypetrain_mvp/features/leagues/domain/league.dart';
import 'package:hypetrain_mvp/core/socket/socket_service.dart';

import '../../mocks/mock_repositories.dart';
import '../../mocks/mock_socket_service.dart';

// Test data helpers
Draft createMockDraft({
  int id = 1,
  String status = 'in_progress',
}) {
  return Draft(
    id: id,
    leagueId: 1,
    draftType: 'snake',
    status: status,
    rounds: 15,
    pickTimeSeconds: 90,
    currentPick: 1,
    currentRound: 1,
    currentRosterId: 1,
  );
}

Player createMockPlayer({
  int id = 1,
  String firstName = 'Patrick',
  String lastName = 'Mahomes',
  String position = 'QB',
}) {
  return Player(
    id: id,
    sleeperId: 'sleeper_$id',
    firstName: firstName,
    lastName: lastName,
    fantasyPositions: [position],
  );
}

void main() {
  late MockDraftRepository mockDraftRepo;
  late MockPlayerRepository mockPlayerRepo;
  late MockSocketService mockSocketService;
  ProviderContainer? container;

  setUp(() {
    mockDraftRepo = MockDraftRepository();
    mockPlayerRepo = MockPlayerRepository();
    mockSocketService = MockSocketService();

    // Setup default socket service mocks
    // The on* methods return VoidCallback disposers (always non-null, queued if not connected)
    when(() => mockSocketService.joinDraft(any())).thenReturn(null);
    when(() => mockSocketService.leaveDraft(any())).thenReturn(null);
    when(() => mockSocketService.onDraftPick(any())).thenReturn(() {});
    when(() => mockSocketService.onNextPick(any())).thenReturn(() {});
    when(() => mockSocketService.onDraftCompleted(any())).thenReturn(() {});
  });

  tearDown(() {
    container?.dispose();
    container = null;
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        draftRepositoryProvider.overrideWithValue(mockDraftRepo),
        playerRepositoryProvider.overrideWithValue(mockPlayerRepo),
        socketServiceProvider.overrideWithValue(mockSocketService),
      ],
    );
  }

  group('DraftRoomState', () {
    test('initial state should have empty picks and players', () {
      final state = DraftRoomState();
      expect(state.draft, isNull);
      expect(state.players, isEmpty);
      expect(state.picks, isEmpty);
      expect(state.isLoading, true);
      expect(state.draftedPlayerIds, isEmpty);
    });

    test('draftedPlayerIds should return set of picked player IDs', () {
      final state = DraftRoomState(
        picks: [
          DraftPick(id: 1, draftId: 1, pickNumber: 1, round: 1, pickInRound: 1, rosterId: 1, playerId: 1),
          DraftPick(id: 2, draftId: 1, pickNumber: 2, round: 1, pickInRound: 2, rosterId: 2, playerId: 5),
          DraftPick(id: 3, draftId: 1, pickNumber: 3, round: 1, pickInRound: 3, rosterId: 1, playerId: 10),
        ],
      );
      expect(state.draftedPlayerIds, equals({1, 5, 10}));
    });

    test('copyWith should preserve values when not specified', () {
      final draft = createMockDraft();
      final players = [createMockPlayer()];
      final state = DraftRoomState(
        draft: draft,
        players: players,
        isLoading: false,
      );
      final newState = state.copyWith();

      expect(newState.draft, equals(draft));
      expect(newState.players, equals(players));
      expect(newState.isLoading, false);
    });
  });

  group('DraftRoomNotifier - loadData', () {
    test('loadData success should set draft and players', () async {
      // Arrange
      final mockDraft = createMockDraft();
      final mockPlayers = [
        createMockPlayer(id: 1, firstName: 'Patrick', lastName: 'Mahomes'),
        createMockPlayer(id: 2, firstName: 'Josh', lastName: 'Allen'),
      ];

      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers())
          .thenAnswer((_) async => mockPlayers);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);

      // Trigger provider creation (which starts loadData)
      container!.read(draftRoomProvider(key));

      // Wait for loading to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert
      final state = container!.read(draftRoomProvider(key));
      expect(state.draft?.id, 1);
      expect(state.players.length, 2);
      expect(state.isLoading, false);
      expect(state.error, isNull);
      verify(() => mockSocketService.joinDraft(1)).called(1);
    });

    test('loadData failure should set error', () async {
      // Arrange
      when(() => mockDraftRepo.getDraft(1, 1))
          .thenThrow(Exception('Failed to load'));
      when(() => mockPlayerRepo.getPlayers())
          .thenAnswer((_) async => []);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);

      // Trigger provider creation (which starts loadData)
      container!.read(draftRoomProvider(key));

      // Wait for loading to complete
      await Future.delayed(const Duration(milliseconds: 300));

      // Assert
      final state = container!.read(draftRoomProvider(key));
      expect(state.error, isNotNull);
      expect(state.isLoading, false);
    });
  });

  group('DraftRoomNotifier - makePick', () {
    test('makePick success should return true', () async {
      // Arrange
      final mockDraft = createMockDraft();
      final mockPlayers = [createMockPlayer()];

      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers())
          .thenAnswer((_) async => mockPlayers);
      when(() => mockDraftRepo.makePick(1, 1, 100))
          .thenAnswer((_) async => {'success': true});

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      // Act
      final notifier = container!.read(draftRoomProvider(key).notifier);
      final success = await notifier.makePick(100);

      // Assert
      expect(success, true);
      verify(() => mockDraftRepo.makePick(1, 1, 100)).called(1);
    });

    test('makePick failure should return false', () async {
      // Arrange
      final mockDraft = createMockDraft();

      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers())
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.makePick(1, 1, 100))
          .thenThrow(Exception('Not your turn'));

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      // Act
      final notifier = container!.read(draftRoomProvider(key).notifier);
      final success = await notifier.makePick(100);

      // Assert
      expect(success, false);
    });
  });

  group('DraftRoomNotifier - dispose', () {
    test('dispose should leave draft room and cleanup socket listeners', () async {
      // Arrange
      final mockDraft = createMockDraft();

      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers())
          .thenAnswer((_) async => []);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      // Read provider to trigger initialization
      container!.read(draftRoomProvider(key));
      await Future.delayed(const Duration(milliseconds: 300));

      // Act - dispose the container (which disposes the notifier)
      container!.dispose();
      container = null; // Prevent double-dispose in tearDown

      // Assert - verify leaveDraft was called
      // (disposers are called internally but we can't verify VoidCallback calls)
      verify(() => mockSocketService.leaveDraft(1)).called(1);
    });
  });
}
