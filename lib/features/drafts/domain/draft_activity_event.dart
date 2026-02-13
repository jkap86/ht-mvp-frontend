enum DraftActivityType {
  pickMade,
  autoPick,
  timerExpired,
  draftStarted,
  draftPaused,
  draftResumed,
  draftCompleted,
  pickUndone,
  autodraftToggled,
  // Derby-specific activity types
  derbySlotPicked,
  derbyTimeout,
  derbyCompleted,
  // Auction-specific activity types
  nominationTimeout,
  autoNominated,
}

class DraftActivityEvent {
  final DraftActivityType type;
  final String message;
  final DateTime timestamp;

  const DraftActivityEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}
