# Socket Session Manager Guide

## Overview

The `SocketSessionManager` provides a centralized API for managing socket connections, room subscriptions, and lifecycle events in the HypeTrain MVP app.

## Architecture

```
SocketSessionManager (high-level API)
    ├── SocketService (low-level socket.io wrapper)
    ├── SocketLifecycleEventBus (typed lifecycle events)
    └── SocketSessionContext (current league/draft/user context)
```

## Key Features

1. **Connection Management**: Connect, disconnect, and reconnect with fresh tokens
2. **Context Tracking**: Track current league, draft, and user context
3. **Lifecycle Events**: Subscribe to typed connection lifecycle events
4. **Room Management**: Coordinate room joins/leaves (delegates to SocketService)
5. **App Lifecycle**: Integrates with app background/foreground transitions

## Quick Start

### 1. Basic Setup (App Initialization)

```dart
// In your app initialization (e.g., main.dart or root widget)
class MyApp extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Initialize session manager
    final sessionManager = ref.watch(socketSessionManagerProvider);

    // Connect on app startup (after auth)
    ref.listen(authStateProvider, (previous, next) {
      next.when(
        authenticated: (_) {
          // User logged in - connect socket
          sessionManager.connect();
        },
        unauthenticated: () {
          // User logged out - disconnect socket
          sessionManager.disconnect();
        },
      );
    });

    return MaterialApp(
      // ... your app
    );
  }
}
```

### 2. Listening to Lifecycle Events

```dart
// In a provider or widget
class MyNotifier extends StateNotifier<MyState> {
  final SocketSessionManager _sessionManager;
  StreamSubscription? _lifecycleSubscription;

  MyNotifier(this._sessionManager) : super(MyState()) {
    _setupLifecycleListener();
  }

  void _setupLifecycleListener() {
    _lifecycleSubscription = _sessionManager.lifecycleStream.listen((event) {
      switch (event) {
        case SocketLifecycleEvent.connected:
          // Initial connection - load data
          _loadInitialData();
          break;
        case SocketLifecycleEvent.disconnected:
          // Lost connection - show offline UI
          _handleDisconnected();
          break;
        case SocketLifecycleEvent.reconnectedLight:
          // Reconnected after brief disconnect (<30s)
          // Refresh latest state
          _refreshLatestData();
          break;
        case SocketLifecycleEvent.reconnectedFull:
          // Reconnected after long disconnect (>30s)
          // Do full data reload
          _loadAllData();
          break;
        case SocketLifecycleEvent.reconnectFailed:
          // Reconnection failed - show error
          _handleReconnectFailed();
          break;
      }
    });
  }

  @override
  void dispose() {
    _lifecycleSubscription?.cancel();
    super.dispose();
  }
}
```

### 3. Using Context Tracking

```dart
// Set context when navigating to a league
void onLeagueEntered(int leagueId) {
  final sessionManager = ref.read(socketSessionManagerProvider);
  sessionManager.setLeagueContext(leagueId);
}

// Clear context when leaving
void onLeagueExited() {
  final sessionManager = ref.read(socketSessionManagerProvider);
  sessionManager.clearLeagueContext();
}

// Listen to context changes
sessionManager.contextStream.listen((context) {
  print('Current context: league=${context.leagueId}, draft=${context.draftId}');
});
```

### 4. Room Management (Existing Pattern - No Change Needed)

The session manager **tracks context** but **delegates actual room management** to individual feature socket handlers. This is intentional - features still control their own room subscriptions using reference counting.

```dart
// Existing pattern (still works as-is)
class ChatSocketHandler {
  void setupListeners() {
    // Join league room (reference counted)
    _socketService.joinLeague(leagueId);

    // Setup listeners...
  }

  void dispose() {
    // Leave league room (reference counted)
    _socketService.leaveLeague(leagueId);
  }
}
```

The session manager complements this by:
- Tracking which league/draft is "current" for the user
- Providing a single source of truth for app-wide context
- Coordinating lifecycle events across features

### 5. Direct Socket Access

For features that need direct socket access (emitting events, custom listeners):

```dart
// Get the underlying SocketService
final socketService = sessionManager.socketService;

// Use it directly
final disposer = socketService.onChatMessage((data) {
  // Handle message
});

// Don't forget to dispose
disposer();
```

## Provider API

### Core Providers

```dart
// Session manager instance
final sessionManager = ref.watch(socketSessionManagerProvider);

// Lifecycle events stream
final lifecycleStream = ref.watch(socketLifecycleEventsProvider);

// Session context stream
final contextStream = ref.watch(socketSessionContextProvider);

// Current connection state (boolean)
final isConnected = ref.watch(sessionConnectionStateProvider);
```

### Example: React to Connection State in UI

```dart
class ConnectionBanner extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = ref.watch(sessionConnectionStateProvider);

    if (!isConnected) {
      return Container(
        color: Colors.red,
        padding: EdgeInsets.all(8),
        child: Text('Disconnected - Reconnecting...'),
      );
    }

    return SizedBox.shrink();
  }
}
```

## Migration Guide

### Existing Code

```dart
// Old pattern - directly using SocketService
class MyProvider extends StateNotifier<MyState> {
  final SocketService _socketService;
  VoidCallback? _reconnectDisposer;

  MyProvider(this._socketService) : super(MyState()) {
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (needsFullRefresh) {
        loadAllData();
      } else {
        refreshData();
      }
    });
  }

  @override
  void dispose() {
    _reconnectDisposer?.call();
    super.dispose();
  }
}
```

### New Pattern (Optional - Both Work)

```dart
// New pattern - using SocketSessionManager
class MyProvider extends StateNotifier<MyState> {
  final SocketSessionManager _sessionManager;
  StreamSubscription? _lifecycleSubscription;

  MyProvider(this._sessionManager) : super(MyState()) {
    _lifecycleSubscription = _sessionManager.lifecycleStream.listen((event) {
      if (event == SocketLifecycleEvent.reconnectedFull) {
        loadAllData();
      } else if (event == SocketLifecycleEvent.reconnectedLight) {
        refreshData();
      }
    });
  }

  @override
  void dispose() {
    _lifecycleSubscription?.cancel();
    super.dispose();
  }
}
```

**Note**: The old pattern still works! The session manager is **additive** - it provides a cleaner API but doesn't break existing code.

## Best Practices

### 1. Context Management

- Set context when user navigates to a league/draft screen
- Clear context when user leaves (via back button, logout, etc.)
- Use context stream to react to context changes if needed

```dart
// Good: Set context on navigation
void onLeagueScreenEntered(int leagueId) {
  ref.read(socketSessionManagerProvider).setLeagueContext(leagueId);
}

// Good: Clear context on exit
void onLeagueScreenExited() {
  ref.read(socketSessionManagerProvider).clearLeagueContext();
}
```

### 2. Lifecycle Event Handling

- Use `reconnectedLight` for lightweight refreshes (e.g., fetch latest messages)
- Use `reconnectedFull` for full reloads (e.g., reload entire chat history)
- Handle `disconnected` to show offline UI
- Handle `reconnectFailed` to show error state

```dart
lifecycleStream.listen((event) {
  switch (event) {
    case SocketLifecycleEvent.reconnectedLight:
      // Quick refresh - just get latest updates
      fetchLatestMessages();
      break;
    case SocketLifecycleEvent.reconnectedFull:
      // Full reload - user was offline for >30s
      loadAllMessages();
      break;
    case SocketLifecycleEvent.disconnected:
      // Show "reconnecting..." banner
      showOfflineBanner();
      break;
    case SocketLifecycleEvent.reconnectFailed:
      // Show error, allow manual retry
      showReconnectError();
      break;
  }
});
```

### 3. Room Management

- Let socket handlers manage rooms (existing pattern is good)
- Use session manager for context tracking only
- Don't manually join/leave rooms in multiple places

```dart
// Good: Socket handler manages room
class ChatSocketHandler {
  void setupListeners() {
    _socketService.joinLeague(leagueId); // Reference counted
    // ... setup listeners
  }

  void dispose() {
    _socketService.leaveLeague(leagueId); // Reference counted
  }
}

// Bad: Manually managing rooms in multiple places
// DON'T DO THIS - use socket handlers instead
sessionManager.socketService.joinLeague(leagueId);
// ... somewhere else
sessionManager.socketService.joinLeague(leagueId); // Duplicate join!
```

### 4. Disposal

- Always dispose socket handlers in provider dispose
- Cancel lifecycle stream subscriptions
- Don't dispose the session manager itself (Riverpod handles it)

```dart
@override
void dispose() {
  _socketHandler?.dispose(); // Dispose socket handler
  _lifecycleSubscription?.cancel(); // Cancel stream subscription
  super.dispose();
}
```

## Testing

### Mocking the Session Manager

```dart
// Create a mock session manager for tests
class MockSocketSessionManager extends Mock implements SocketSessionManager {}

// Use it in tests
testWidgets('handles disconnection', (tester) async {
  final mockManager = MockSocketSessionManager();
  final streamController = StreamController<SocketLifecycleEvent>();

  when(mockManager.lifecycleStream).thenAnswer((_) => streamController.stream);
  when(mockManager.isConnected).thenReturn(false);

  // Test your widget/provider
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        socketSessionManagerProvider.overrideWithValue(mockManager),
      ],
      child: MyApp(),
    ),
  );

  // Emit disconnection event
  streamController.add(SocketLifecycleEvent.disconnected);
  await tester.pump();

  // Verify UI shows offline state
  expect(find.text('Disconnected'), findsOneWidget);
});
```

## Common Patterns

### Pattern 1: League Chat Screen

```dart
class ChatProvider extends StateNotifier<ChatState> {
  final SocketSessionManager _sessionManager;
  final ChatRepository _chatRepo;
  ChatSocketHandler? _socketHandler;

  ChatProvider(this._sessionManager, this._chatRepo, int leagueId)
      : super(ChatState()) {
    // Set league context
    _sessionManager.setLeagueContext(leagueId);

    // Setup socket handler (handles room join/leave)
    _socketHandler = ChatSocketHandler(
      socketService: _sessionManager.socketService,
      leagueId: leagueId,
      callbacks: this,
    );
    _socketHandler!.setupListeners();

    // Load initial data
    loadMessages();
  }

  @override
  void dispose() {
    _socketHandler?.dispose();
    _sessionManager.clearLeagueContext();
    super.dispose();
  }
}
```

### Pattern 2: Draft Room Screen

```dart
class DraftRoomProvider extends StateNotifier<DraftState> {
  final SocketSessionManager _sessionManager;
  final DraftRepository _draftRepo;
  DraftSocketHandler? _socketHandler;

  DraftRoomProvider(this._sessionManager, this._draftRepo, int draftId)
      : super(DraftState()) {
    // Set draft context
    _sessionManager.setDraftContext(draftId);

    // Setup socket handler (handles room join/leave)
    _socketHandler = DraftSocketHandler(
      socketService: _sessionManager.socketService,
      draftId: draftId,
      callbacks: this,
    );
    _socketHandler!.setupListeners();

    // Load initial data
    loadDraftData();
  }

  @override
  void dispose() {
    _socketHandler?.dispose();
    _sessionManager.clearDraftContext();
    super.dispose();
  }
}
```

## Troubleshooting

### Socket Not Connecting

1. Check that `connect()` was called after authentication
2. Verify auth token is valid and stored in secure storage
3. Check network connectivity
4. Review logs for connection errors

```dart
// Debug logging
final sessionManager = ref.read(socketSessionManagerProvider);
print('Is connected: ${sessionManager.isConnected}');
sessionManager.lifecycleStream.listen((event) {
  print('Lifecycle event: $event');
});
```

### Duplicate Socket Events

If you're receiving duplicate events:

1. Check that you're not joining rooms multiple times without leaving
2. Verify socket handlers are properly disposed
3. Use reference counting (SocketService already does this)

```dart
// Good: Balanced join/leave
_socketService.joinLeague(leagueId);  // ref count: 1
// ...
_socketService.leaveLeague(leagueId); // ref count: 0, room left

// Bad: Unbalanced (leak)
_socketService.joinLeague(leagueId);  // ref count: 1
_socketService.joinLeague(leagueId);  // ref count: 2
_socketService.leaveLeague(leagueId); // ref count: 1, STILL in room!
```

### Context Not Updating

If context isn't updating:

1. Verify you're calling `setLeagueContext` / `setDraftContext`
2. Check that you're listening to `contextStream`
3. Ensure session manager hasn't been disposed

```dart
// Subscribe to context changes
sessionManager.contextStream.listen((context) {
  print('Context changed: $context');
});
```

## Future Enhancements

Potential future improvements:

1. **Automatic context management**: Automatically set context based on current route
2. **Persistent context**: Save context to storage, restore on app restart
3. **Context-aware event filtering**: Filter events based on current context
4. **Multi-league support**: Track multiple active leagues simultaneously
5. **Metrics**: Track connection uptime, reconnection frequency, etc.

## Summary

The `SocketSessionManager`:

- ✅ Provides a clean, high-level API for socket operations
- ✅ Tracks current league/draft/user context
- ✅ Exposes typed lifecycle events via streams
- ✅ Delegates to existing SocketService (no breaking changes)
- ✅ Works alongside existing socket handlers
- ✅ Integrates with Riverpod for dependency injection
- ✅ Supports app lifecycle (background/foreground)

Use it to simplify socket management and improve code consistency across features!
