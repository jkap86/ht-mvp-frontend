/// Formats timestamps for chat and DM messages.
///
/// Provides two formatting modes:
/// - Absolute format: "m/d/yy h:mm AM/PM" (e.g., "1/15/26 3:45 PM")
/// - Compact format: "Now", "5m", "2h", "2d", "M/D" for inbox/conversation lists
String formatMessageTimestamp(DateTime dateTime, {bool compact = false}) {
  // Convert UTC to local timezone
  final localTime = dateTime.toLocal();
  final now = DateTime.now();

  if (compact) {
    // For inbox/conversation list only - shows relative time in compact form
    final diff = now.difference(localTime);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${localTime.month}/${localTime.day}';
  }

  // Absolute format for in-message timestamps
  // Convert to 12-hour format
  final hour = localTime.hour > 12
      ? localTime.hour - 12
      : (localTime.hour == 0 ? 12 : localTime.hour);
  final period = localTime.hour >= 12 ? 'PM' : 'AM';
  final minute = localTime.minute.toString().padLeft(2, '0');

  // Always include 2-digit year
  final year = localTime.year % 100;

  return '${localTime.month}/${localTime.day}/$year $hour:$minute $period';
}
