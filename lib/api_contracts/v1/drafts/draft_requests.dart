class CreateDraftRequest {
  final String draftType;
  final int rounds;
  final int pickTimeSeconds;
  final Map<String, dynamic>? auctionSettings;
  final List<String>? playerPool;
  final bool? includeRookiePicks;

  const CreateDraftRequest({
    required this.draftType,
    required this.rounds,
    required this.pickTimeSeconds,
    this.auctionSettings,
    this.playerPool,
    this.includeRookiePicks,
  });

  Map<String, dynamic> toJson() {
    return {
      'draft_type': draftType,
      'rounds': rounds,
      'pick_time_seconds': pickTimeSeconds,
      if (auctionSettings != null) 'auction_settings': auctionSettings,
      if (playerPool != null) 'player_pool': playerPool,
      if (includeRookiePicks != null) 'include_rookie_picks': includeRookiePicks,
    };
  }
}

class UpdateDraftSettingsRequest {
  final Map<String, dynamic> settings;

  const UpdateDraftSettingsRequest({required this.settings});

  Map<String, dynamic> toJson() => settings;
}

class DraftActionRequest {
  final String action;
  final int? playerId;
  final List<int>? playerIds;
  final int? initialBid;
  final int? lotId;
  final int? maxBid;

  const DraftActionRequest({
    required this.action,
    this.playerId,
    this.playerIds,
    this.initialBid,
    this.lotId,
    this.maxBid,
  });

  Map<String, dynamic> toJson() {
    return {
      'action': action,
      if (playerId != null) 'player_id': playerId,
      if (playerIds != null) 'player_ids': playerIds,
      if (initialBid != null) 'initial_bid': initialBid,
      if (lotId != null) 'lot_id': lotId,
      if (maxBid != null) 'max_bid': maxBid,
    };
  }
}

class DerbyPickSlotRequest {
  final int draftId;
  final int slotPosition;

  const DerbyPickSlotRequest({required this.draftId, required this.slotPosition});

  Map<String, dynamic> toJson() {
    return {
      'draftId': draftId,
      'slotPosition': slotPosition,
    };
  }
}
