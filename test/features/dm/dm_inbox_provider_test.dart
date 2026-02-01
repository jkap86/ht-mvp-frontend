import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/dm/presentation/providers/dm_inbox_provider.dart';
import 'package:hypetrain_mvp/features/dm/data/dm_repository.dart';
import 'package:hypetrain_mvp/core/socket/socket_service.dart';

import '../../mocks/mock_repositories.dart';
import '../../mocks/mock_socket_service.dart';

void main() {
  late MockDmRepository mockDmRepo;
  late MockSocketService mockSocketService;
  ProviderContainer? container;

  setUp(() {
    mockDmRepo = MockDmRepository();
    mockSocketService = MockSocketService();

    // Set up default socket service behavior
    when(() => mockSocketService.onDmMessage(any())).thenReturn(() {});
    when(() => mockSocketService.onDmRead(any())).thenReturn(() {});
    when(() => mockSocketService.onReconnected(any())).thenReturn(() {});
  });

  tearDown(() {
    container?.dispose();
    container = null;
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        dmRepositoryProvider.overrideWithValue(mockDmRepo),
        socketServiceProvider.overrideWithValue(mockSocketService),
      ],
    );
  }

  group('DmInboxState', () {
    test('initial state should have empty conversations and loading true', () {
      final state = DmInboxState();
      expect(state.conversations, isEmpty);
      expect(state.isLoading, true);
      expect(state.error, isNull);
      expect(state.totalUnreadCount, 0);
    });

    test('copyWith should preserve values when not specified', () {
      final conversations = [createMockConversation()];
      final state = DmInboxState(
        conversations: conversations,
        isLoading: false,
        totalUnreadCount: 5,
        error: 'some error',
      );
      final newState = state.copyWith();

      expect(newState.conversations, equals(conversations));
      expect(newState.isLoading, false);
      expect(newState.totalUnreadCount, 5);
    });

    test('copyWith clearError should set error to null', () {
      final state = DmInboxState(error: 'some error');
      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
    });
  });

  group('DmInboxNotifier - loadConversations', () {
    test('should load conversations from repository', () async {
      final mockConversations = [
        createMockConversation(id: 1, otherUsername: 'user1', unreadCount: 2),
        createMockConversation(id: 2, otherUsername: 'user2', unreadCount: 3),
      ];

      when(() => mockDmRepo.getConversations())
          .thenAnswer((_) async => mockConversations);

      container = createContainer();

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container!.read(dmInboxProvider);
      expect(state.conversations.length, 2);
      expect(state.isLoading, false);
      expect(state.totalUnreadCount, 5); // 2 + 3
    });

    test('should handle errors gracefully', () async {
      when(() => mockDmRepo.getConversations())
          .thenThrow(Exception('Network error'));

      container = createContainer();

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container!.read(dmInboxProvider);
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });
  });

  group('DmInboxNotifier - markConversationReadLocally', () {
    test('should set unread count to 0 for conversation', () async {
      final mockConversations = [
        createMockConversation(id: 1, unreadCount: 5),
        createMockConversation(id: 2, unreadCount: 3),
      ];

      when(() => mockDmRepo.getConversations())
          .thenAnswer((_) async => mockConversations);

      container = createContainer();
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container!.read(dmInboxProvider.notifier);
      notifier.markConversationReadLocally(1);

      final state = container!.read(dmInboxProvider);
      final conversation = state.conversations.firstWhere((c) => c.id == 1);
      expect(conversation.unreadCount, 0);
      expect(state.totalUnreadCount, 3); // Only conversation 2's unread
    });

    test('should update total unread count', () async {
      final mockConversations = [
        createMockConversation(id: 1, unreadCount: 5),
        createMockConversation(id: 2, unreadCount: 3),
      ];

      when(() => mockDmRepo.getConversations())
          .thenAnswer((_) async => mockConversations);

      container = createContainer();
      await Future.delayed(const Duration(milliseconds: 100));

      // Initial total should be 8
      expect(container!.read(dmInboxProvider).totalUnreadCount, 8);

      final notifier = container!.read(dmInboxProvider.notifier);
      notifier.markConversationReadLocally(1);

      // After marking conversation 1 as read, should be 3
      expect(container!.read(dmInboxProvider).totalUnreadCount, 3);
    });
  });
}
