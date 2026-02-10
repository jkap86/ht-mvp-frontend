import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../leagues/data/league_repository.dart';
import '../../leagues/domain/league.dart';
import '../../matchups/data/matchup_repository.dart';
import '../../playoffs/data/playoff_repository.dart';
import '../../playoffs/domain/playoff.dart';
import '../../waivers/data/waiver_repository.dart';

/// Commissioner data bundle returned by loadCommissionerData
class CommissionerData {
  final League league;
  final List<Map<String, dynamic>> members;
  final PlayoffBracketView? bracketView;

  CommissionerData({
    required this.league,
    required this.members,
    this.bracketView,
  });
}

/// Facade repository that encapsulates all commissioner-related operations.
///
/// This consolidates cross-feature dependencies (leagues, matchups, playoffs, waivers)
/// into a single repository, reducing coupling in the provider layer.
class CommissionerRepository {
  final LeagueRepository _leagueRepo;
  final MatchupRepository _matchupRepo;
  final PlayoffRepository _playoffRepo;
  final WaiverRepository _waiverRepo;

  CommissionerRepository({
    required LeagueRepository leagueRepo,
    required MatchupRepository matchupRepo,
    required PlayoffRepository playoffRepo,
    required WaiverRepository waiverRepo,
  })  : _leagueRepo = leagueRepo,
        _matchupRepo = matchupRepo,
        _playoffRepo = playoffRepo,
        _waiverRepo = waiverRepo;

  // ============================================================
  // Data Loading
  // ============================================================

  /// Load all commissioner dashboard data in parallel
  Future<CommissionerData> loadCommissionerData(int leagueId) async {
    final results = await Future.wait([
      _leagueRepo.getLeague(leagueId),
      _leagueRepo.getMembers(leagueId),
      _playoffRepo.getBracket(leagueId),
    ]);

    return CommissionerData(
      league: results[0] as League,
      members: results[1] as List<Map<String, dynamic>>,
      bracketView: results[2] as PlayoffBracketView?,
    );
  }

  /// Get current league
  Future<League> getLeague(int leagueId) {
    return _leagueRepo.getLeague(leagueId);
  }

  /// Get league members
  Future<List<Map<String, dynamic>>> getMembers(int leagueId) {
    return _leagueRepo.getMembers(leagueId);
  }

  // ============================================================
  // Member Management
  // ============================================================

  /// Kick a member from the league
  Future<void> kickMember(int leagueId, int rosterId, {String? idempotencyKey}) {
    return _leagueRepo.kickMember(leagueId, rosterId, idempotencyKey: idempotencyKey);
  }

  // ============================================================
  // League Management
  // ============================================================

  /// Delete the league (requires confirmationName to match league name)
  Future<void> deleteLeague(int leagueId, {required String confirmationName, String? idempotencyKey}) {
    return _leagueRepo.deleteLeague(leagueId, confirmationName: confirmationName, idempotencyKey: idempotencyKey);
  }

  /// Update season controls (season status and/or current week)
  Future<League> updateSeasonControls(
    int leagueId, {
    String? seasonStatus,
    int? currentWeek,
    String? idempotencyKey,
  }) {
    return _leagueRepo.updateSeasonControls(
      leagueId,
      seasonStatus: seasonStatus,
      currentWeek: currentWeek,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Reset the league for a new season
  Future<void> resetLeague(
    int leagueId, {
    required String newSeason,
    required String confirmationName,
    bool keepMembers = false,
    bool clearChat = true,
    String? idempotencyKey,
  }) {
    return _leagueRepo.resetLeague(
      leagueId,
      newSeason: newSeason,
      confirmationName: confirmationName,
      keepMembers: keepMembers,
      clearChat: clearChat,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Update league settings
  Future<League> updateLeague(
    int leagueId, {
    String? name,
    String? mode,
    bool? isPublic,
    Map<String, dynamic>? settings,
    Map<String, dynamic>? leagueSettings,
    Map<String, dynamic>? scoringSettings,
    int? totalRosters,
    String? idempotencyKey,
  }) {
    return _leagueRepo.updateLeague(
      leagueId,
      name: name,
      mode: mode,
      isPublic: isPublic,
      settings: settings,
      leagueSettings: leagueSettings,
      scoringSettings: scoringSettings,
      totalRosters: totalRosters,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Reinstate a benched member
  Future<void> reinstateMember(int leagueId, int rosterId, {String? idempotencyKey}) {
    return _leagueRepo.reinstateMember(leagueId, rosterId, idempotencyKey: idempotencyKey);
  }

  // ============================================================
  // Schedule Management
  // ============================================================

  /// Generate regular season schedule
  Future<void> generateSchedule(int leagueId, {required int weeks, String? idempotencyKey}) {
    return _matchupRepo.generateSchedule(leagueId, weeks: weeks, idempotencyKey: idempotencyKey);
  }

  /// Finalize matchups for a week
  Future<void> finalizeMatchups(int leagueId, int week, {String? idempotencyKey}) {
    return _matchupRepo.finalizeMatchups(leagueId, week, idempotencyKey: idempotencyKey);
  }

  // ============================================================
  // Playoff Management
  // ============================================================

  /// Generate playoff bracket
  ///
  /// Optional parameters:
  /// - weeksByRound: Array of weeks per round (e.g., [1, 2, 2] for multi-week series)
  /// - enableThirdPlaceGame: Enable 3rd place game
  /// - consolationType: 'NONE' or 'CONSOLATION'
  /// - consolationTeams: 4, 6, or 8 (null for auto)
  Future<PlayoffBracketView> generatePlayoffBracket(
    int leagueId, {
    required int playoffTeams,
    required int startWeek,
    List<int>? weeksByRound,
    bool? enableThirdPlaceGame,
    String? consolationType,
    int? consolationTeams,
    String? idempotencyKey,
  }) {
    return _playoffRepo.generateBracket(
      leagueId,
      playoffTeams: playoffTeams,
      startWeek: startWeek,
      weeksByRound: weeksByRound,
      enableThirdPlaceGame: enableThirdPlaceGame,
      consolationType: consolationType,
      consolationTeams: consolationTeams,
      idempotencyKey: idempotencyKey,
    );
  }

  /// Advance playoff winners to next round
  Future<PlayoffBracketView> advanceWinners(int leagueId, int week, {String? idempotencyKey}) {
    return _playoffRepo.advanceWinners(leagueId, week, idempotencyKey: idempotencyKey);
  }

  /// Get current playoff bracket
  Future<PlayoffBracketView?> getBracket(int leagueId) {
    return _playoffRepo.getBracket(leagueId);
  }

  // ============================================================
  // Waiver Management
  // ============================================================

  /// Initialize waiver system for the league
  Future<void> initializeWaivers(int leagueId, {int? faabBudget, String? idempotencyKey}) {
    return _waiverRepo.initializeWaivers(leagueId, faabBudget: faabBudget, idempotencyKey: idempotencyKey);
  }

  /// Process pending waiver claims
  Future<Map<String, dynamic>> processWaivers(int leagueId, {String? idempotencyKey}) {
    return _waiverRepo.processWaivers(leagueId, idempotencyKey: idempotencyKey);
  }
}

/// Provider for CommissionerRepository
final commissionerRepositoryProvider = Provider<CommissionerRepository>((ref) {
  return CommissionerRepository(
    leagueRepo: ref.watch(leagueRepositoryProvider),
    matchupRepo: ref.watch(matchupRepositoryProvider),
    playoffRepo: ref.watch(playoffRepositoryProvider),
    waiverRepo: ref.watch(waiverRepositoryProvider),
  );
});
