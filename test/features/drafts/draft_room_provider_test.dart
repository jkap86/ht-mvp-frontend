import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/drafts/presentation/providers/draft_room_provider.dart';
import 'package:hypetrain_mvp/features/drafts/data/draft_repository.dart';
import 'package:hypetrain_mvp/features/drafts/data/draft_pick_asset_repository.dart';
import 'package:hypetrain_mvp/features/drafts/domain/draft_pick.dart';
import 'package:hypetrain_mvp/features/drafts/domain/draft_pick_asset.dart';
import 'package:hypetrain_mvp/features/drafts/domain/draft_status.dart';
import 'package:hypetrain_mvp/features/drafts/domain/draft_type.dart';
import 'package:hypetrain_mvp/features/players/data/player_repository.dart';
import 'package:hypetrain_mvp/features/players/domain/player.dart';
import 'package:hypetrain_mvp/features/leagues/domain/league.dart';
import 'package:hypetrain_mvp/features/auth/presentation/auth_provider.dart';
import 'package:hypetrain_mvp/features/auth/domain/user.dart';
import 'package:hypetrain_mvp/core/api/api_exceptions.dart';
import 'package:hypetrain_mvp/core/socket/socket_service.dart';
import 'package:hypetrain_mvp/core/providers/league_context_provider.dart';
import 'package:hypetrain_mvp/features/leagues/data/league_repository.dart';

import '../../mocks/mock_repositories.dart';
import '../../mocks/mock_socket_service.dart';

class MockDraftPickAssetRepository extends Mock implements DraftPickAssetRepository {}

/// Mock AuthNotifier for testing - provides stable state without async operations
class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier()
      : super(AuthState(
          user: User(id: '1', username: 'testuser', email: 'test@test.com'),
        ));

  @override
  Future<bool> login(String username, String password) async => true;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> register(String username, String email, String password) async => true;

  @override
  void clearError() {}
}

// Test data helpers
Draft createMockDraft({
  int id = 1,
  DraftStatus status = DraftStatus.inProgress,
  DraftType draftType = DraftType.snake,
}) {
  return Draft(
    id: id,
    leagueId: 1,
    draftType: draftType,
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
  late MockDraftPickAssetRepository mockPickAssetRepo;
  late MockLeagueRepository mockLeagueRepo;
  ProviderContainer? container;

  setUp(() {
    mockDraftRepo = MockDraftRepository();
    mockPlayerRepo = MockPlayerRepository();
    mockSocketService = MockSocketService();
    mockPickAssetRepo = MockDraftPickAssetRepository();
    mockLeagueRepo = MockLeagueRepository();

    // Default mock for pick assets (empty list)
    when(() => mockPickAssetRepo.getLeaguePickAssets(any()))
        .thenAnswer((_) async => <DraftPickAsset>[]);

    // Default mock for league repository
    when(() => mockLeagueRepo.getLeagueMembers(any()))
        .thenAnswer((_) async => <Roster>[]);
    when(() => mockLeagueRepo.getLeague(any()))
        .thenAnswer((_) async => League(
              id: 1,
              name: 'Test League',
              status: 'active',
              season: 2025,
              settings: {},
              totalRosters: 10,
            ));

    // Setup default socket service mocks
    // The on* methods return VoidCallback disposers (always non-null, queued if not connected)
    when(() => mockSocketService.joinDraft(any())).thenReturn(null);
    when(() => mockSocketService.leaveDraft(any())).thenReturn(null);
    when(() => mockSocketService.onDraftPick(any())).thenReturn(() {});
    when(() => mockSocketService.onNextPick(any())).thenReturn(() {});
    when(() => mockSocketService.onDraftCompleted(any())).thenReturn(() {});
    when(() => mockSocketService.onPickUndone(any())).thenReturn(() {});
    when(() => mockSocketService.onDraftPaused(any())).thenReturn(() {});
    when(() => mockSocketService.onDraftResumed(any())).thenReturn(() {});
    when(() => mockSocketService.onOvernightPauseStarted(any())).thenReturn(() {});
    when(() => mockSocketService.onOvernightPauseEnded(any())).thenReturn(() {});
    // Auction socket listeners
    when(() => mockSocketService.onAuctionLotCreated(any())).thenReturn(() {});
    when(() => mockSocketService.onAuctionLotUpdated(any())).thenReturn(() {});
    when(() => mockSocketService.onAuctionLotWon(any())).thenReturn(() {});
    when(() => mockSocketService.onAuctionLotPassed(any())).thenReturn(() {});
    when(() => mockSocketService.onAuctionOutbid(any())).thenReturn(() {});
    when(() => mockSocketService.onAuctionNominatorChanged(any())).thenReturn(() {});
    when(() => mockSocketService.onAuctionError(any())).thenReturn(() {});
    // Additional socket listeners
    when(() => mockSocketService.onAutodraftToggled(any())).thenReturn(() {});
    when(() => mockSocketService.onDraftPickTraded(any())).thenReturn(() {});
    when(() => mockSocketService.onDraftSettingsUpdated(any())).thenReturn(() {});
    // Derby socket listeners
    when(() => mockSocketService.onDerbyState(any())).thenReturn(() {});
    when(() => mockSocketService.onDerbySlotPicked(any())).thenReturn(() {});
    when(() => mockSocketService.onDerbyTurnChanged(any())).thenReturn(() {});
    when(() => mockSocketService.onDerbyPhaseTransition(any())).thenReturn(() {});
    // Reconnection and membership listeners
    when(() => mockSocketService.onReconnected(any())).thenReturn(() {});
    when(() => mockSocketService.onMemberKicked(any())).thenReturn(() {});
    when(() => mockSocketService.joinLeague(any())).thenReturn(null);
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
        draftPickAssetRepositoryProvider.overrideWithValue(mockPickAssetRepo),
        leagueRepositoryProvider.overrideWithValue(mockLeagueRepo),
        // Override authStateProvider with a stable state to prevent async updates
        authStateProvider.overrideWith((ref) => MockAuthNotifier()),
        // Override leagueContextProvider to prevent autoDispose rebuilds in tests
        leagueContextProvider.overrideWith((ref, leagueId) async => LeagueContext(
              league: League(
                id: leagueId,
                name: 'Test League',
                status: 'active',
                season: 2025,
                settings: {},
                totalRosters: 10,
              ),
              userRosterId: null,
              isCommissioner: false,
            )),
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
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => mockPlayers);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);

      // Use listen to keep autoDispose provider alive during test
      container!.listen(draftRoomProvider(key), (_, __) {});

      // Wait for leagueContextProvider to resolve (causes provider rebuild)
      // and for the rebuilt notifier's constructor loadData to complete
      await Future.delayed(const Duration(milliseconds: 500));

      // Read the stable (post-rebuild) notifier and call loadData
      final notifier = container!.read(draftRoomProvider(key).notifier);
      await notifier.loadData();

      // Assert
      final state = container!.read(draftRoomProvider(key));
      expect(state.draft?.id, 1);
      expect(state.players.length, 2);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('loadData failure should set error', () async {
      // Arrange
      when(() => mockDraftRepo.getDraft(1, 1))
          .thenThrow(Exception('Failed to load'));
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);

      // Trigger provider creation and call loadData directly
      final notifier = container!.read(draftRoomProvider(key).notifier);
      await notifier.loadData();

      // Assert
      final state = container!.read(draftRoomProvider(key));
      expect(state.error, isNotNull);
      expect(state.isLoading, false);
    });
  });

  group('DraftRoomNotifier - makePick', () {
    test('makePick success should return null', () async {
      // Arrange
      final mockDraft = createMockDraft();
      final mockPlayers = [createMockPlayer()];

      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => mockPlayers);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.makePick(1, 1, 100))
          .thenAnswer((_) async => {'success': true});

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      // Act
      final notifier = container!.read(draftRoomProvider(key).notifier);
      final result = await notifier.makePick(100);

      // Assert - null means success
      expect(result, isNull);
      verify(() => mockDraftRepo.makePick(1, 1, 100)).called(1);
    });

    test('makePick failure should return error message', () async {
      // Arrange
      final mockDraft = createMockDraft();

      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.makePick(1, 1, 100))
          .thenThrow(ValidationException('Not your turn'));

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      // Act
      final notifier = container!.read(draftRoomProvider(key).notifier);
      final result = await notifier.makePick(100);

      // Assert - non-null means error
      expect(result, isNotNull);
      expect(result, contains('Not your turn'));
    });
  });

  group('DraftRoomNotifier - dispose', () {
    test('dispose should leave draft room and cleanup socket listeners', () async {
      // Arrange
      final mockDraft = createMockDraft();

      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

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

  group('DraftRoomNotifier - pick deduplication', () {
    test('onPickReceived should ignore duplicate picks with same id', () async {
      // Arrange
      final mockDraft = createMockDraft();
      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      final notifier = container!.read(draftRoomProvider(key).notifier);

      // Act - receive the same pick twice (simulating socket replay)
      final pick = DraftPick(
        id: 1,
        draftId: 1,
        pickNumber: 1,
        round: 1,
        pickInRound: 1,
        rosterId: 1,
        playerId: 100,
      );
      notifier.onPickReceived(pick);
      notifier.onPickReceived(pick); // Duplicate - should be ignored

      // Assert - only one pick should be in state
      final state = container!.read(draftRoomProvider(key));
      expect(state.picks.length, 1);
      expect(state.picks.first.id, 1);
    });

    test('onPickReceived should add picks with different ids', () async {
      // Arrange
      final mockDraft = createMockDraft();
      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      final notifier = container!.read(draftRoomProvider(key).notifier);

      // Act - receive multiple different picks
      final pick1 = DraftPick(
        id: 1,
        draftId: 1,
        pickNumber: 1,
        round: 1,
        pickInRound: 1,
        rosterId: 1,
        playerId: 100,
      );
      final pick2 = DraftPick(
        id: 2,
        draftId: 1,
        pickNumber: 2,
        round: 1,
        pickInRound: 2,
        rosterId: 2,
        playerId: 101,
      );
      notifier.onPickReceived(pick1);
      notifier.onPickReceived(pick2);

      // Assert - both picks should be in state
      final state = container!.read(draftRoomProvider(key));
      expect(state.picks.length, 2);
      expect(state.picks.map((p) => p.id).toSet(), {1, 2});
    });

    test('onPickReceived during reconnect replay should dedupe correctly', () async {
      // Arrange - start with some existing picks
      final mockDraft = createMockDraft();
      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => [
            {'id': 1, 'draftId': 1, 'pickNumber': 1, 'round': 1, 'pickInRound': 1, 'rosterId': 1, 'playerId': 100},
            {'id': 2, 'draftId': 1, 'pickNumber': 2, 'round': 1, 'pickInRound': 2, 'rosterId': 2, 'playerId': 101},
          ]);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      final notifier = container!.read(draftRoomProvider(key).notifier);

      // Act - simulate reconnect replay: receive all picks again plus a new one
      final existingPick1 = DraftPick(
        id: 1,
        draftId: 1,
        pickNumber: 1,
        round: 1,
        pickInRound: 1,
        rosterId: 1,
        playerId: 100,
      );
      final existingPick2 = DraftPick(
        id: 2,
        draftId: 1,
        pickNumber: 2,
        round: 1,
        pickInRound: 2,
        rosterId: 2,
        playerId: 101,
      );
      final newPick3 = DraftPick(
        id: 3,
        draftId: 1,
        pickNumber: 3,
        round: 1,
        pickInRound: 3,
        rosterId: 3,
        playerId: 102,
      );

      // Replay existing picks (should be deduped)
      notifier.onPickReceived(existingPick1);
      notifier.onPickReceived(existingPick2);
      // New pick (should be added)
      notifier.onPickReceived(newPick3);

      // Assert - should have exactly 3 unique picks
      final state = container!.read(draftRoomProvider(key));
      expect(state.picks.length, 3);
      expect(state.picks.map((p) => p.id).toSet(), {1, 2, 3});
    });
  });

  group('DraftRoomNotifier - undo pick', () {
    test('onPickUndoneReceived should remove pick from state', () async {
      // Arrange - set up provider with empty initial picks
      final mockDraft = createMockDraft();
      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      final notifier = container!.read(draftRoomProvider(key).notifier);

      // Manually add picks via onPickReceived (simulating socket events)
      final pick1 = DraftPick(
        id: 1, draftId: 1, pickNumber: 1, round: 1, pickInRound: 1, rosterId: 1, playerId: 100,
      );
      final pick2 = DraftPick(
        id: 2, draftId: 1, pickNumber: 2, round: 1, pickInRound: 2, rosterId: 2, playerId: 101,
      );
      notifier.onPickReceived(pick1);
      notifier.onPickReceived(pick2);

      // Verify we have 2 picks before undo
      var state = container!.read(draftRoomProvider(key));
      expect(state.picks.length, 2);

      // Act - undo pick 2 (Draft.fromJson uses snake_case)
      notifier.onPickUndoneReceived({
        'pick': {'id': 2, 'pickNumber': 2},
        'draft': <String, dynamic>{
          'id': 1,
          'league_id': 1,
          'draft_type': 'snake',
          'status': 'in_progress',
          'rounds': 15,
          'pick_time_seconds': 90,
          'current_pick': 2,
          'current_round': 1,
          'current_roster_id': 1,
        },
      });

      // Assert - pick 2 should be removed, only pick 1 remains
      state = container!.read(draftRoomProvider(key));
      expect(state.picks.length, 1);
      expect(state.picks.first.id, 1);
    });

    test('onPickUndoneReceived should update draft state', () async {
      // Arrange
      final mockDraft = createMockDraft(status: DraftStatus.inProgress);
      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      final notifier = container!.read(draftRoomProvider(key).notifier);

      // Add a pick first
      final pick1 = DraftPick(
        id: 1, draftId: 1, pickNumber: 1, round: 1, pickInRound: 1, rosterId: 1, playerId: 100,
      );
      notifier.onPickReceived(pick1);

      // Act - undo pick and get updated draft state (Draft.fromJson uses snake_case)
      notifier.onPickUndoneReceived({
        'pick': {'id': 1, 'pickNumber': 1},
        'draft': <String, dynamic>{
          'id': 1,
          'league_id': 1,
          'draft_type': 'snake',
          'status': 'in_progress',
          'rounds': 15,
          'pick_time_seconds': 90,
          'current_pick': 1,
          'current_round': 1,
          'current_roster_id': 1,
        },
      });

      // Assert - draft state should be updated
      final state = container!.read(draftRoomProvider(key));
      expect(state.picks.length, 0); // Pick was removed
      expect(state.draft?.currentPick, 1); // Current pick reverted
    });

    test('onPickUndoneReceived with missing pick id should not remove any picks', () async {
      // Arrange
      final mockDraft = createMockDraft();
      when(() => mockDraftRepo.getDraft(1, 1))
          .thenAnswer((_) async => mockDraft);
      when(() => mockPlayerRepo.getPlayers(playerPool: any(named: 'playerPool')))
          .thenAnswer((_) async => []);
      when(() => mockDraftRepo.getDraftOrder(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);
      when(() => mockDraftRepo.getDraftPicks(1, 1))
          .thenAnswer((_) async => <Map<String, dynamic>>[]);

      container = createContainer();
      final key = (leagueId: 1, draftId: 1);
      await Future.delayed(const Duration(milliseconds: 300));

      final notifier = container!.read(draftRoomProvider(key).notifier);

      // Add a pick first
      final pick1 = DraftPick(
        id: 1, draftId: 1, pickNumber: 1, round: 1, pickInRound: 1, rosterId: 1, playerId: 100,
      );
      notifier.onPickReceived(pick1);

      // Act - send undo data with missing pick id
      notifier.onPickUndoneReceived({
        'pick': <String, dynamic>{}, // Missing 'id'
        'draft': null,
      });

      // Assert - should not crash, picks unchanged
      final state = container!.read(draftRoomProvider(key));
      expect(state.picks.length, 1);
    });
  });
}
