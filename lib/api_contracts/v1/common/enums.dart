// Canonical backend-synced enums.
// Each enum carries only its wire `value` and a `fromString` factory.
// UI labels, descriptions, and helpers belong in feature-layer extensions.

// ─── Draft ───────────────────────────────────────────────────────────────────

enum DraftType {
  snake('snake'),
  linear('linear'),
  auction('auction'),
  matchups('matchups');

  final String value;
  const DraftType(this.value);

  static DraftType fromString(String? value) {
    return DraftType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => DraftType.snake,
    );
  }
}

enum DraftStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  paused('paused'),
  completed('completed');

  final String value;
  const DraftStatus(this.value);

  static DraftStatus fromString(String? status) {
    if (status == null) return DraftStatus.notStarted;
    return DraftStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => DraftStatus.notStarted,
    );
  }
}

enum DraftPhase {
  setup('SETUP'),
  derby('DERBY'),
  live('LIVE');

  final String value;
  const DraftPhase(this.value);

  static DraftPhase fromString(String? phase) {
    if (phase == null) return DraftPhase.setup;
    return DraftPhase.values.firstWhere(
      (p) => p.value.toUpperCase() == phase.toUpperCase(),
      orElse: () => DraftPhase.setup,
    );
  }
}

enum DerbyTimeoutPolicy {
  autoRandomSlot('AUTO_RANDOM_SLOT'),
  pushBackOne('PUSH_BACK_ONE'),
  pushToEnd('PUSH_TO_END');

  final String value;
  const DerbyTimeoutPolicy(this.value);

  static DerbyTimeoutPolicy fromString(String? policy) {
    if (policy == null) return DerbyTimeoutPolicy.autoRandomSlot;
    return DerbyTimeoutPolicy.values.firstWhere(
      (p) => p.value == policy,
      orElse: () => DerbyTimeoutPolicy.autoRandomSlot,
    );
  }
}

// ─── Trade ────────────────────────────────────────────────────────────────────

enum TradeStatus {
  pending('pending'),
  countered('countered'),
  accepted('accepted'),
  inReview('in_review'),
  completed('completed'),
  rejected('rejected'),
  cancelled('cancelled'),
  expired('expired'),
  vetoed('vetoed');

  final String value;
  const TradeStatus(this.value);

  static TradeStatus fromString(String? value) {
    return TradeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TradeStatus.pending,
    );
  }
}

enum TradeItemType {
  player('player'),
  draftPick('draft_pick');

  final String value;
  const TradeItemType(this.value);

  static TradeItemType fromString(String? value) {
    switch (value) {
      case 'draft_pick':
        return TradeItemType.draftPick;
      case 'player':
      default:
        return TradeItemType.player;
    }
  }
}

// ─── Waiver ──────────────────────────────────────────────────────────────────

enum WaiverClaimStatus {
  pending('pending'),
  processing('processing'),
  successful('successful'),
  failed('failed'),
  cancelled('cancelled'),
  invalid('invalid');

  final String value;
  const WaiverClaimStatus(this.value);

  static WaiverClaimStatus fromString(String? value) {
    return WaiverClaimStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WaiverClaimStatus.pending,
    );
  }
}

// ─── League ──────────────────────────────────────────────────────────────────

enum SeasonStatus {
  preSeason('pre_season'),
  regularSeason('regular_season'),
  playoffs('playoffs'),
  offseason('offseason');

  final String value;
  const SeasonStatus(this.value);

  static SeasonStatus fromString(String? value) {
    switch (value) {
      case 'regular_season':
        return SeasonStatus.regularSeason;
      case 'playoffs':
        return SeasonStatus.playoffs;
      case 'offseason':
        return SeasonStatus.offseason;
      default:
        return SeasonStatus.preSeason;
    }
  }
}

enum FillStatus {
  open('open'),
  waitingPayment('waiting_payment'),
  filled('filled');

  final String value;
  const FillStatus(this.value);

  static FillStatus fromString(String? value) {
    switch (value) {
      case 'open':
        return FillStatus.open;
      case 'waiting_payment':
        return FillStatus.waitingPayment;
      case 'filled':
        return FillStatus.filled;
      default:
        return FillStatus.open;
    }
  }
}

// ─── Roster ──────────────────────────────────────────────────────────────────

enum AcquiredType {
  draft('draft'),
  freeAgent('free_agent'),
  trade('trade'),
  waiver('waiver');

  final String value;
  const AcquiredType(this.value);

  static AcquiredType fromString(String? value) {
    switch (value) {
      case 'draft':
        return AcquiredType.draft;
      case 'free_agent':
        return AcquiredType.freeAgent;
      case 'trade':
        return AcquiredType.trade;
      case 'waiver':
        return AcquiredType.waiver;
      default:
        return AcquiredType.freeAgent;
    }
  }
}

enum TransactionType {
  add('add'),
  drop('drop'),
  trade('trade');

  final String value;
  const TransactionType(this.value);

  static TransactionType fromString(String? value) {
    switch (value) {
      case 'add':
        return TransactionType.add;
      case 'drop':
        return TransactionType.drop;
      case 'trade':
        return TransactionType.trade;
      default:
        return TransactionType.add;
    }
  }
}

enum LineupSlot {
  qb('QB'),
  rb('RB'),
  wr('WR'),
  te('TE'),
  flex('FLEX'),
  superFlex('SUPER_FLEX'),
  recFlex('REC_FLEX'),
  k('K'),
  def('DEF'),
  dl('DL'),
  lb('LB'),
  db('DB'),
  idpFlex('IDP_FLEX'),
  bn('BN'),
  ir('IR'),
  taxi('TAXI');

  final String code;
  const LineupSlot(this.code);

  static LineupSlot? fromCode(String? code) {
    if (code == null) return null;
    return LineupSlot.values
        .where((s) => s.code == code.toUpperCase())
        .firstOrNull;
  }
}

// ─── Activity ────────────────────────────────────────────────────────────────

enum ActivityType {
  trade('trade'),
  waiver('waiver'),
  add('add'),
  drop('drop'),
  draft('draft');

  final String value;
  const ActivityType(this.value);

  static ActivityType fromString(String? value) {
    return ActivityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ActivityType.add,
    );
  }
}

// ─── Notification ────────────────────────────────────────────────────────────

enum NotificationType {
  tradePending('trade_pending'),
  tradeAccepted('trade_accepted'),
  tradeRejected('trade_rejected'),
  tradeCompleted('trade_completed'),
  draftStarting('draft_starting'),
  draftStarted('draft_started'),
  draftPick('draft_pick'),
  waiverProcessed('waiver_processed'),
  waiverSuccess('waiver_success'),
  waiverFailed('waiver_failed'),
  scoresUpdated('scores_updated'),
  weekFinalized('week_finalized'),
  messageReceived('message_received'),
  leagueInvite('league_invite'),
  invitationReceived('invitation_received'),
  matchupResult('matchup_result');

  final String value;
  const NotificationType(this.value);

  static NotificationType fromString(String value) {
    return NotificationType.values.firstWhere(
      (t) => t.value == value,
      orElse: () => NotificationType.messageReceived,
    );
  }
}

// ─── Chat ────────────────────────────────────────────────────────────────────

enum MessageType {
  chat('chat'),
  tradeProposed('trade_proposed'),
  tradeCountered('trade_countered'),
  tradeAccepted('trade_accepted'),
  tradeCompleted('trade_completed'),
  tradeRejected('trade_rejected'),
  tradeCancelled('trade_cancelled'),
  tradeVetoed('trade_vetoed'),
  tradeInvalidated('trade_invalidated'),
  waiverSuccessful('waiver_successful'),
  waiverProcessed('waiver_processed'),
  settingsUpdated('settings_updated'),
  memberJoined('member_joined'),
  memberKicked('member_kicked'),
  duesPaid('dues_paid'),
  duesUnpaid('dues_unpaid');

  final String value;
  const MessageType(this.value);

  static MessageType fromString(String? value) {
    return MessageType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => MessageType.chat,
    );
  }
}

// ─── Playoff ─────────────────────────────────────────────────────────────────

enum PlayoffStatus {
  pending('pending'),
  active('active'),
  completed('completed');

  final String value;
  const PlayoffStatus(this.value);

  static PlayoffStatus fromString(String? value) {
    switch (value) {
      case 'active':
        return PlayoffStatus.active;
      case 'completed':
        return PlayoffStatus.completed;
      default:
        return PlayoffStatus.pending;
    }
  }
}

enum ConsolationType {
  none('NONE'),
  consolation('CONSOLATION');

  final String value;
  const ConsolationType(this.value);

  static ConsolationType fromString(String? value) {
    switch (value) {
      case 'CONSOLATION':
        return ConsolationType.consolation;
      default:
        return ConsolationType.none;
    }
  }
}
