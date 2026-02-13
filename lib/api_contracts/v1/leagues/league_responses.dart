import 'league_dtos.dart';

class GetLeagueResponse {
  final LeagueDto league;
  final List<RosterDto> rosters;

  const GetLeagueResponse({required this.league, this.rosters = const []});

  factory GetLeagueResponse.fromJson(Map<String, dynamic> json) {
    final rostersJson = json['rosters'] as List<dynamic>? ?? [];
    return GetLeagueResponse(
      league: LeagueDto.fromJson(json),
      rosters: rostersJson.map((r) => RosterDto.fromJson(r as Map<String, dynamic>)).toList(),
    );
  }
}

class ListLeaguesResponse {
  final List<LeagueDto> leagues;

  const ListLeaguesResponse({required this.leagues});

  factory ListLeaguesResponse.fromJson(List<dynamic> json) {
    return ListLeaguesResponse(
      leagues: json.map((l) => LeagueDto.fromJson(l as Map<String, dynamic>)).toList(),
    );
  }
}

class DashboardResponse {
  final Map<String, dynamic> data;

  const DashboardResponse({required this.data});

  factory DashboardResponse.fromJson(Map<String, dynamic> json) {
    return DashboardResponse(data: json);
  }
}

class StandingsResponse {
  final List<Map<String, dynamic>> standings;

  const StandingsResponse({required this.standings});

  factory StandingsResponse.fromJson(List<dynamic> json) {
    return StandingsResponse(
      standings: json.cast<Map<String, dynamic>>(),
    );
  }
}

class FreeAgentsResponse {
  final List<Map<String, dynamic>> players;
  final int total;

  const FreeAgentsResponse({required this.players, required this.total});

  factory FreeAgentsResponse.fromJson(Map<String, dynamic> json) {
    return FreeAgentsResponse(
      players: (json['players'] as List<dynamic>?)?.cast<Map<String, dynamic>>() ?? [],
      total: json['total'] as int? ?? 0,
    );
  }
}
