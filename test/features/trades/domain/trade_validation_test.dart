import 'package:flutter_test/flutter_test.dart';
import 'package:hypetrain_mvp/features/trades/domain/trade_validation.dart';

void main() {
  group('canSubmitTrade', () {
    test('returns false when recipientRosterId is null', () {
      expect(
        canSubmitTrade(
          recipientRosterId: null,
          offeringPlayerIds: [1],
          offeringPickAssetIds: {},
          requestingPlayerIds: [2],
          requestingPickAssetIds: {},
        ),
        false,
      );
    });

    test('returns false when no assets offered', () {
      expect(
        canSubmitTrade(
          recipientRosterId: 1,
          offeringPlayerIds: [],
          offeringPickAssetIds: {},
          requestingPlayerIds: [2],
          requestingPickAssetIds: {},
        ),
        false,
      );
    });

    test('returns false when no assets requested', () {
      expect(
        canSubmitTrade(
          recipientRosterId: 1,
          offeringPlayerIds: [1],
          offeringPickAssetIds: {},
          requestingPlayerIds: [],
          requestingPickAssetIds: {},
        ),
        false,
      );
    });

    test('returns true with players on both sides', () {
      expect(
        canSubmitTrade(
          recipientRosterId: 1,
          offeringPlayerIds: [1],
          offeringPickAssetIds: {},
          requestingPlayerIds: [2],
          requestingPickAssetIds: {},
        ),
        true,
      );
    });

    test('returns true with pick assets on both sides', () {
      expect(
        canSubmitTrade(
          recipientRosterId: 1,
          offeringPlayerIds: [],
          offeringPickAssetIds: {10},
          requestingPlayerIds: [],
          requestingPickAssetIds: {20},
        ),
        true,
      );
    });

    test('returns true with mixed players and picks', () {
      expect(
        canSubmitTrade(
          recipientRosterId: 1,
          offeringPlayerIds: [1],
          offeringPickAssetIds: {},
          requestingPlayerIds: [],
          requestingPickAssetIds: {20},
        ),
        true,
      );
    });
  });
}
