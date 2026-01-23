/// Socket.IO event name constants.
/// Use these instead of hardcoded strings for consistency.
library;

class SocketEvents {
  SocketEvents._();

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
  static const draftCompleted = 'draft:completed';
  static const draftNextPick = 'draft:next_pick';

  // Chat events
  static const chatMessage = 'chat:message';
}
