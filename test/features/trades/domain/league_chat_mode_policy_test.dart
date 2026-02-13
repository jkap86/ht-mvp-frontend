import 'package:flutter_test/flutter_test.dart';
import 'package:hypetrain_mvp/features/trades/domain/league_chat_mode_policy.dart';

void main() {
  group('clampChatMode', () {
    test('returns mode unchanged when within max', () {
      expect(clampChatMode('none', 'details'), 'none');
      expect(clampChatMode('summary', 'details'), 'summary');
      expect(clampChatMode('details', 'details'), 'details');
    });

    test('clamps mode down to max', () {
      expect(clampChatMode('details', 'summary'), 'summary');
      expect(clampChatMode('details', 'none'), 'none');
      expect(clampChatMode('summary', 'none'), 'none');
    });

    test('returns summary for unrecognized mode', () {
      expect(clampChatMode('invalid', 'details'), 'summary');
    });

    test('returns summary for unrecognized max', () {
      expect(clampChatMode('summary', 'invalid'), 'summary');
    });
  });

  group('resolveDefaultChatMode', () {
    test('returns clamped default from settings', () {
      expect(
        resolveDefaultChatMode({
          'tradeProposalLeagueChatMax': 'summary',
          'tradeProposalLeagueChatDefault': 'details',
        }),
        'summary',
      );
    });

    test('uses summary default when not specified', () {
      expect(resolveDefaultChatMode(null), 'summary');
      expect(resolveDefaultChatMode({}), 'summary');
    });

    test('respects explicit default within max', () {
      expect(
        resolveDefaultChatMode({
          'tradeProposalLeagueChatMax': 'details',
          'tradeProposalLeagueChatDefault': 'none',
        }),
        'none',
      );
    });
  });

  group('allowedChatModes', () {
    test('returns all modes when max is details', () {
      expect(
        allowedChatModes({'tradeProposalLeagueChatMax': 'details'}),
        ['none', 'summary', 'details'],
      );
    });

    test('returns none and summary when max is summary', () {
      expect(
        allowedChatModes({'tradeProposalLeagueChatMax': 'summary'}),
        ['none', 'summary'],
      );
    });

    test('returns only none when max is none', () {
      expect(
        allowedChatModes({'tradeProposalLeagueChatMax': 'none'}),
        ['none'],
      );
    });

    test('defaults to all modes when settings null', () {
      expect(allowedChatModes(null), ['none', 'summary', 'details']);
    });
  });
}
