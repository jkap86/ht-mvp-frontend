export 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart' show WaiverClaimStatus;

import 'package:hypetrain_mvp/api_contracts/v1/common/enums.dart';

extension WaiverClaimStatusUI on WaiverClaimStatus {
  String get label => switch (this) {
    WaiverClaimStatus.pending => 'Pending',
    WaiverClaimStatus.processing => 'Processing',
    WaiverClaimStatus.successful => 'Successful',
    WaiverClaimStatus.failed => 'Failed',
    WaiverClaimStatus.cancelled => 'Cancelled',
    WaiverClaimStatus.invalid => 'Invalid',
  };

  bool get isPending => this == WaiverClaimStatus.pending;
  bool get isProcessing => this == WaiverClaimStatus.processing;
  bool get isSuccessful => this == WaiverClaimStatus.successful;
  bool get isFailed => this == WaiverClaimStatus.failed;
  bool get isCancelled => this == WaiverClaimStatus.cancelled;
  bool get isFinal =>
      this == WaiverClaimStatus.successful ||
      this == WaiverClaimStatus.failed ||
      this == WaiverClaimStatus.cancelled ||
      this == WaiverClaimStatus.invalid;

  String get description => switch (this) {
    WaiverClaimStatus.pending => 'Waiting for next waiver processing run',
    WaiverClaimStatus.processing => 'Currently being processed',
    WaiverClaimStatus.successful => 'Player added to your roster',
    WaiverClaimStatus.failed => 'Claim was not successful',
    WaiverClaimStatus.cancelled => 'Claim was cancelled',
    WaiverClaimStatus.invalid => 'Claim is no longer valid',
  };
}
