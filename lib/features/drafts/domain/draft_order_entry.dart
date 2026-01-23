class DraftOrderEntry {
  final int id;
  final int draftId;
  final int rosterId;
  final int draftPosition;
  final String username;
  final int? userId;

  const DraftOrderEntry({
    required this.id,
    required this.draftId,
    required this.rosterId,
    required this.draftPosition,
    required this.username,
    this.userId,
  });

  factory DraftOrderEntry.fromJson(Map<String, dynamic> json) {
    return DraftOrderEntry(
      id: json['id'] as int,
      draftId: json['draft_id'] as int,
      rosterId: json['roster_id'] as int,
      draftPosition: json['draft_position'] as int,
      username: json['username'] as String? ?? 'Unknown',
      userId: json['user_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'draft_id': draftId,
        'roster_id': rosterId,
        'draft_position': draftPosition,
        'username': username,
        'user_id': userId,
      };
}
