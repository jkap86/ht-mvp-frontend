import 'league.dart';

enum RosterFeature {
  superflex,
  twoTE,
  idp,
  bestball;

  String get displayName {
    switch (this) {
      case RosterFeature.superflex:
        return 'Superflex';
      case RosterFeature.twoTE:
        return '2TE';
      case RosterFeature.idp:
        return 'IDP';
      case RosterFeature.bestball:
        return 'Bestball';
    }
  }
}

enum LeagueSortField {
  name,
  season,
  status;

  String get displayName {
    switch (this) {
      case LeagueSortField.name:
        return 'Name';
      case LeagueSortField.season:
        return 'Season';
      case LeagueSortField.status:
        return 'Status';
    }
  }
}

enum SortDirection { ascending, descending }

class LeagueFilterCriteria {
  final String searchQuery;
  final Set<String> modes;
  final Set<SeasonStatus> seasonStatuses;
  final Set<String> scoringTypes;
  final Set<RosterFeature> rosterFeatures;
  final LeagueSortField sortField;
  final SortDirection sortDirection;

  const LeagueFilterCriteria({
    this.searchQuery = '',
    this.modes = const {},
    this.seasonStatuses = const {},
    this.scoringTypes = const {},
    this.rosterFeatures = const {},
    this.sortField = LeagueSortField.name,
    this.sortDirection = SortDirection.ascending,
  });

  bool get hasActiveFilters =>
      modes.isNotEmpty ||
      seasonStatuses.isNotEmpty ||
      scoringTypes.isNotEmpty ||
      rosterFeatures.isNotEmpty;

  int get activeFilterCount =>
      modes.length +
      seasonStatuses.length +
      scoringTypes.length +
      rosterFeatures.length;

  LeagueFilterCriteria copyWith({
    String? searchQuery,
    Set<String>? modes,
    Set<SeasonStatus>? seasonStatuses,
    Set<String>? scoringTypes,
    Set<RosterFeature>? rosterFeatures,
    LeagueSortField? sortField,
    SortDirection? sortDirection,
  }) {
    return LeagueFilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      modes: modes ?? this.modes,
      seasonStatuses: seasonStatuses ?? this.seasonStatuses,
      scoringTypes: scoringTypes ?? this.scoringTypes,
      rosterFeatures: rosterFeatures ?? this.rosterFeatures,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
    );
  }

  LeagueFilterCriteria clearAll() {
    return LeagueFilterCriteria(
      searchQuery: searchQuery,
      sortField: sortField,
      sortDirection: sortDirection,
    );
  }
}

// Extension to detect roster features from league settings
extension LeagueRosterFeatures on League {
  bool get hasSuperflex {
    final rosterConfig = settings['roster_config'] as Map<String, dynamic>?;
    if (rosterConfig == null) return false;
    final sf = rosterConfig['SUPER_FLEX'];
    return sf is num && sf > 0;
  }

  bool get hasTwoTE {
    final rosterConfig = settings['roster_config'] as Map<String, dynamic>?;
    if (rosterConfig == null) return false;
    final te = rosterConfig['TE'];
    return te is num && te >= 2;
  }

  bool get hasIDP {
    final rosterConfig = settings['roster_config'] as Map<String, dynamic>?;
    if (rosterConfig == null) return false;
    for (final key in ['DL', 'LB', 'DB', 'IDP_FLEX']) {
      final val = rosterConfig[key];
      if (val is num && val > 0) return true;
    }
    return false;
  }

  bool hasRosterFeature(RosterFeature feature) {
    switch (feature) {
      case RosterFeature.superflex:
        return hasSuperflex;
      case RosterFeature.twoTE:
        return hasTwoTE;
      case RosterFeature.idp:
        return hasIDP;
      case RosterFeature.bestball:
        return isBestball;
    }
  }
}
