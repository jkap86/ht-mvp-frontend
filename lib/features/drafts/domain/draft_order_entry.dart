class DraftOrderEntry {
  final int id;
  final int draftId;
  final int rosterId;
  final int draftPosition;
  final String username;
  final String? userId;  // UUID string from backend
  final bool isAutodraftEnabled;

  const DraftOrderEntry({
    required this.id,
    required this.draftId,
    required this.rosterId,
    required this.draftPosition,
    required this.username,
    this.userId,
    this.isAutodraftEnabled = false,
  });

  factory DraftOrderEntry.fromJson(Map<String, dynamic> json) {
    return DraftOrderEntry(
      id: json['id'] as int? ?? 0,
      draftId: json['draft_id'] as int? ?? json['draftId'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      draftPosition: json['draft_position'] as int? ?? json['draftPosition'] as int? ?? 0,
      username: json['username'] as String? ?? 'Unknown',
      userId: json['user_id'] as String? ?? json['userId'] as String?,
      isAutodraftEnabled: json['is_autodraft_enabled'] as bool? ?? json['isAutodraftEnabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'draft_id': draftId,
        'roster_id': rosterId,
        'draft_position': draftPosition,
        'username': username,
        'user_id': userId,
        'is_autodraft_enabled': isAutodraftEnabled,
      };

  DraftOrderEntry copyWith({
    int? id,
    int? draftId,
    int? rosterId,
    int? draftPosition,
    String? username,
    String? userId,
    bool? isAutodraftEnabled,
  }) {
    return DraftOrderEntry(
      id: id ?? this.id,
      draftId: draftId ?? this.draftId,
      rosterId: rosterId ?? this.rosterId,
      draftPosition: draftPosition ?? this.draftPosition,
      username: username ?? this.username,
      userId: userId ?? this.userId,
      isAutodraftEnabled: isAutodraftEnabled ?? this.isAutodraftEnabled,
    );
  }
}
