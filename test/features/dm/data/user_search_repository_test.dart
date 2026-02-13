import 'package:flutter_test/flutter_test.dart';
import 'package:hypetrain_mvp/features/dm/data/user_search_repository.dart';

void main() {
  group('UserSearchResult.fromJson', () {
    test('parses id and username', () {
      final result = UserSearchResult.fromJson({
        'id': 'abc-123',
        'username': 'testuser',
      });
      expect(result.id, 'abc-123');
      expect(result.username, 'testuser');
    });

    test('falls back to userId field', () {
      final result = UserSearchResult.fromJson({
        'userId': 'abc-456',
        'username': 'otheruser',
      });
      expect(result.id, 'abc-456');
    });

    test('defaults to empty id and Unknown username', () {
      final result = UserSearchResult.fromJson({});
      expect(result.id, '');
      expect(result.username, 'Unknown');
    });
  });
}
