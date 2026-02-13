import 'package:flutter_test/flutter_test.dart';
import 'package:hypetrain_mvp/features/drafts/domain/auction_bid_calculator.dart';
import 'package:hypetrain_mvp/features/drafts/domain/auction_budget.dart';
import 'package:hypetrain_mvp/features/drafts/domain/auction_lot.dart';
import 'package:hypetrain_mvp/features/drafts/domain/auction_settings.dart';

AuctionLot _lot({
  int currentBid = 5,
  int? currentBidderRosterId,
  int id = 1,
}) {
  return AuctionLot(
    id: id,
    draftId: 1,
    playerId: 100,
    nominatorRosterId: 10,
    currentBid: currentBid,
    currentBidderRosterId: currentBidderRosterId,
    bidCount: 1,
    bidDeadline: DateTime.now().add(const Duration(hours: 1)),
    status: 'active',
  );
}

AuctionBudget _budget({
  int rosterId = 1,
  int totalBudget = 200,
  int available = 100,
  int wonCount = 5,
  int spent = 80,
  int leadingCommitment = 20,
}) {
  return AuctionBudget(
    rosterId: rosterId,
    username: 'user',
    totalBudget: totalBudget,
    spent: spent,
    leadingCommitment: leadingCommitment,
    available: available,
    wonCount: wonCount,
  );
}

void main() {
  const settings = AuctionSettings(
    auctionMode: 'slow',
    bidWindowSeconds: 43200,
    maxActiveNominationsPerTeam: 2,
    nominationSeconds: 45,
    resetOnBidSeconds: 10,
    minBid: 1,
    minIncrement: 1,
  );

  final calc = AuctionBidCalculator(settings: settings, totalRosterSpots: 15);

  group('isLeading', () {
    test('returns true when roster matches leading bidder', () {
      expect(calc.isLeading(_lot(currentBidderRosterId: 1), 1), true);
    });

    test('returns false when roster does not match', () {
      expect(calc.isLeading(_lot(currentBidderRosterId: 2), 1), false);
    });

    test('returns false when myRosterId is null', () {
      expect(calc.isLeading(_lot(currentBidderRosterId: 1), null), false);
    });

    test('returns false when no current bidder', () {
      expect(calc.isLeading(_lot(), 1), false);
    });
  });

  group('minBid', () {
    test('leader min bid is current bid', () {
      final lot = _lot(currentBid: 10, currentBidderRosterId: 1);
      expect(calc.minBid(lot, 1), 10);
    });

    test('non-leader min bid is current bid + increment', () {
      final lot = _lot(currentBid: 10, currentBidderRosterId: 2);
      expect(calc.minBid(lot, 1), 11);
    });
  });

  group('maxBid', () {
    test('returns available budget for non-leader', () {
      final lot = _lot(currentBid: 10, currentBidderRosterId: 2);
      final budget = _budget(available: 50);
      expect(calc.maxBid(lot, budget, 1), 50);
    });

    test('leader gets current bid added to available', () {
      final lot = _lot(currentBid: 10, currentBidderRosterId: 1);
      final budget = _budget(rosterId: 1, available: 50);
      expect(calc.maxBid(lot, budget, 1), 60);
    });

    test('returns null when budget is null', () {
      expect(calc.maxBid(_lot(), null, 1), null);
    });
  });

  group('maxPossibleBid', () {
    test('reserves budget for remaining spots', () {
      // 15 spots, 5 won = 10 remaining. Reserve 9 * $1 = $9. Available = $100 - $9 = $91.
      final lot = _lot(currentBid: 5, currentBidderRosterId: 2);
      final budget = _budget(available: 100, wonCount: 5);
      expect(calc.maxPossibleBid(lot, budget, 1), 91);
    });

    test('leader adds current bid to max possible', () {
      final lot = _lot(currentBid: 5, currentBidderRosterId: 1);
      final budget = _budget(rosterId: 1, available: 100, wonCount: 5);
      // Reserve 9 * $1 = $9. Available = $100 - $9 + $5 (leader reuse) = $96.
      expect(calc.maxPossibleBid(lot, budget, 1), 96);
    });

    test('last spot edge case: can bid everything', () {
      final lot = _lot(currentBid: 5, currentBidderRosterId: 2);
      final budget = _budget(available: 100, wonCount: 14); // 14 won, 1 remaining
      expect(calc.maxPossibleBid(lot, budget, 1), 100);
    });

    test('returns 0 not negative when reserved exceeds available', () {
      final lot = _lot(currentBid: 5, currentBidderRosterId: 2);
      final budget = _budget(available: 5, wonCount: 0); // Reserve 14 * $1 = $14 > $5
      expect(calc.maxPossibleBid(lot, budget, 1), 0);
    });

    test('returns null when budget is null', () {
      expect(calc.maxPossibleBid(_lot(), null, 1), null);
    });
  });

  group('maxPossibleBidForBudget', () {
    test('reserves budget for remaining spots', () {
      final budget = _budget(available: 100, wonCount: 5);
      // 15 - 5 = 10 remaining. Reserve 9 * $1 = $9. Max = $91.
      expect(calc.maxPossibleBidForBudget(budget), 91);
    });

    test('last spot: can use full budget', () {
      final budget = _budget(available: 100, wonCount: 14);
      expect(calc.maxPossibleBidForBudget(budget), 100);
    });

    test('returns 0 when reserved exceeds available', () {
      final budget = _budget(available: 5, wonCount: 0);
      expect(calc.maxPossibleBidForBudget(budget), 0);
    });
  });

  group('validateBid', () {
    test('returns error when lot is null', () {
      expect(calc.validateBid('10', null, null, 1), 'This lot has ended');
    });

    test('returns error for empty value', () {
      expect(calc.validateBid('', _lot(), null, 1), 'Please enter a bid amount');
      expect(calc.validateBid(null, _lot(), null, 1), 'Please enter a bid amount');
    });

    test('returns error for non-numeric value', () {
      expect(calc.validateBid('abc', _lot(), null, 1), 'Please enter a valid number');
    });

    test('non-leader below min bid returns error', () {
      final lot = _lot(currentBid: 10, currentBidderRosterId: 2);
      expect(calc.validateBid('10', lot, null, 1), 'Bid must be at least \$11');
    });

    test('leader below system minBid returns error', () {
      final lot = _lot(currentBid: 5, currentBidderRosterId: 1);
      expect(calc.validateBid('0', lot, null, 1), 'Bid must be at least \$1');
    });

    test('leader below current commitment returns error', () {
      final lot = _lot(currentBid: 5, currentBidderRosterId: 1);
      expect(
        calc.validateBid('3', lot, null, 1),
        'Max bid must be at least \$5 (your current commitment)',
      );
    });

    test('bid exceeding budget returns error', () {
      final lot = _lot(currentBid: 5, currentBidderRosterId: 2);
      final budget = _budget(available: 10);
      expect(
        calc.validateBid('15', lot, budget, 1),
        'Bid exceeds your available budget (\$10)',
      );
    });

    test('valid non-leader bid returns null', () {
      final lot = _lot(currentBid: 5, currentBidderRosterId: 2);
      final budget = _budget(available: 100);
      expect(calc.validateBid('6', lot, budget, 1), null);
    });

    test('valid leader bid returns null', () {
      final lot = _lot(currentBid: 5, currentBidderRosterId: 1);
      final budget = _budget(rosterId: 1, available: 100);
      expect(calc.validateBid('50', lot, budget, 1), null);
    });
  });

  group('with higher minBid / minIncrement settings', () {
    final customSettings = settings.copyWith(minBid: 5, minIncrement: 5);
    final customCalc =
        AuctionBidCalculator(settings: customSettings, totalRosterSpots: 10);

    test('minBid uses custom increment', () {
      final lot = _lot(currentBid: 20, currentBidderRosterId: 2);
      expect(customCalc.minBid(lot, 1), 25);
    });

    test('reserved uses custom minBid', () {
      final lot = _lot(currentBid: 10, currentBidderRosterId: 2);
      final budget = _budget(available: 100, wonCount: 5);
      // 10 - 5 = 5 remaining. Reserve 4 * $5 = $20. Max = $80.
      expect(customCalc.maxPossibleBid(lot, budget, 1), 80);
    });
  });
}
