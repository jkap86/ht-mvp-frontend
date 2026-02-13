class LeagueSettingsDto {
  final String? draftType;
  final String? auctionMode;
  final int? auctionBudget;
  final int? rosterSlots;
  final String? rosterType;
  final bool? useLeagueMedian;
  final String? tradeProposalLeagueChatMax;
  final int? maxKeepers;
  final bool? keeperCostsEnabled;
  final int? faabBudget;
  final bool? allowMemberInvites;

  const LeagueSettingsDto({
    this.draftType,
    this.auctionMode,
    this.auctionBudget,
    this.rosterSlots,
    this.rosterType,
    this.useLeagueMedian,
    this.tradeProposalLeagueChatMax,
    this.maxKeepers,
    this.keeperCostsEnabled,
    this.faabBudget,
    this.allowMemberInvites,
  });

  factory LeagueSettingsDto.fromJson(Map<String, dynamic> json) {
    return LeagueSettingsDto(
      draftType: json['draftType'] as String?,
      auctionMode: json['auctionMode'] as String?,
      auctionBudget: json['auctionBudget'] as int?,
      rosterSlots: json['rosterSlots'] as int?,
      rosterType: json['rosterType'] as String?,
      useLeagueMedian: json['useLeagueMedian'] as bool?,
      tradeProposalLeagueChatMax: json['tradeProposalLeagueChatMax'] as String?,
      maxKeepers: json['maxKeepers'] as int?,
      keeperCostsEnabled: json['keeperCostsEnabled'] as bool?,
      faabBudget: json['faabBudget'] as int?,
      allowMemberInvites: json['allowMemberInvites'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (draftType != null) 'draftType': draftType,
      if (auctionMode != null) 'auctionMode': auctionMode,
      if (auctionBudget != null) 'auctionBudget': auctionBudget,
      if (rosterSlots != null) 'rosterSlots': rosterSlots,
      if (rosterType != null) 'rosterType': rosterType,
      if (useLeagueMedian != null) 'useLeagueMedian': useLeagueMedian,
      if (tradeProposalLeagueChatMax != null) 'tradeProposalLeagueChatMax': tradeProposalLeagueChatMax,
      if (maxKeepers != null) 'maxKeepers': maxKeepers,
      if (keeperCostsEnabled != null) 'keeperCostsEnabled': keeperCostsEnabled,
      if (faabBudget != null) 'faabBudget': faabBudget,
      if (allowMemberInvites != null) 'allowMemberInvites': allowMemberInvites,
    };
  }
}

class ScoringSettingsDto {
  final Map<String, double> rules;

  const ScoringSettingsDto({required this.rules});

  factory ScoringSettingsDto.fromJson(Map<String, dynamic> json) {
    final rules = <String, double>{};
    json.forEach((key, value) {
      if (value is num) rules[key] = value.toDouble();
    });
    return ScoringSettingsDto(rules: rules);
  }

  Map<String, dynamic> toJson() => rules;
}

class RosterSettingsDto {
  final Map<String, int> slots;

  const RosterSettingsDto({required this.slots});

  factory RosterSettingsDto.fromJson(Map<String, dynamic> json) {
    final slots = <String, int>{};
    json.forEach((key, value) {
      if (value is int) slots[key] = value;
    });
    return RosterSettingsDto(slots: slots);
  }

  Map<String, dynamic> toJson() => slots;
}
