import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:hypetrain_mvp/features/dm/domain/direct_message.dart';
import 'package:hypetrain_mvp/features/dm/presentation/providers/dm_conversation_provider.dart';
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
    when(() => mockSocketService.onReconnected(any())).thenReturn(() {});
  });

  tearDown(() {
    container?.dispose();
    container = null;
  });

  ProviderContainer createContainer(int conversationId) {
    return ProviderContainer(
      overrides: [
        dmRepositoryProvider.overrideWithValue(mockDmRepo),
        socketServiceProvider.overrideWithValue(mockSocketService),
      ],
    );
  }

  group('DmConversationState', () {
    test('initial state should have empty messages and loading true', () {
      final state = DmConversationState();
      expect(state.messages, isEmpty);
      expect(state.isLoading, true);
      expect(state.isSending, false);
      expect(state.error, isNull);
      expect(state.hasMore, true);
      expect(state.isLoadingMore, false);
    });

    test('copyWith should preserve values when not specified', () {
      final messages = [createMockDirectMessage()];
      final state = DmConversationState(
        messages: messages,
        isLoading: false,
        isSending: true,
        error: 'some error',
      );
      final newState = state.copyWith();

      expect(newState.messages, equals(messages));
      expect(newState.isLoading, false);
      expect(newState.isSending, true);
    });

    test('copyWith clearError should set error to null', () {
      final state = DmConversationState(error: 'some error');
      final newState = state.copyWith(clearError: true);

      expect(newState.error, isNull);
    });
  });

  group('DmConversationNotifier - loadMessages', () {
    test('should load messages from repository', () async {
      final mockMessages = [
        createMockDirectMessage(id: 1, message: 'Hello'),
        createMockDirectMessage(id: 2, message: 'Hi there'),
      ];

      when(() => mockDmRepo.getMessages(1, limit: any(named: 'limit')))
          .thenAnswer((_) async => mockMessages);
      when(() => mockDmRepo.markAsRead(1)).thenAnswer((_) async {});

      container = createContainer(1);
      final notifier = container!.read(dmConversationProvider(1).notifier);

      // Await load directly instead of using Future.delayed
      await notifier.loadMessages();

      final state = container!.read(dmConversationProvider(1));
      expect(state.messages.length, 2);
      expect(state.isLoading, false);
    });

    test('should handle errors gracefully', () async {
      when(() => mockDmRepo.getMessages(1, limit: any(named: 'limit')))
          .thenThrow(Exception('Network error'));

      container = createContainer(1);

      // Wait for initial load
      await Future.delayed(const Duration(milliseconds: 100));

      final state = container!.read(dmConversationProvider(1));
      expect(state.isLoading, false);
      expect(state.error, isNotNull);
    });
  });

  group('DmConversationNotifier - sendMessage', () {
    test('should not send empty messages', () async {
      when(() => mockDmRepo.getMessages(1, limit: any(named: 'limit')))
          .thenAnswer((_) async => []);
      when(() => mockDmRepo.markAsRead(1)).thenAnswer((_) async {});

      container = createContainer(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container!.read(dmConversationProvider(1).notifier);
      final result = await notifier.sendMessage('');

      expect(result, false);
      verifyNever(() => mockDmRepo.sendMessage(any(), any()));
    });

    test('should send message and return true on success', () async {
      final mockMessage = createMockDirectMessage(id: 1, message: 'Test message');

      when(() => mockDmRepo.getMessages(1, limit: any(named: 'limit')))
          .thenAnswer((_) async => []);
      when(() => mockDmRepo.markAsRead(1)).thenAnswer((_) async {});
      when(() => mockDmRepo.sendMessage(1, 'Test message'))
          .thenAnswer((_) async => mockMessage);

      container = createContainer(1);
      await Future.delayed(const Duration(milliseconds: 100));

      final notifier = container!.read(dmConversationProvider(1).notifier);
      final result = await notifier.sendMessage('Test message');

      expect(result, true);
      verify(() => mockDmRepo.sendMessage(1, 'Test message')).called(1);
    });

    test('should set isSending state correctly', () async {
      when(() => mockDmRepo.getMessages(1, limit: any(named: 'limit')))
          .thenAnswer((_) async => []);
      when(() => mockDmRepo.markAsRead(1)).thenAnswer((_) async {});

      // Use a Completer to control when sendMessage completes
      final sendCompleter = Completer<DirectMessage>();
      when(() => mockDmRepo.sendMessage(1, any()))
          .thenAnswer((_) => sendCompleter.future);

      container = createContainer(1);
      final notifier = container!.read(dmConversationProvider(1).notifier);

      // Await load directly instead of using Future.delayed
      await notifier.loadMessages();

      // Start sending (don't await yet)
      final future = notifier.sendMessage('Test');

      // Allow microtask to process so isSending is set to true
      await Future.microtask(() {});
      expect(container!.read(dmConversationProvider(1)).isSending, true);

      // Complete the send operation
      sendCompleter.complete(createMockDirectMessage());
      await future;
      expect(container!.read(dmConversationProvider(1)).isSending, false);
    });
  });

  group('DmConversationNotifier - message deduplication', () {
    test('should deduplicate messages by ID', () async {
      final mockMessages = [
        createMockDirectMessage(id: 1, message: 'Hello'),
        createMockDirectMessage(id: 1, message: 'Hello duplicate'),
        createMockDirectMessage(id: 2, message: 'Hi there'),
      ];

      when(() => mockDmRepo.getMessages(1, limit: any(named: 'limit')))
          .thenAnswer((_) async => mockMessages);
      when(() => mockDmRepo.markAsRead(1)).thenAnswer((_) async {});

      container = createContainer(1);
      final notifier = container!.read(dmConversationProvider(1).notifier);

      // Await load directly instead of using Future.delayed
      await notifier.loadMessages();

      final state = container!.read(dmConversationProvider(1));
      // Should only have 2 unique messages
      expect(state.messages.length, 2);
    });
  });
}
