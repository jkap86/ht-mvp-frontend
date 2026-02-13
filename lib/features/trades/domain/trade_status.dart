export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show TradeStatus;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension TradeStatusUI on TradeStatus {
  String get label => switch (this) {
    TradeStatus.pending => 'Pending',
    TradeStatus.countered => 'Countered',
    TradeStatus.accepted => 'Accepted',
    TradeStatus.inReview => 'In Review',
    TradeStatus.completed => 'Completed',
    TradeStatus.rejected => 'Rejected',
    TradeStatus.cancelled => 'Cancelled',
    TradeStatus.expired => 'Expired',
    TradeStatus.vetoed => 'Vetoed',
  };

  bool get isPending =>
      this == TradeStatus.pending || this == TradeStatus.countered;

  bool get isActive =>
      isPending ||
      this == TradeStatus.accepted ||
      this == TradeStatus.inReview;

  bool get isFinal =>
      this == TradeStatus.completed ||
      this == TradeStatus.rejected ||
      this == TradeStatus.cancelled ||
      this == TradeStatus.expired ||
      this == TradeStatus.vetoed;
}
