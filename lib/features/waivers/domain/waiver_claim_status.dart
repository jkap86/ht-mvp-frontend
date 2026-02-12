/// Waiver claim status enum
enum WaiverClaimStatus {
  pending('pending', 'Pending'),
  processing('processing', 'Processing'),
  successful('successful', 'Successful'),
  failed('failed', 'Failed'),
  cancelled('cancelled', 'Cancelled'),
  invalid('invalid', 'Invalid');

  final String value;
  final String label;

  const WaiverClaimStatus(this.value, this.label);

  static WaiverClaimStatus fromString(String? value) {
    return WaiverClaimStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => WaiverClaimStatus.pending,
    );
  }

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

  /// A human-readable description of what this status means
  String get description {
    switch (this) {
      case WaiverClaimStatus.pending:
        return 'Waiting for next waiver processing run';
      case WaiverClaimStatus.processing:
        return 'Currently being processed';
      case WaiverClaimStatus.successful:
        return 'Player added to your roster';
      case WaiverClaimStatus.failed:
        return 'Claim was not successful';
      case WaiverClaimStatus.cancelled:
        return 'Claim was cancelled';
      case WaiverClaimStatus.invalid:
        return 'Claim is no longer valid';
    }
  }
}
