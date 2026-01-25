/// Waiver claim status enum
enum WaiverClaimStatus {
  pending('pending', 'Pending'),
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
  bool get isSuccessful => this == WaiverClaimStatus.successful;
  bool get isFailed => this == WaiverClaimStatus.failed;
  bool get isCancelled => this == WaiverClaimStatus.cancelled;
  bool get isFinal =>
      this == WaiverClaimStatus.successful ||
      this == WaiverClaimStatus.failed ||
      this == WaiverClaimStatus.cancelled ||
      this == WaiverClaimStatus.invalid;
}
