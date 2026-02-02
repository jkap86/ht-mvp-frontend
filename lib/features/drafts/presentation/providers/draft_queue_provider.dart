import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../data/draft_repository.dart';

/// Queue entry model
class QueueEntry {
  final int id;
  final int draftId;
  final int rosterId;
  final int playerId;
  final int queuePosition;
  final String? playerName;
  final String? playerPosition;
  final String? playerTeam;

  QueueEntry({
    required this.id,
    required this.draftId,
    required this.rosterId,
    required this.playerId,
    required this.queuePosition,
    this.playerName,
    this.playerPosition,
    this.playerTeam,
  });

  factory QueueEntry.fromJson(Map<String, dynamic> json) {
    return QueueEntry(
      id: json['id'] as int? ?? 0,
      draftId: json['draftId'] as int? ?? json['draft_id'] as int? ?? 0,
      rosterId: json['rosterId'] as int? ?? json['roster_id'] as int? ?? 0,
      playerId: json['playerId'] as int? ?? json['player_id'] as int? ?? 0,
      queuePosition: json['queuePosition'] as int? ?? json['queue_position'] as int? ?? 0,
      playerName: json['playerName'] as String? ?? json['player_name'] as String?,
      playerPosition: json['playerPosition'] as String? ?? json['player_position'] as String?,
      playerTeam: json['playerTeam'] as String? ?? json['player_team'] as String?,
    );
  }
}

class DraftQueueState {
  final List<QueueEntry> queue;
  final bool isLoading;
  final String? error;

  DraftQueueState({
    this.queue = const [],
    this.isLoading = true,
    this.error,
  });

  /// Get queued player IDs as a set
  Set<int> get queuedPlayerIds => queue.map((e) => e.playerId).toSet();

  DraftQueueState copyWith({
    List<QueueEntry>? queue,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DraftQueueState(
      queue: queue ?? this.queue,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Composite key for DraftQueueProvider
typedef DraftQueueKey = ({int leagueId, int draftId});

class DraftQueueNotifier extends StateNotifier<DraftQueueState> {
  final DraftRepository _draftRepo;
  final SocketService _socketService;
  final int leagueId;
  final int draftId;

  // Disposer for socket listener
  VoidCallback? _queueUpdateDisposer;

  DraftQueueNotifier(
    this._draftRepo,
    this._socketService,
    this.leagueId,
    this.draftId,
  ) : super(DraftQueueState()) {
    _setupSocketListeners();
    loadQueue();
  }

  void _setupSocketListeners() {
    _queueUpdateDisposer = _socketService.onQueueUpdated((data) {
      if (!mounted) return;
      final playerId = data['playerId'] as int?;
      final action = data['action'] as String?;

      if (playerId != null && action == 'removed') {
        // Remove the player from our local queue
        state = state.copyWith(
          queue: state.queue.where((e) => e.playerId != playerId).toList(),
        );
      }
    });
  }

  Future<void> loadQueue() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final queueData = await _draftRepo.getQueue(leagueId, draftId);
      final queue = queueData.map((e) => QueueEntry.fromJson(e)).toList();

      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(queue: queue, isLoading: false);
    } catch (e) {
      // Check if disposed during async operations
      if (!mounted) return;

      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<bool> addToQueue(int playerId) async {
    try {
      await _draftRepo.addToQueue(leagueId, draftId, playerId);
      // Reload queue to get the full entry with player info
      await loadQueue();
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> removeFromQueue(int playerId) async {
    try {
      await _draftRepo.removeFromQueue(leagueId, draftId, playerId);
      // Optimistically remove from local state
      state = state.copyWith(
        queue: state.queue.where((e) => e.playerId != playerId).toList(),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> reorderQueue(List<int> playerIds) async {
    try {
      final queueData = await _draftRepo.reorderQueue(leagueId, draftId, playerIds);
      final queue = queueData.map((e) => QueueEntry.fromJson(e)).toList();
      state = state.copyWith(queue: queue);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  @override
  void dispose() {
    _queueUpdateDisposer?.call();
    super.dispose();
  }
}

final draftQueueProvider =
    StateNotifierProvider.autoDispose.family<DraftQueueNotifier, DraftQueueState, DraftQueueKey>(
  (ref, key) => DraftQueueNotifier(
    ref.watch(draftRepositoryProvider),
    ref.watch(socketServiceProvider),
    key.leagueId,
    key.draftId,
  ),
);
