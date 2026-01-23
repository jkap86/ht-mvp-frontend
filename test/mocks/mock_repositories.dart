import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/auth/data/auth_repository.dart';
import 'package:hypetrain_mvp/features/auth/domain/user.dart';
import 'package:hypetrain_mvp/features/leagues/data/league_repository.dart';
import 'package:hypetrain_mvp/features/drafts/data/draft_repository.dart';
import 'package:hypetrain_mvp/features/chat/data/chat_repository.dart';
import 'package:hypetrain_mvp/features/players/data/player_repository.dart';
import 'package:hypetrain_mvp/core/api/api_client.dart';

// Mock classes
class MockAuthRepository extends Mock implements AuthRepository {}

class MockLeagueRepository extends Mock implements LeagueRepository {}

class MockDraftRepository extends Mock implements DraftRepository {}

class MockChatRepository extends Mock implements ChatRepository {}

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockApiClient extends Mock implements ApiClient {}

// Test data helpers
User createMockUser({
  String id = 'user-123',
  String username = 'testuser',
  String email = 'test@example.com',
}) {
  return User(id: id, username: username, email: email);
}

AuthResult createMockAuthResult({
  User? user,
  String accessToken = 'mock_access_token',
  String refreshToken = 'mock_refresh_token',
}) {
  return AuthResult(
    user: user ?? createMockUser(),
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}
