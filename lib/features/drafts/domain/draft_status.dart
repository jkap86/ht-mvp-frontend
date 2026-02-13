export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show DraftStatus;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension DraftStatusUI on DraftStatus {
  bool get isActive => this == DraftStatus.inProgress;

  bool get canStart => this == DraftStatus.notStarted;

  bool get isFinished => this == DraftStatus.completed;
}
