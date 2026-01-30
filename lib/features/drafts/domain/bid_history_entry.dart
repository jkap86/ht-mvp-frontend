/// Represents a single bid entry in auction lot history.
class BidHistoryEntry {
  final int id;
  final int lotId;
  final int rosterId;
  final String? username;
  final int bidAmount;
  final bool isProxy;
  final DateTime createdAt;

  BidHistoryEntry({
    required this.id,
    required this.lotId,
    required this.rosterId,
    this.username,
    required this.bidAmount,
    required this.isProxy,
    required this.createdAt,
  });

  factory BidHistoryEntry.fromJson(Map<String, dynamic> json) {
    return BidHistoryEntry(
      id: json['id'] as int? ?? 0,
      lotId: json['lot_id'] as int? ?? json['lotId'] as int? ?? 0,
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      username: json['username'] as String?,
      bidAmount: json['bid_amount'] as int? ?? json['bidAmount'] as int? ?? 0,
      isProxy: json['is_proxy'] as bool? ?? json['isProxy'] as bool? ?? false,
      createdAt: DateTime.tryParse(
              json['created_at'] as String? ?? json['createdAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lot_id': lotId,
      'roster_id': rosterId,
      'username': username,
      'bid_amount': bidAmount,
      'is_proxy': isProxy,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'BidHistoryEntry(id: $id, rosterId: $rosterId, bidAmount: $bidAmount, isProxy: $isProxy)';
  }
}
