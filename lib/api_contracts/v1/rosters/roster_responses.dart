import 'roster_dtos.dart';

class GetRosterPlayersResponse {
  final List<RosterPlayerDto> players;

  const GetRosterPlayersResponse({required this.players});

  factory GetRosterPlayersResponse.fromJson(List<dynamic> json) {
    return GetRosterPlayersResponse(
      players: json.map((p) => RosterPlayerDto.fromJson(p as Map<String, dynamic>)).toList(),
    );
  }
}

class GetLineupResponse {
  final RosterLineupDto lineup;

  const GetLineupResponse({required this.lineup});

  factory GetLineupResponse.fromJson(Map<String, dynamic> json) {
    return GetLineupResponse(lineup: RosterLineupDto.fromJson(json));
  }
}

class AddDropResponse {
  final Map<String, dynamic> result;

  const AddDropResponse({required this.result});

  factory AddDropResponse.fromJson(Map<String, dynamic> json) {
    return AddDropResponse(result: json);
  }
}
