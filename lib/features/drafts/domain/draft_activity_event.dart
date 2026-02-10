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
