/// Represents a roster's budget in a slow auction draft.
class AuctionBudget {
  final int rosterId;
  final String username;
  final int totalBudget;
  final int spent;
  final int leadingCommitment;
  final int available;
  final int wonCount;

  AuctionBudget({
    required this.rosterId,
    required this.username,
    required this.totalBudget,
    required this.spent,
    required this.leadingCommitment,
    required this.available,
    required this.wonCount,
  });

  factory AuctionBudget.fromJson(Map<String, dynamic> json) {
    return AuctionBudget(
      rosterId: json['roster_id'] as int? ?? json['rosterId'] as int? ?? 0,
      username: json['username'] as String? ?? 'Unknown',
      totalBudget: json['total_budget'] as int? ?? json['totalBudget'] as int? ?? 200,
      spent: json['spent'] as int? ?? 0,
      leadingCommitment: json['leading_commitment'] as int? ?? json['leadingCommitment'] as int? ?? 0,
      available: json['available'] as int? ?? 200,
      wonCount: json['won_count'] as int? ?? json['wonCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roster_id': rosterId,
      'username': username,
      'total_budget': totalBudget,
      'spent': spent,
      'leading_commitment': leadingCommitment,
      'available': available,
      'won_count': wonCount,
    };
  }

  AuctionBudget copyWith({
    int? rosterId,
    String? username,
    int? totalBudget,
    int? spent,
    int? leadingCommitment,
    int? available,
    int? wonCount,
  }) {
    return AuctionBudget(
      rosterId: rosterId ?? this.rosterId,
      username: username ?? this.username,
      totalBudget: totalBudget ?? this.totalBudget,
      spent: spent ?? this.spent,
      leadingCommitment: leadingCommitment ?? this.leadingCommitment,
      available: available ?? this.available,
      wonCount: wonCount ?? this.wonCount,
    );
  }

  @override
  String toString() {
    return 'AuctionBudget(rosterId: $rosterId, username: $username, available: $available, spent: $spent)';
  }
}
