export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show DraftType;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension DraftTypeUI on DraftType {
  String get label => switch (this) {
    DraftType.snake => 'Snake',
    DraftType.linear => 'Linear',
    DraftType.auction => 'Auction',
    DraftType.matchups => 'Matchups',
  };

  String get description => switch (this) {
    DraftType.snake => 'Pick order reverses each round',
    DraftType.linear => 'Same pick order every round',
    DraftType.auction => 'Bid on players with a budget',
    DraftType.matchups => 'Draft your schedule strategically',
  };

  bool get isAuction => this == DraftType.auction;

  bool get isMatchups => this == DraftType.matchups;
}
