# Frontend Architecture Rules

## Layer Definitions

### presentation/
Widgets, screens, providers (StateNotifier), and UI-only logic.

**Allowed imports:** domain/, data/, core/
**Forbidden:** Instantiating repositories or ApiClient directly in widgets.

### domain/
Pure Dart classes and functions. Business rules, validation, calculations.

**Allowed imports:** Only other domain/ files and dart:core/dart:math.
**Forbidden:** Any import from data/, presentation/, core/, or Flutter SDK.

### data/
Repositories, API clients, DTOs, JSON parsing.

**Allowed imports:** domain/, core/
**Forbidden:** Flutter widgets, presentation/ imports, socket event handlers.

### core/
Shared infrastructure: API client, socket service, theme, common widgets.

**Allowed imports:** Only other core/ files.
**Forbidden:** Feature-specific imports from features/.

---

## Key Rules

### 1. Widgets never call APIs directly
```dart
// BAD - raw API call in widget
final response = await apiClient.get('/auth/users/search?q=$query');

// GOOD - use a repository via provider
final results = await ref.read(userSearchRepositoryProvider).searchUsers(query);
```

### 2. Widgets never instantiate repositories
```dart
// BAD - bypasses DI, loses auth token and interceptors
final repo = DraftRepository(ApiClient());

// GOOD - use the provider
final repo = ref.read(draftRepositoryProvider);
```

### 3. Mutations go through notifiers, not directly to repositories
```dart
// BAD - widget calls repository directly
await ref.read(tradeRepositoryProvider).proposeTrade(...);

// GOOD - widget calls notifier method
await ref.read(tradesProvider(leagueId).notifier).proposeTrade(...);
```

### 4. Business logic belongs in domain/, not widgets
```dart
// BAD - bid math duplicated across 3 widgets
int get _maxPossibleBid {
  final remaining = totalSpots - budget.wonCount;
  // ...same calculation in 3 places
}

// GOOD - single source of truth in domain
final max = calculator.maxPossibleBid(lot, budget, myRosterId);
```

### 5. Use newIdempotencyKey() not Uuid().v4()
```dart
// BAD - inconsistent, unclear intent
final key = const Uuid().v4();

// GOOD - semantic, centralized
final key = newIdempotencyKey();
```

### 6. Socket handlers belong in presentation/providers/, not data/
```dart
// BAD - socket event handling in data layer
class InvitationsNotifier {
  void _setupSocket() { socketService.on('invite', ...); }
}

// GOOD - dedicated socket handler in presentation/providers/
class InvitationsSocketHandler {
  final List<VoidCallback> _disposers = [];
  void setupListeners() { ... }
  void dispose() { ... }
}
```

### 7. Widgets use providers for socket actions, not SocketService directly
```dart
// BAD - widget reaches into socket service
ref.read(socketServiceProvider).reconnect();

// GOOD - thin provider wraps the action
ref.read(socketReconnectProvider)();
```

---

## PR Review Checklist

- [ ] No widget instantiates a repository or ApiClient manually
- [ ] No widget calls `apiClient.get/post/put/patch/delete` directly
- [ ] All mutations route through a StateNotifier, not directly to a repository
- [ ] Business logic (validation, calculations, policy) lives in `domain/`
- [ ] `domain/` files have zero imports from `data/`, `presentation/`, `core/`, or Flutter
- [ ] Idempotency keys use `newIdempotencyKey()`, not `Uuid().v4()`
- [ ] Socket event handlers use the disposer pattern in `presentation/providers/`
- [ ] No `Future.delayed` in tests for synchronization (use callback capture or Completer)
- [ ] No circular dependencies between layers
