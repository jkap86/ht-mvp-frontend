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
  static const draftStarted = 'draft:started';
  static const draftPaused = 'draft:paused';
  static const draftResumed = 'draft:resumed';
  static const draftCompleted = 'draft:completed';
  static const draftNextPick = 'draft:next_pick';
  static const draftPickUndone = 'draft:pick_undone';
  static const draftQueueUpdated = 'draft:queue_updated';

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
}
