/// Socket.IO event name constants.
/// Use these instead of hardcoded strings for consistency.
library;

class SocketEvents {
  SocketEvents._();

  // App-level events
  static const appError = 'app:error';

  // League events
  static const leagueJoin = 'join:league';
  static const leagueLeave = 'leave:league';

  // Draft events
  static const draftJoin = 'join:draft';
  static const draftLeave = 'leave:draft';
  static const draftUserJoined = 'draft:user_joined';
  static const draftUserLeft = 'draft:user_left';
  static const draftPickMade = 'draft:pick_made';
  static const draftCreated = 'draft:created';
  static const draftStarted = 'draft:started';
  static const draftPaused = 'draft:paused';
  static const draftResumed = 'draft:resumed';
  static const draftCompleted = 'draft:completed';
  static const draftNextPick = 'draft:next_pick';
  static const draftPickUndone = 'draft:pick_undone';
  static const draftQueueUpdated = 'draft:queue_updated';
  static const draftAutodraftToggled = 'draft:autodraft_toggled';
  static const draftPickTraded = 'draft:pick_traded';
  static const draftSettingsUpdated = 'draft:settings_updated';

  // Auction events
  static const auctionLotCreated = 'draft:auction_lot_created';
  static const auctionLotUpdated = 'draft:auction_lot_updated';
  static const auctionLotWon = 'draft:auction_lot_won';
  static const auctionLotPassed = 'draft:auction_lot_passed';
  static const auctionOutbid = 'draft:auction_outbid';
  static const auctionNominatorChanged = 'draft:auction_nominator_changed';
  static const auctionError = 'draft:auction_error';

  // Chat events
  static const chatMessage = 'chat:message';

  // Direct message events
  static const dmMessage = 'dm:message';
  static const dmRead = 'dm:read';

  // Trade events
  static const tradeProposed = 'trade:proposed';
  static const tradeAccepted = 'trade:accepted';
  static const tradeRejected = 'trade:rejected';
  static const tradeCountered = 'trade:countered';
  static const tradeCancelled = 'trade:cancelled';
  static const tradeExpired = 'trade:expired';
  static const tradeCompleted = 'trade:completed';
  static const tradeVetoed = 'trade:vetoed';
  static const tradeVoteCast = 'trade:vote_cast';
  static const tradeInvalidated = 'trade:invalidated';

  // Waiver events
  static const waiverClaimSubmitted = 'waiver:claim_submitted';
  static const waiverClaimCancelled = 'waiver:claim_cancelled';
  static const waiverClaimUpdated = 'waiver:claim_updated';
  static const waiverProcessed = 'waiver:processed';
  static const waiverClaimSuccessful = 'waiver:claim_successful';
  static const waiverClaimFailed = 'waiver:claim_failed';
  static const waiverPriorityUpdated = 'waiver:priority_updated';
  static const waiverBudgetUpdated = 'waiver:budget_updated';

  // Scoring events
  static const scoringScoresUpdated = 'scoring:scores_updated';
  static const scoringWeekFinalized = 'scoring:week_finalized';

  // Member events
  static const memberKicked = 'member:kicked';
  static const memberJoined = 'member:joined';

  // Invitation events
  static const invitationReceived = 'invitation:received';
  static const invitationAccepted = 'invitation:accepted';
  static const invitationDeclined = 'invitation:declined';
  static const invitationCancelled = 'invitation:cancelled';
}
