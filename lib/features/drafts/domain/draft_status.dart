/// Enum representing the possible states of a draft
enum DraftStatus {
  notStarted('not_started'),
  inProgress('in_progress'),
  completed('completed');

  final String value;
  const DraftStatus(this.value);

  /// Parse a string value to DraftStatus, defaulting to notStarted
  static DraftStatus fromString(String? status) {
    if (status == null) return DraftStatus.notStarted;
    return DraftStatus.values.firstWhere(
      (s) => s.value == status,
      orElse: () => DraftStatus.notStarted,
    );
  }

  /// Check if the draft is currently active
  bool get isActive => this == DraftStatus.inProgress;

  /// Check if the draft can be started
  bool get canStart => this == DraftStatus.notStarted;

  /// Check if the draft is finished
  bool get isFinished => this == DraftStatus.completed;
}
