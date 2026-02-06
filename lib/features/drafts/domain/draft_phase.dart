/// Enum representing the workflow phase of a draft
enum DraftPhase {
  setup('SETUP'),
  derby('DERBY'),
  live('LIVE');

  final String value;
  const DraftPhase(this.value);

  /// Parse a string value to DraftPhase, defaulting to setup
  static DraftPhase fromString(String? phase) {
    if (phase == null) return DraftPhase.setup;
    return DraftPhase.values.firstWhere(
      (p) => p.value.toUpperCase() == phase.toUpperCase(),
      orElse: () => DraftPhase.setup,
    );
  }

  /// Check if the draft is in derby phase (slot selection)
  bool get isDerby => this == DraftPhase.derby;

  /// Check if the draft is in live phase (actual drafting)
  bool get isLive => this == DraftPhase.live;

  /// Check if the draft is still in setup phase
  bool get isSetup => this == DraftPhase.setup;
}
