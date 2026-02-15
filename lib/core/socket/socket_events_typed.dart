/// Typed socket events for type-safe event handling.
///
/// Each event class contains the parsed payload from the socket event,
/// allowing features to work with strongly-typed data instead of dynamic maps.
library;

import '../../features/drafts/domain/draft_pick.dart';
import '../../features/drafts/domain/auction_lot.dart';
import '../../features/trades/domain/trade.dart';
import '../utils/json_read.dart';

/// Base sealed class for all socket events.
/// Using sealed classes allows exhaustive pattern matching.
sealed class SocketEvent {
  const SocketEvent();
}

// ============================================================================
// Draft Events
// ============================================================================

/// Emitted when a new draft is created
final class DraftCreatedEvent extends SocketEvent {
  final int draftId;
  final int leagueId;
  final String draftType;
  final String status;

  const DraftCreatedEvent({
    required this.draftId,
    required this.leagueId,
    required this.draftType,
    required this.status,
  });

  factory DraftCreatedEvent.fromJson(Map<String, dynamic> json) {
    return DraftCreatedEvent(
      draftId: readIntEither(json, 'draft_id', 'draftId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      draftType: json['draftType'] as String,
      status: json['status'] as String,
    );
  }
}

/// Emitted when a draft starts
final class DraftStartedEvent extends SocketEvent {
  final int draftId;
  final int currentPick;
  final int currentRound;
  final int? currentRosterId;
  final DateTime? turnExpiresAt;

  const DraftStartedEvent({
    required this.draftId,
    required this.currentPick,
    required this.currentRound,
    this.currentRosterId,
    this.turnExpiresAt,
  });

  factory DraftStartedEvent.fromJson(Map<String, dynamic> json) {
    return DraftStartedEvent(
      draftId: readIntEither(json, 'draft_id', 'draftId')!,
      currentPick: readIntEither(json, 'current_pick', 'currentPick') ?? 1,
      currentRound: readIntEither(json, 'current_round', 'currentRound') ?? 1,
      currentRosterId: readIntEither(json, 'current_roster_id', 'currentRosterId'),
      turnExpiresAt: json['turnExpiresAt'] != null
          ? DateTime.parse(json['turnExpiresAt'] as String)
          : null,
    );
  }
}

/// Emitted when a draft pick is made
final class DraftPickEvent extends SocketEvent {
  final DraftPick pick;
  final int? serverTime;

  const DraftPickEvent({
    required this.pick,
    this.serverTime,
  });

  factory DraftPickEvent.fromJson(Map<String, dynamic> json) {
    return DraftPickEvent(
      pick: DraftPick.fromJson(json),
      serverTime: readIntEither(json, 'server_time', 'serverTime'),
    );
  }
}

/// Emitted when it's time for the next pick
final class NextPickEvent extends SocketEvent {
  final int draftId;
  final int pickNumber;
  final int round;
  final int rosterId;
  final DateTime? turnExpiresAt;
  final bool isOnTheClock;

  const NextPickEvent({
    required this.draftId,
    required this.pickNumber,
    required this.round,
    required this.rosterId,
    this.turnExpiresAt,
    this.isOnTheClock = false,
  });

  factory NextPickEvent.fromJson(Map<String, dynamic> json) {
    return NextPickEvent(
      draftId: readIntEither(json, 'draft_id', 'draftId')!,
      pickNumber: readIntEither(json, 'pick_number', 'pickNumber')!,
      round: json['round'] as int,
      rosterId: readIntEither(json, 'roster_id', 'rosterId')!,
      turnExpiresAt: json['turnExpiresAt'] != null
          ? DateTime.parse(json['turnExpiresAt'] as String)
          : null,
      isOnTheClock: json['isOnTheClock'] as bool? ?? false,
    );
  }
}

/// Emitted when a draft is paused
final class DraftPausedEvent extends SocketEvent {
  final int draftId;

  const DraftPausedEvent({required this.draftId});

  factory DraftPausedEvent.fromJson(Map<String, dynamic> json) {
    return DraftPausedEvent(draftId: readIntEither(json, 'draft_id', 'draftId')!);
  }
}

/// Emitted when a draft is resumed
final class DraftResumedEvent extends SocketEvent {
  final int draftId;
  final DateTime? turnExpiresAt;

  const DraftResumedEvent({
    required this.draftId,
    this.turnExpiresAt,
  });

  factory DraftResumedEvent.fromJson(Map<String, dynamic> json) {
    return DraftResumedEvent(
      draftId: readIntEither(json, 'draft_id', 'draftId')!,
      turnExpiresAt: json['turnExpiresAt'] != null
          ? DateTime.parse(json['turnExpiresAt'] as String)
          : null,
    );
  }
}

/// Emitted when a draft completes
final class DraftCompletedEvent extends SocketEvent {
  final int draftId;

  const DraftCompletedEvent({required this.draftId});

  factory DraftCompletedEvent.fromJson(Map<String, dynamic> json) {
    return DraftCompletedEvent(draftId: readIntEither(json, 'draft_id', 'draftId')!);
  }
}

/// Emitted when a pick is undone
final class PickUndoneEvent extends SocketEvent {
  final int draftId;
  final int pickNumber;
  final int round;
  final int rosterId;
  final DateTime? turnExpiresAt;

  const PickUndoneEvent({
    required this.draftId,
    required this.pickNumber,
    required this.round,
    required this.rosterId,
    this.turnExpiresAt,
  });

  factory PickUndoneEvent.fromJson(Map<String, dynamic> json) {
    return PickUndoneEvent(
      draftId: readIntEither(json, 'draft_id', 'draftId')!,
      pickNumber: readIntEither(json, 'current_pick', 'currentPick')!,
      round: readIntEither(json, 'current_round', 'currentRound')!,
      rosterId: readIntEither(json, 'current_roster_id', 'currentRosterId')!,
      turnExpiresAt: json['turnExpiresAt'] != null
          ? DateTime.parse(json['turnExpiresAt'] as String)
          : null,
    );
  }
}

/// Emitted when autodraft is toggled
final class AutodraftToggledEvent extends SocketEvent {
  final int draftId;
  final int rosterId;
  final bool isEnabled;

  const AutodraftToggledEvent({
    required this.draftId,
    required this.rosterId,
    required this.isEnabled,
  });

  factory AutodraftToggledEvent.fromJson(Map<String, dynamic> json) {
    return AutodraftToggledEvent(
      draftId: readIntEither(json, 'draft_id', 'draftId')!,
      rosterId: readIntEither(json, 'roster_id', 'rosterId')!,
      isEnabled: json['autodraftEnabled'] as bool,
    );
  }
}

/// Emitted when a user's queue is updated
final class QueueUpdatedEvent extends SocketEvent {
  final int draftId;
  final int rosterId;
  final List<int> queuePlayerIds;

  const QueueUpdatedEvent({
    required this.draftId,
    required this.rosterId,
    required this.queuePlayerIds,
  });

  factory QueueUpdatedEvent.fromJson(Map<String, dynamic> json) {
    return QueueUpdatedEvent(
      draftId: readIntEither(json, 'draft_id', 'draftId')!,
      rosterId: readIntEither(json, 'roster_id', 'rosterId')!,
      queuePlayerIds: (json['queue'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
    );
  }
}

// ============================================================================
// Auction Events
// ============================================================================

/// Emitted when a new auction lot is created
final class AuctionLotCreatedEvent extends SocketEvent {
  final AuctionLot lot;
  final int? serverTime;

  const AuctionLotCreatedEvent({
    required this.lot,
    this.serverTime,
  });

  factory AuctionLotCreatedEvent.fromJson(Map<String, dynamic> json) {
    return AuctionLotCreatedEvent(
      lot: AuctionLot.fromJson(json),
      serverTime: readIntEither(json, 'server_time', 'serverTime'),
    );
  }
}

/// Emitted when an auction lot is updated (bid placed)
final class AuctionLotUpdatedEvent extends SocketEvent {
  final AuctionLot lot;
  final int? serverTime;

  const AuctionLotUpdatedEvent({
    required this.lot,
    this.serverTime,
  });

  factory AuctionLotUpdatedEvent.fromJson(Map<String, dynamic> json) {
    return AuctionLotUpdatedEvent(
      lot: AuctionLot.fromJson(json),
      serverTime: readIntEither(json, 'server_time', 'serverTime'),
    );
  }
}

/// Emitted when an auction lot is won
final class AuctionLotWonEvent extends SocketEvent {
  final int lotId;
  final int playerId;
  final int winningRosterId;
  final int winningBid;

  const AuctionLotWonEvent({
    required this.lotId,
    required this.playerId,
    required this.winningRosterId,
    required this.winningBid,
  });

  factory AuctionLotWonEvent.fromJson(Map<String, dynamic> json) {
    return AuctionLotWonEvent(
      lotId: readIntEither(json, 'lot_id', 'lotId')!,
      playerId: readIntEither(json, 'player_id', 'playerId')!,
      winningRosterId: readIntEither(json, 'winning_roster_id', 'winningRosterId')!,
      winningBid: readIntEither(json, 'winning_bid', 'winningBid')!,
    );
  }
}

/// Emitted when an auction lot passes (no bids)
final class AuctionLotPassedEvent extends SocketEvent {
  final int lotId;
  final int playerId;

  const AuctionLotPassedEvent({
    required this.lotId,
    required this.playerId,
  });

  factory AuctionLotPassedEvent.fromJson(Map<String, dynamic> json) {
    return AuctionLotPassedEvent(
      lotId: readIntEither(json, 'lot_id', 'lotId')!,
      playerId: readIntEither(json, 'player_id', 'playerId')!,
    );
  }
}

/// Emitted when user is outbid
final class AuctionOutbidEvent extends SocketEvent {
  final int lotId;
  final int playerId;
  final int currentBid;
  final int highBidderRosterId;

  const AuctionOutbidEvent({
    required this.lotId,
    required this.playerId,
    required this.currentBid,
    required this.highBidderRosterId,
  });

  factory AuctionOutbidEvent.fromJson(Map<String, dynamic> json) {
    return AuctionOutbidEvent(
      lotId: readIntEither(json, 'lot_id', 'lotId')!,
      playerId: readIntEither(json, 'player_id', 'playerId')!,
      currentBid: readIntEither(json, 'current_bid', 'currentBid')!,
      highBidderRosterId: readIntEither(json, 'high_bidder_roster_id', 'highBidderRosterId')!,
    );
  }
}

/// Emitted when nominator changes in fast auction
final class AuctionNominatorChangedEvent extends SocketEvent {
  final int draftId;
  final int nominatorRosterId;
  final DateTime? nominationExpiresAt;

  const AuctionNominatorChangedEvent({
    required this.draftId,
    required this.nominatorRosterId,
    this.nominationExpiresAt,
  });

  factory AuctionNominatorChangedEvent.fromJson(Map<String, dynamic> json) {
    return AuctionNominatorChangedEvent(
      draftId: readIntEither(json, 'draft_id', 'draftId')!,
      nominatorRosterId: readIntEither(json, 'nominator_roster_id', 'nominatorRosterId')!,
      nominationExpiresAt: json['nominationExpiresAt'] != null
          ? DateTime.parse(json['nominationExpiresAt'] as String)
          : null,
    );
  }
}

/// Emitted on auction action error
final class AuctionErrorEvent extends SocketEvent {
  final String code;
  final String message;

  const AuctionErrorEvent({
    required this.code,
    required this.message,
  });

  factory AuctionErrorEvent.fromJson(Map<String, dynamic> json) {
    return AuctionErrorEvent(
      code: json['code'] as String? ?? 'UNKNOWN',
      message: json['message'] as String? ?? 'Unknown error',
    );
  }
}

// ============================================================================
// Trade Events
// ============================================================================

/// Emitted when a trade is proposed
final class TradeProposedEvent extends SocketEvent {
  final Trade trade;

  const TradeProposedEvent({required this.trade});

  factory TradeProposedEvent.fromJson(Map<String, dynamic> json) {
    return TradeProposedEvent(trade: Trade.fromJson(json));
  }
}

/// Emitted when a trade is accepted
final class TradeAcceptedEvent extends SocketEvent {
  final int tradeId;
  final int leagueId;

  const TradeAcceptedEvent({
    required this.tradeId,
    required this.leagueId,
  });

  factory TradeAcceptedEvent.fromJson(Map<String, dynamic> json) {
    return TradeAcceptedEvent(
      tradeId: readIntEither(json, 'trade_id', 'tradeId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
    );
  }
}

/// Emitted when a trade is rejected
final class TradeRejectedEvent extends SocketEvent {
  final int tradeId;
  final int leagueId;

  const TradeRejectedEvent({
    required this.tradeId,
    required this.leagueId,
  });

  factory TradeRejectedEvent.fromJson(Map<String, dynamic> json) {
    return TradeRejectedEvent(
      tradeId: readIntEither(json, 'trade_id', 'tradeId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
    );
  }
}

/// Emitted when a trade is countered
final class TradeCounteredEvent extends SocketEvent {
  final Trade trade;

  const TradeCounteredEvent({required this.trade});

  factory TradeCounteredEvent.fromJson(Map<String, dynamic> json) {
    return TradeCounteredEvent(trade: Trade.fromJson(json));
  }
}

/// Emitted when a trade is cancelled
final class TradeCancelledEvent extends SocketEvent {
  final int tradeId;
  final int leagueId;

  const TradeCancelledEvent({
    required this.tradeId,
    required this.leagueId,
  });

  factory TradeCancelledEvent.fromJson(Map<String, dynamic> json) {
    return TradeCancelledEvent(
      tradeId: readIntEither(json, 'trade_id', 'tradeId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
    );
  }
}

/// Emitted when a trade expires
final class TradeExpiredEvent extends SocketEvent {
  final int tradeId;
  final int leagueId;

  const TradeExpiredEvent({
    required this.tradeId,
    required this.leagueId,
  });

  factory TradeExpiredEvent.fromJson(Map<String, dynamic> json) {
    return TradeExpiredEvent(
      tradeId: readIntEither(json, 'trade_id', 'tradeId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
    );
  }
}

/// Emitted when a trade is completed (executed)
final class TradeCompletedEvent extends SocketEvent {
  final int tradeId;
  final int leagueId;

  const TradeCompletedEvent({
    required this.tradeId,
    required this.leagueId,
  });

  factory TradeCompletedEvent.fromJson(Map<String, dynamic> json) {
    return TradeCompletedEvent(
      tradeId: readIntEither(json, 'trade_id', 'tradeId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
    );
  }
}

/// Emitted when a trade is vetoed
final class TradeVetoedEvent extends SocketEvent {
  final int tradeId;
  final int leagueId;

  const TradeVetoedEvent({
    required this.tradeId,
    required this.leagueId,
  });

  factory TradeVetoedEvent.fromJson(Map<String, dynamic> json) {
    return TradeVetoedEvent(
      tradeId: readIntEither(json, 'trade_id', 'tradeId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
    );
  }
}

/// Emitted when a vote is cast on a trade
final class TradeVoteCastEvent extends SocketEvent {
  final int tradeId;
  final int leagueId;
  final int vetoCount;
  final int approveCount;

  const TradeVoteCastEvent({
    required this.tradeId,
    required this.leagueId,
    required this.vetoCount,
    required this.approveCount,
  });

  factory TradeVoteCastEvent.fromJson(Map<String, dynamic> json) {
    return TradeVoteCastEvent(
      tradeId: readIntEither(json, 'trade_id', 'tradeId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      vetoCount: readIntEither(json, 'veto_count', 'vetoCount') ?? 0,
      approveCount: readIntEither(json, 'approve_count', 'approveCount') ?? 0,
    );
  }
}

// ============================================================================
// Waiver Events
// ============================================================================

/// Emitted when a waiver claim is submitted
final class WaiverClaimSubmittedEvent extends SocketEvent {
  final int claimId;
  final int leagueId;
  final int rosterId;
  final int playerId;
  final int? dropPlayerId;

  const WaiverClaimSubmittedEvent({
    required this.claimId,
    required this.leagueId,
    required this.rosterId,
    required this.playerId,
    this.dropPlayerId,
  });

  factory WaiverClaimSubmittedEvent.fromJson(Map<String, dynamic> json) {
    return WaiverClaimSubmittedEvent(
      claimId: readIntEither(json, 'claim_id', 'claimId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      rosterId: readIntEither(json, 'roster_id', 'rosterId')!,
      playerId: readIntEither(json, 'player_id', 'playerId')!,
      dropPlayerId: readIntEither(json, 'drop_player_id', 'dropPlayerId'),
    );
  }
}

/// Emitted when a waiver claim is cancelled
final class WaiverClaimCancelledEvent extends SocketEvent {
  final int claimId;
  final int leagueId;

  const WaiverClaimCancelledEvent({
    required this.claimId,
    required this.leagueId,
  });

  factory WaiverClaimCancelledEvent.fromJson(Map<String, dynamic> json) {
    return WaiverClaimCancelledEvent(
      claimId: readIntEither(json, 'claim_id', 'claimId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
    );
  }
}

/// Emitted when waivers are processed for a league
final class WaiverProcessedEvent extends SocketEvent {
  final int leagueId;
  final int week;
  final int claimsProcessed;
  final int claimsSuccessful;

  const WaiverProcessedEvent({
    required this.leagueId,
    required this.week,
    required this.claimsProcessed,
    required this.claimsSuccessful,
  });

  factory WaiverProcessedEvent.fromJson(Map<String, dynamic> json) {
    return WaiverProcessedEvent(
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      week: json['week'] as int,
      claimsProcessed: readIntEither(json, 'claims_processed', 'claimsProcessed') ?? 0,
      claimsSuccessful: readIntEither(json, 'claims_successful', 'claimsSuccessful') ?? 0,
    );
  }
}

/// Emitted when a waiver claim succeeds
final class WaiverClaimSuccessfulEvent extends SocketEvent {
  final int claimId;
  final int leagueId;
  final int rosterId;
  final int playerId;

  const WaiverClaimSuccessfulEvent({
    required this.claimId,
    required this.leagueId,
    required this.rosterId,
    required this.playerId,
  });

  factory WaiverClaimSuccessfulEvent.fromJson(Map<String, dynamic> json) {
    return WaiverClaimSuccessfulEvent(
      claimId: readIntEither(json, 'claim_id', 'claimId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      rosterId: readIntEither(json, 'roster_id', 'rosterId')!,
      playerId: readIntEither(json, 'player_id', 'playerId')!,
    );
  }
}

/// Emitted when a waiver claim fails
final class WaiverClaimFailedEvent extends SocketEvent {
  final int claimId;
  final int leagueId;
  final String reason;

  const WaiverClaimFailedEvent({
    required this.claimId,
    required this.leagueId,
    required this.reason,
  });

  factory WaiverClaimFailedEvent.fromJson(Map<String, dynamic> json) {
    return WaiverClaimFailedEvent(
      claimId: readIntEither(json, 'claim_id', 'claimId')!,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      reason: json['reason'] as String? ?? 'Unknown',
    );
  }
}

// ============================================================================
// Chat Events
// ============================================================================

/// Emitted when a chat message is received
final class ChatMessageEvent extends SocketEvent {
  final int messageId;
  final int leagueId;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime sentAt;

  const ChatMessageEvent({
    required this.messageId,
    required this.leagueId,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.sentAt,
  });

  factory ChatMessageEvent.fromJson(Map<String, dynamic> json) {
    return ChatMessageEvent(
      messageId: json['id'] as int,
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String? ?? 'Unknown',
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

/// Emitted when a direct message is received
final class DmMessageEvent extends SocketEvent {
  final int messageId;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime sentAt;

  const DmMessageEvent({
    required this.messageId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.sentAt,
  });

  factory DmMessageEvent.fromJson(Map<String, dynamic> json) {
    return DmMessageEvent(
      messageId: json['id'] as int,
      senderId: json['senderId'] as String,
      recipientId: json['recipientId'] as String,
      content: json['content'] as String,
      sentAt: DateTime.parse(json['sentAt'] as String),
    );
  }
}

// ============================================================================
// Scoring Events
// ============================================================================

/// Emitted when scores are updated
final class ScoresUpdatedEvent extends SocketEvent {
  final int leagueId;
  final int week;
  final Map<int, double> rosterScores;

  const ScoresUpdatedEvent({
    required this.leagueId,
    required this.week,
    required this.rosterScores,
  });

  factory ScoresUpdatedEvent.fromJson(Map<String, dynamic> json) {
    final scoresMap = <int, double>{};
    final scores = json['scores'] as Map<String, dynamic>?;
    if (scores != null) {
      for (final entry in scores.entries) {
        final key = int.tryParse(entry.key.toString());
        final val = entry.value;
        if (key != null && val is num) {
          scoresMap[key] = val.toDouble();
        }
      }
    }
    return ScoresUpdatedEvent(
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      week: json['week'] as int,
      rosterScores: scoresMap,
    );
  }
}

/// Emitted when a week is finalized
final class WeekFinalizedEvent extends SocketEvent {
  final int leagueId;
  final int week;

  const WeekFinalizedEvent({
    required this.leagueId,
    required this.week,
  });

  factory WeekFinalizedEvent.fromJson(Map<String, dynamic> json) {
    return WeekFinalizedEvent(
      leagueId: readIntEither(json, 'league_id', 'leagueId')!,
      week: json['week'] as int,
    );
  }
}

// ============================================================================
// App Error Event
// ============================================================================

/// Emitted when a server-side error occurs
final class AppErrorEvent extends SocketEvent {
  final String code;
  final String message;
  final String? event;

  const AppErrorEvent({
    required this.code,
    required this.message,
    this.event,
  });

  factory AppErrorEvent.fromJson(Map<String, dynamic> json) {
    return AppErrorEvent(
      code: json['code'] as String? ?? 'UNKNOWN_ERROR',
      message: json['message'] as String? ?? 'An error occurred',
      event: json['event'] as String?,
    );
  }
}
