import 'player_dtos.dart';

class GetPlayerResponse {
  final PlayerDto player;

  const GetPlayerResponse({required this.player});

  factory GetPlayerResponse.fromJson(Map<String, dynamic> json) {
    return GetPlayerResponse(player: PlayerDto.fromJson(json));
  }
}

class SearchPlayersResponse {
  final List<PlayerDto> players;
  final int total;

  const SearchPlayersResponse({required this.players, required this.total});

  factory SearchPlayersResponse.fromJson(Map<String, dynamic> json) {
    return SearchPlayersResponse(
      players: (json['players'] as List<dynamic>?)
              ?.map((p) => PlayerDto.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      total: json['total'] as int? ?? 0,
    );
  }
}

class PlayerNewsResponse {
  final List<PlayerNewsDto> news;

  const PlayerNewsResponse({required this.news});

  factory PlayerNewsResponse.fromJson(Map<String, dynamic> json) {
    return PlayerNewsResponse(
      news: (json['news'] as List<dynamic>?)
              ?.map((n) => PlayerNewsDto.fromJson(n as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
