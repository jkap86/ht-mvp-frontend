// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'player.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Player _$PlayerFromJson(Map<String, dynamic> json) {
  return _Player.fromJson(json);
}

/// @nodoc
mixin _$Player {
  int get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'sleeper_id')
  String get sleeperId => throw _privateConstructorUsedError;
  @JsonKey(name: 'first_name')
  String? get firstName => throw _privateConstructorUsedError;
  @JsonKey(name: 'last_name')
  String? get lastName => throw _privateConstructorUsedError;
  @JsonKey(name: 'fantasy_positions')
  List<String> get fantasyPositions => throw _privateConstructorUsedError;
  @JsonKey(name: 'years_exp')
  int? get yearsExp => throw _privateConstructorUsedError;
  int? get age => throw _privateConstructorUsedError;
  String? get team => throw _privateConstructorUsedError;
  String? get position => throw _privateConstructorUsedError;
  @JsonKey(name: 'jersey_number')
  int? get number => throw _privateConstructorUsedError;
  String? get status => throw _privateConstructorUsedError;
  @JsonKey(name: 'injury_status')
  String? get injuryStatus => throw _privateConstructorUsedError;
  bool? get active => throw _privateConstructorUsedError; // Fantasy stats
  @JsonKey(name: 'prior_season_pts')
  double? get priorSeasonPts => throw _privateConstructorUsedError;
  @JsonKey(name: 'season_to_date_pts')
  double? get seasonToDatePts => throw _privateConstructorUsedError;
  @JsonKey(name: 'remaining_projected_pts')
  double? get remainingProjectedPts => throw _privateConstructorUsedError;

  /// Serializes this Player to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlayerCopyWith<Player> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlayerCopyWith<$Res> {
  factory $PlayerCopyWith(Player value, $Res Function(Player) then) =
      _$PlayerCopyWithImpl<$Res, Player>;
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'sleeper_id') String sleeperId,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'fantasy_positions') List<String> fantasyPositions,
      @JsonKey(name: 'years_exp') int? yearsExp,
      int? age,
      String? team,
      String? position,
      @JsonKey(name: 'jersey_number') int? number,
      String? status,
      @JsonKey(name: 'injury_status') String? injuryStatus,
      bool? active,
      @JsonKey(name: 'prior_season_pts') double? priorSeasonPts,
      @JsonKey(name: 'season_to_date_pts') double? seasonToDatePts,
      @JsonKey(name: 'remaining_projected_pts') double? remainingProjectedPts});
}

/// @nodoc
class _$PlayerCopyWithImpl<$Res, $Val extends Player>
    implements $PlayerCopyWith<$Res> {
  _$PlayerCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sleeperId = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? fantasyPositions = null,
    Object? yearsExp = freezed,
    Object? age = freezed,
    Object? team = freezed,
    Object? position = freezed,
    Object? number = freezed,
    Object? status = freezed,
    Object? injuryStatus = freezed,
    Object? active = freezed,
    Object? priorSeasonPts = freezed,
    Object? seasonToDatePts = freezed,
    Object? remainingProjectedPts = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      sleeperId: null == sleeperId
          ? _value.sleeperId
          : sleeperId // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      fantasyPositions: null == fantasyPositions
          ? _value.fantasyPositions
          : fantasyPositions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      yearsExp: freezed == yearsExp
          ? _value.yearsExp
          : yearsExp // ignore: cast_nullable_to_non_nullable
              as int?,
      age: freezed == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int?,
      team: freezed == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as String?,
      position: freezed == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String?,
      number: freezed == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      injuryStatus: freezed == injuryStatus
          ? _value.injuryStatus
          : injuryStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      active: freezed == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool?,
      priorSeasonPts: freezed == priorSeasonPts
          ? _value.priorSeasonPts
          : priorSeasonPts // ignore: cast_nullable_to_non_nullable
              as double?,
      seasonToDatePts: freezed == seasonToDatePts
          ? _value.seasonToDatePts
          : seasonToDatePts // ignore: cast_nullable_to_non_nullable
              as double?,
      remainingProjectedPts: freezed == remainingProjectedPts
          ? _value.remainingProjectedPts
          : remainingProjectedPts // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PlayerImplCopyWith<$Res> implements $PlayerCopyWith<$Res> {
  factory _$$PlayerImplCopyWith(
          _$PlayerImpl value, $Res Function(_$PlayerImpl) then) =
      __$$PlayerImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int id,
      @JsonKey(name: 'sleeper_id') String sleeperId,
      @JsonKey(name: 'first_name') String? firstName,
      @JsonKey(name: 'last_name') String? lastName,
      @JsonKey(name: 'fantasy_positions') List<String> fantasyPositions,
      @JsonKey(name: 'years_exp') int? yearsExp,
      int? age,
      String? team,
      String? position,
      @JsonKey(name: 'jersey_number') int? number,
      String? status,
      @JsonKey(name: 'injury_status') String? injuryStatus,
      bool? active,
      @JsonKey(name: 'prior_season_pts') double? priorSeasonPts,
      @JsonKey(name: 'season_to_date_pts') double? seasonToDatePts,
      @JsonKey(name: 'remaining_projected_pts') double? remainingProjectedPts});
}

/// @nodoc
class __$$PlayerImplCopyWithImpl<$Res>
    extends _$PlayerCopyWithImpl<$Res, _$PlayerImpl>
    implements _$$PlayerImplCopyWith<$Res> {
  __$$PlayerImplCopyWithImpl(
      _$PlayerImpl _value, $Res Function(_$PlayerImpl) _then)
      : super(_value, _then);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? sleeperId = null,
    Object? firstName = freezed,
    Object? lastName = freezed,
    Object? fantasyPositions = null,
    Object? yearsExp = freezed,
    Object? age = freezed,
    Object? team = freezed,
    Object? position = freezed,
    Object? number = freezed,
    Object? status = freezed,
    Object? injuryStatus = freezed,
    Object? active = freezed,
    Object? priorSeasonPts = freezed,
    Object? seasonToDatePts = freezed,
    Object? remainingProjectedPts = freezed,
  }) {
    return _then(_$PlayerImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as int,
      sleeperId: null == sleeperId
          ? _value.sleeperId
          : sleeperId // ignore: cast_nullable_to_non_nullable
              as String,
      firstName: freezed == firstName
          ? _value.firstName
          : firstName // ignore: cast_nullable_to_non_nullable
              as String?,
      lastName: freezed == lastName
          ? _value.lastName
          : lastName // ignore: cast_nullable_to_non_nullable
              as String?,
      fantasyPositions: null == fantasyPositions
          ? _value._fantasyPositions
          : fantasyPositions // ignore: cast_nullable_to_non_nullable
              as List<String>,
      yearsExp: freezed == yearsExp
          ? _value.yearsExp
          : yearsExp // ignore: cast_nullable_to_non_nullable
              as int?,
      age: freezed == age
          ? _value.age
          : age // ignore: cast_nullable_to_non_nullable
              as int?,
      team: freezed == team
          ? _value.team
          : team // ignore: cast_nullable_to_non_nullable
              as String?,
      position: freezed == position
          ? _value.position
          : position // ignore: cast_nullable_to_non_nullable
              as String?,
      number: freezed == number
          ? _value.number
          : number // ignore: cast_nullable_to_non_nullable
              as int?,
      status: freezed == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String?,
      injuryStatus: freezed == injuryStatus
          ? _value.injuryStatus
          : injuryStatus // ignore: cast_nullable_to_non_nullable
              as String?,
      active: freezed == active
          ? _value.active
          : active // ignore: cast_nullable_to_non_nullable
              as bool?,
      priorSeasonPts: freezed == priorSeasonPts
          ? _value.priorSeasonPts
          : priorSeasonPts // ignore: cast_nullable_to_non_nullable
              as double?,
      seasonToDatePts: freezed == seasonToDatePts
          ? _value.seasonToDatePts
          : seasonToDatePts // ignore: cast_nullable_to_non_nullable
              as double?,
      remainingProjectedPts: freezed == remainingProjectedPts
          ? _value.remainingProjectedPts
          : remainingProjectedPts // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PlayerImpl implements _Player {
  const _$PlayerImpl(
      {required this.id,
      @JsonKey(name: 'sleeper_id') required this.sleeperId,
      @JsonKey(name: 'first_name') this.firstName,
      @JsonKey(name: 'last_name') this.lastName,
      @JsonKey(name: 'fantasy_positions')
      required final List<String> fantasyPositions,
      @JsonKey(name: 'years_exp') this.yearsExp,
      this.age,
      this.team,
      this.position,
      @JsonKey(name: 'jersey_number') this.number,
      this.status,
      @JsonKey(name: 'injury_status') this.injuryStatus,
      this.active,
      @JsonKey(name: 'prior_season_pts') this.priorSeasonPts,
      @JsonKey(name: 'season_to_date_pts') this.seasonToDatePts,
      @JsonKey(name: 'remaining_projected_pts') this.remainingProjectedPts})
      : _fantasyPositions = fantasyPositions;

  factory _$PlayerImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlayerImplFromJson(json);

  @override
  final int id;
  @override
  @JsonKey(name: 'sleeper_id')
  final String sleeperId;
  @override
  @JsonKey(name: 'first_name')
  final String? firstName;
  @override
  @JsonKey(name: 'last_name')
  final String? lastName;
  final List<String> _fantasyPositions;
  @override
  @JsonKey(name: 'fantasy_positions')
  List<String> get fantasyPositions {
    if (_fantasyPositions is EqualUnmodifiableListView)
      return _fantasyPositions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_fantasyPositions);
  }

  @override
  @JsonKey(name: 'years_exp')
  final int? yearsExp;
  @override
  final int? age;
  @override
  final String? team;
  @override
  final String? position;
  @override
  @JsonKey(name: 'jersey_number')
  final int? number;
  @override
  final String? status;
  @override
  @JsonKey(name: 'injury_status')
  final String? injuryStatus;
  @override
  final bool? active;
// Fantasy stats
  @override
  @JsonKey(name: 'prior_season_pts')
  final double? priorSeasonPts;
  @override
  @JsonKey(name: 'season_to_date_pts')
  final double? seasonToDatePts;
  @override
  @JsonKey(name: 'remaining_projected_pts')
  final double? remainingProjectedPts;

  @override
  String toString() {
    return 'Player(id: $id, sleeperId: $sleeperId, firstName: $firstName, lastName: $lastName, fantasyPositions: $fantasyPositions, yearsExp: $yearsExp, age: $age, team: $team, position: $position, number: $number, status: $status, injuryStatus: $injuryStatus, active: $active, priorSeasonPts: $priorSeasonPts, seasonToDatePts: $seasonToDatePts, remainingProjectedPts: $remainingProjectedPts)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlayerImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.sleeperId, sleeperId) ||
                other.sleeperId == sleeperId) &&
            (identical(other.firstName, firstName) ||
                other.firstName == firstName) &&
            (identical(other.lastName, lastName) ||
                other.lastName == lastName) &&
            const DeepCollectionEquality()
                .equals(other._fantasyPositions, _fantasyPositions) &&
            (identical(other.yearsExp, yearsExp) ||
                other.yearsExp == yearsExp) &&
            (identical(other.age, age) || other.age == age) &&
            (identical(other.team, team) || other.team == team) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.number, number) || other.number == number) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.injuryStatus, injuryStatus) ||
                other.injuryStatus == injuryStatus) &&
            (identical(other.active, active) || other.active == active) &&
            (identical(other.priorSeasonPts, priorSeasonPts) ||
                other.priorSeasonPts == priorSeasonPts) &&
            (identical(other.seasonToDatePts, seasonToDatePts) ||
                other.seasonToDatePts == seasonToDatePts) &&
            (identical(other.remainingProjectedPts, remainingProjectedPts) ||
                other.remainingProjectedPts == remainingProjectedPts));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      sleeperId,
      firstName,
      lastName,
      const DeepCollectionEquality().hash(_fantasyPositions),
      yearsExp,
      age,
      team,
      position,
      number,
      status,
      injuryStatus,
      active,
      priorSeasonPts,
      seasonToDatePts,
      remainingProjectedPts);

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      __$$PlayerImplCopyWithImpl<_$PlayerImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PlayerImplToJson(
      this,
    );
  }
}

abstract class _Player implements Player {
  const factory _Player(
      {required final int id,
      @JsonKey(name: 'sleeper_id') required final String sleeperId,
      @JsonKey(name: 'first_name') final String? firstName,
      @JsonKey(name: 'last_name') final String? lastName,
      @JsonKey(name: 'fantasy_positions')
      required final List<String> fantasyPositions,
      @JsonKey(name: 'years_exp') final int? yearsExp,
      final int? age,
      final String? team,
      final String? position,
      @JsonKey(name: 'jersey_number') final int? number,
      final String? status,
      @JsonKey(name: 'injury_status') final String? injuryStatus,
      final bool? active,
      @JsonKey(name: 'prior_season_pts') final double? priorSeasonPts,
      @JsonKey(name: 'season_to_date_pts') final double? seasonToDatePts,
      @JsonKey(name: 'remaining_projected_pts')
      final double? remainingProjectedPts}) = _$PlayerImpl;

  factory _Player.fromJson(Map<String, dynamic> json) = _$PlayerImpl.fromJson;

  @override
  int get id;
  @override
  @JsonKey(name: 'sleeper_id')
  String get sleeperId;
  @override
  @JsonKey(name: 'first_name')
  String? get firstName;
  @override
  @JsonKey(name: 'last_name')
  String? get lastName;
  @override
  @JsonKey(name: 'fantasy_positions')
  List<String> get fantasyPositions;
  @override
  @JsonKey(name: 'years_exp')
  int? get yearsExp;
  @override
  int? get age;
  @override
  String? get team;
  @override
  String? get position;
  @override
  @JsonKey(name: 'jersey_number')
  int? get number;
  @override
  String? get status;
  @override
  @JsonKey(name: 'injury_status')
  String? get injuryStatus;
  @override
  bool? get active; // Fantasy stats
  @override
  @JsonKey(name: 'prior_season_pts')
  double? get priorSeasonPts;
  @override
  @JsonKey(name: 'season_to_date_pts')
  double? get seasonToDatePts;
  @override
  @JsonKey(name: 'remaining_projected_pts')
  double? get remainingProjectedPts;

  /// Create a copy of Player
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlayerImplCopyWith<_$PlayerImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
