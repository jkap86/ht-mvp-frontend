/// Returns true if a trade has enough assets on both sides to be submittable.
bool canSubmitTrade({
  required int? recipientRosterId,
  required List<int> offeringPlayerIds,
  required Set<int> offeringPickAssetIds,
  required List<int> requestingPlayerIds,
  required Set<int> requestingPickAssetIds,
}) {
  final hasAssetsToOffer =
      offeringPlayerIds.isNotEmpty || offeringPickAssetIds.isNotEmpty;
  final hasAssetsToRequest =
      requestingPlayerIds.isNotEmpty || requestingPickAssetIds.isNotEmpty;
  return recipientRosterId != null && hasAssetsToOffer && hasAssetsToRequest;
}
