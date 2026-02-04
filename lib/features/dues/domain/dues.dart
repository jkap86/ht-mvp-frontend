/// League dues configuration model
class LeagueDues {
  final int id;
  final int leagueId;
  final double buyInAmount;
  final Map<String, num> payoutStructure;
  final String currency;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  LeagueDues({
    required this.id,
    required this.leagueId,
    required this.buyInAmount,
    required this.payoutStructure,
    required this.currency,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory LeagueDues.fromJson(Map<String, dynamic> json) {
    return LeagueDues(
      id: json['id'] as int,
      leagueId: json['league_id'] as int,
      buyInAmount: (json['buy_in_amount'] as num).toDouble(),
      payoutStructure: Map<String, num>.from(json['payout_structure'] ?? {}),
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'league_id': leagueId,
      'buy_in_amount': buyInAmount,
      'payout_structure': payoutStructure,
      'currency': currency,
      'notes': notes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

/// Dues payment status for a roster
class DuesPayment {
  final int id;
  final int leagueId;
  final int rosterId;
  final bool isPaid;
  final DateTime? paidAt;
  final String? markedByUserId;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String teamName;
  final String username;

  DuesPayment({
    required this.id,
    required this.leagueId,
    required this.rosterId,
    required this.isPaid,
    this.paidAt,
    this.markedByUserId,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    required this.teamName,
    required this.username,
  });

  factory DuesPayment.fromJson(Map<String, dynamic> json) {
    return DuesPayment(
      id: json['id'] as int? ?? 0,
      leagueId: json['league_id'] as int,
      rosterId: json['roster_id'] as int,
      isPaid: json['is_paid'] as bool? ?? false,
      paidAt: json['paid_at'] != null ? DateTime.parse(json['paid_at'] as String) : null,
      markedByUserId: json['marked_by_user_id'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      teamName: json['team_name'] as String? ?? 'Unknown Team',
      username: json['username'] as String? ?? 'Unknown',
    );
  }
}

/// Payout entry for display
class PayoutEntry {
  final String place;
  final double amount;

  PayoutEntry({required this.place, required this.amount});

  factory PayoutEntry.fromJson(Map<String, dynamic> json) {
    return PayoutEntry(
      place: json['place'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}

/// Summary of dues collection
class DuesSummary {
  final int paidCount;
  final int totalCount;
  final double totalPot;
  final double amountCollected;

  DuesSummary({
    required this.paidCount,
    required this.totalCount,
    required this.totalPot,
    required this.amountCollected,
  });

  factory DuesSummary.fromJson(Map<String, dynamic> json) {
    return DuesSummary(
      paidCount: json['paidCount'] as int? ?? 0,
      totalCount: json['totalCount'] as int? ?? 0,
      totalPot: (json['totalPot'] as num?)?.toDouble() ?? 0,
      amountCollected: (json['amountCollected'] as num?)?.toDouble() ?? 0,
    );
  }

  double get progressPercent => totalCount > 0 ? paidCount / totalCount : 0;
}

/// Complete dues overview
class DuesOverview {
  final LeagueDues? config;
  final List<DuesPayment> payments;
  final DuesSummary summary;
  final List<PayoutEntry> payouts;

  DuesOverview({
    this.config,
    required this.payments,
    required this.summary,
    required this.payouts,
  });

  factory DuesOverview.fromJson(Map<String, dynamic> json) {
    return DuesOverview(
      config: json['config'] != null ? LeagueDues.fromJson(json['config']) : null,
      payments: (json['payments'] as List?)
              ?.map((p) => DuesPayment.fromJson(p))
              .toList() ??
          [],
      summary: DuesSummary.fromJson(json['summary'] ?? {}),
      payouts: (json['payouts'] as List?)
              ?.map((p) => PayoutEntry.fromJson(p))
              .toList() ??
          [],
    );
  }

  bool get isEnabled => config != null;
}
