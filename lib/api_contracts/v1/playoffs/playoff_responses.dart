import 'playoff_dtos.dart';

class GetBracketResponse {
  final PlayoffBracketDto bracket;
  final List<PlayoffRoundDto> rounds;

  const GetBracketResponse({required this.bracket, required this.rounds});

  factory GetBracketResponse.fromJson(Map<String, dynamic> json) {
    return GetBracketResponse(
      bracket: PlayoffBracketDto.fromJson(json['bracket'] as Map<String, dynamic>? ?? json),
      rounds: (json['rounds'] as List<dynamic>?)
              ?.map((r) => PlayoffRoundDto.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
