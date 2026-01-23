/// Draft-related constants.
/// Use these instead of hardcoded strings for consistency.
library;

class DraftStatus {
  DraftStatus._();

  static const notStarted = 'not_started';
  static const inProgress = 'in_progress';
  static const completed = 'completed';
}

class DraftType {
  DraftType._();

  static const snake = 'snake';
  static const linear = 'linear';
}
