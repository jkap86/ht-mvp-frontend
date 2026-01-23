// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlayerImpl _$$PlayerImplFromJson(Map<String, dynamic> json) => _$PlayerImpl(
      id: (json['id'] as num).toInt(),
      sleeperId: json['sleeper_id'] as String,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      fantasyPositions: (json['fantasy_positions'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      yearsExp: (json['years_exp'] as num?)?.toInt(),
      age: (json['age'] as num?)?.toInt(),
      team: json['team'] as String?,
      position: json['position'] as String?,
      number: (json['number'] as num?)?.toInt(),
      status: json['status'] as String?,
      injuryStatus: json['injury_status'] as String?,
      active: json['active'] as bool?,
      priorSeasonPts: (json['prior_season_pts'] as num?)?.toDouble(),
      seasonToDatePts: (json['season_to_date_pts'] as num?)?.toDouble(),
      remainingProjectedPts:
          (json['remaining_projected_pts'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$PlayerImplToJson(_$PlayerImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sleeper_id': instance.sleeperId,
      'first_name': instance.firstName,
      'last_name': instance.lastName,
      'fantasy_positions': instance.fantasyPositions,
      'years_exp': instance.yearsExp,
      'age': instance.age,
      'team': instance.team,
      'position': instance.position,
      'number': instance.number,
      'status': instance.status,
      'injury_status': instance.injuryStatus,
      'active': instance.active,
      'prior_season_pts': instance.priorSeasonPts,
      'season_to_date_pts': instance.seasonToDatePts,
      'remaining_projected_pts': instance.remainingProjectedPts,
    };
