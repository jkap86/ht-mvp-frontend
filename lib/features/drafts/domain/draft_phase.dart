export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show DraftPhase;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension DraftPhaseUI on DraftPhase {
  bool get isDerby => this == DraftPhase.derby;

  bool get isLive => this == DraftPhase.live;

  bool get isSetup => this == DraftPhase.setup;
}
