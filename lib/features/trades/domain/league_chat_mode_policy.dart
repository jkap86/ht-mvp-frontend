const _modeOrder = ['none', 'summary', 'details'];

/// Clamp a chat mode to be at most [max] in the ordered hierarchy.
/// Returns 'summary' if either value is unrecognized.
String clampChatMode(String mode, String max) {
  final modeIdx = _modeOrder.indexOf(mode);
  final maxIdx = _modeOrder.indexOf(max);
  if (modeIdx < 0 || maxIdx < 0) return 'summary';
  return _modeOrder[modeIdx.clamp(0, maxIdx)];
}

/// Resolve the default league chat mode from league settings.
String resolveDefaultChatMode(Map<String, dynamic>? leagueSettings) {
  final max =
      (leagueSettings?['tradeProposalLeagueChatMax'] as String?) ?? 'details';
  final defaultMode =
      (leagueSettings?['tradeProposalLeagueChatDefault'] as String?) ??
          'summary';
  return clampChatMode(defaultMode, max);
}

/// Return the list of allowed chat modes given the league max setting.
List<String> allowedChatModes(Map<String, dynamic>? leagueSettings) {
  final max =
      (leagueSettings?['tradeProposalLeagueChatMax'] as String?) ?? 'details';
  final maxIdx = _modeOrder.indexOf(max);
  if (maxIdx < 0) return List.of(_modeOrder);
  return _modeOrder.sublist(0, maxIdx + 1);
}
