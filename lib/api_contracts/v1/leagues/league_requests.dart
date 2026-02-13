class CreateLeagueRequest {
  final String name;
  final int totalRosters;
  final String mode;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? scoringSettings;
  final Map<String, dynamic>? leagueSettings;
  final bool isPublic;

  const CreateLeagueRequest({
    required this.name,
    required this.totalRosters,
    this.mode = 'redraft',
    this.settings,
    this.scoringSettings,
    this.leagueSettings,
    this.isPublic = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'total_rosters': totalRosters,
      'mode': mode,
      if (settings != null) 'settings': settings,
      if (scoringSettings != null) 'scoring_settings': scoringSettings,
      if (leagueSettings != null) 'league_settings': leagueSettings,
      'is_public': isPublic,
    };
  }
}

class UpdateLeagueRequest {
  final String? name;
  final Map<String, dynamic>? settings;
  final Map<String, dynamic>? scoringSettings;
  final Map<String, dynamic>? leagueSettings;
  final bool? isPublic;

  const UpdateLeagueRequest({
    this.name,
    this.settings,
    this.scoringSettings,
    this.leagueSettings,
    this.isPublic,
  });

  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (settings != null) 'settings': settings,
      if (scoringSettings != null) 'scoring_settings': scoringSettings,
      if (leagueSettings != null) 'league_settings': leagueSettings,
      if (isPublic != null) 'is_public': isPublic,
    };
  }
}

class SeasonControlsRequest {
  final String action;
  final Map<String, dynamic>? params;

  const SeasonControlsRequest({required this.action, this.params});

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      if (params != null) ...params!,
    };
  }
}

class JoinLeagueRequest {
  final int leagueId;

  const JoinLeagueRequest({required this.leagueId});

  Map<String, dynamic> toJson() => {'league_id': leagueId};
}
