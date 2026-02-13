import 'matchup_dtos.dart';

class ListMatchupsResponse {
  final List<MatchupDto> matchups;

  const ListMatchupsResponse({required this.matchups});

  factory ListMatchupsResponse.fromJson(List<dynamic> json) {
    return ListMatchupsResponse(
      matchups: json.map((m) => MatchupDto.fromJson(m as Map<String, dynamic>)).toList(),
    );
  }
}

class GetMatchupDetailResponse {
  final MatchupDetailDto detail;

  const GetMatchupDetailResponse({required this.detail});

  factory GetMatchupDetailResponse.fromJson(Map<String, dynamic> json) {
    return GetMatchupDetailResponse(detail: MatchupDetailDto.fromJson(json));
  }
}
