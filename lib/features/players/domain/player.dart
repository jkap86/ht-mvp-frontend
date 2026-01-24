import 'package:freezed_annotation/freezed_annotation.dart';

part 'player.freezed.dart';
part 'player.g.dart';

@freezed
class Player with _$Player {
  const factory Player({
    required int id,
    @JsonKey(name: 'sleeper_id') required String sleeperId,
    @JsonKey(name: 'first_name') String? firstName,
    @JsonKey(name: 'last_name') String? lastName,
    @JsonKey(name: 'fantasy_positions') required List<String> fantasyPositions,
    @JsonKey(name: 'years_exp') int? yearsExp,
    int? age,
    String? team,
    String? position,
    @JsonKey(name: 'jersey_number') int? number,
    String? status,
    @JsonKey(name: 'injury_status') String? injuryStatus,
    bool? active,
    // Fantasy stats
    @JsonKey(name: 'prior_season_pts') double? priorSeasonPts,
    @JsonKey(name: 'season_to_date_pts') double? seasonToDatePts,
    @JsonKey(name: 'remaining_projected_pts') double? remainingProjectedPts,
  }) = _Player;

  factory Player.fromJson(Map<String, dynamic> json) => _$PlayerFromJson(json);
}

extension PlayerExtensions on Player {
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName ?? 'Unknown';
  }

  String get primaryPosition => fantasyPositions.isNotEmpty ? fantasyPositions.first : position ?? 'UNKNOWN';
}
