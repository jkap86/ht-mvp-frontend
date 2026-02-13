class SubmitClaimRequest {
  final int leagueId;
  final int playerId;
  final int? dropPlayerId;
  final int? bidAmount;

  const SubmitClaimRequest({
    required this.leagueId,
    required this.playerId,
    this.dropPlayerId,
    this.bidAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'league_id': leagueId,
      'player_id': playerId,
      if (dropPlayerId != null) 'drop_player_id': dropPlayerId,
      if (bidAmount != null) 'bid_amount': bidAmount,
    };
  }
}

class UpdateClaimRequest {
  final int claimId;
  final int? dropPlayerId;
  final int? bidAmount;

  const UpdateClaimRequest({
    required this.claimId,
    this.dropPlayerId,
    this.bidAmount,
  });

  Map<String, dynamic> toJson() {
    return {
      'claim_id': claimId,
      if (dropPlayerId != null) 'drop_player_id': dropPlayerId,
      if (bidAmount != null) 'bid_amount': bidAmount,
    };
  }
}

class ReorderClaimsRequest {
  final List<int> claimIds;

  const ReorderClaimsRequest({required this.claimIds});

  Map<String, dynamic> toJson() => {'claim_ids': claimIds};
}
