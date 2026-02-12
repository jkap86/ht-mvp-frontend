import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/socket/socket_service.dart';
import '../../../../core/utils/error_sanitizer.dart';
import '../../data/league_repository.dart';
import '../../domain/dashboard.dart';

/// State for the league dashboard
class LeagueDashboardState {
  final DashboardSummary? dashboard;
  final bool isLoading;
  final String? error;

  LeagueDashboardState({
    this.dashboard,
    this.isLoading = true,
    this.error,
  });

  LeagueDashboardState copyWith({
    DashboardSummary? dashboard,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LeagueDashboardState(
      dashboard: dashboard ?? this.dashboard,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Convenience getters
  DraftInfo? get draft => dashboard?.draft;
  AuctionInfo? get auction => dashboard?.auction;
  WaiverInfo? get waivers => dashboard?.waivers;
  MatchupInfo? get matchup => dashboard?.matchup;
  int get pendingTrades => dashboard?.pendingTrades ?? 0;
  int get activeWaiverClaims => dashboard?.activeWaiverClaims ?? 0;
  int get unreadChatMessages => dashboard?.unreadChatMessages ?? 0;
  List<Announcement> get announcements => dashboard?.announcements ?? [];

  /// Determine what to show in "Next Up" section
  NextUpType get nextUpType {
    final d = draft;
    if (d != null && d.isLive) return NextUpType.draftLive;
    if (d != null && d.isPaused) return NextUpType.draftPaused;
    if (d != null && d.isScheduled) return NextUpType.draftScheduled;
    final a = auction;
    if (a != null && a.hasActiveAuction) return NextUpType.auctionActive;
    final w = waivers;
    if (w != null && w.nextProcessingTime != null) return NextUpType.waiversSoon;
    final m = matchup;
    if (m != null) return NextUpType.inSeason;
    return NextUpType.none;
  }
}

enum NextUpType {
  draftLive,
  draftScheduled,
  draftPaused,
  auctionActive,
  waiversSoon,
  inSeason,
  none,
}

/// Notifier for managing dashboard state
class LeagueDashboardNotifier extends StateNotifier<LeagueDashboardState> {
  final LeagueRepository _leagueRepo;
  final SocketService _socketService;
  final int leagueId;

  VoidCallback? _draftStartedDisposer;
  VoidCallback? _draftCompletedDisposer;
  VoidCallback? _tradeProposedDisposer;
  VoidCallback? _tradeCompletedDisposer;
  VoidCallback? _waiverProcessedDisposer;
  VoidCallback? _auctionLotUpdatedDisposer;
  VoidCallback? _reconnectDisposer;

  LeagueDashboardNotifier(
    this._leagueRepo,
    this._socketService,
    this.leagueId,
  ) : super(LeagueDashboardState()) {
    _setupSocketListeners();
    loadDashboard();
  }

  void _setupSocketListeners() {
    _socketService.joinLeague(leagueId);

    // Listen for draft events
    _draftStartedDisposer = _socketService.onDraftStarted((data) {
      if (!mounted) return;
      loadDashboard();
    });

    _draftCompletedDisposer = _socketService.onDraftCompleted((data) {
      if (!mounted) return;
      loadDashboard();
    });

    // Listen for trade events
    _tradeProposedDisposer = _socketService.onTradeProposed((data) {
      if (!mounted) return;
      // Increment pending trades count
      final current = state.dashboard;
      if (current != null) {
        state = state.copyWith(
          dashboard: DashboardSummary(
            draft: current.draft,
            auction: current.auction,
            waivers: current.waivers,
            matchup: current.matchup,
            pendingTrades: current.pendingTrades + 1,
            activeWaiverClaims: current.activeWaiverClaims,
            unreadChatMessages: current.unreadChatMessages,
            announcements: current.announcements,
          ),
        );
      }
    });

    _tradeCompletedDisposer = _socketService.onTradeCompleted((data) {
      if (!mounted) return;
      loadDashboard(); // Refresh for accurate counts
    });

    // Listen for waiver events
    _waiverProcessedDisposer = _socketService.onWaiverProcessed((data) {
      if (!mounted) return;
      loadDashboard();
    });

    // Listen for auction events
    _auctionLotUpdatedDisposer = _socketService.onAuctionLotUpdated((data) {
      if (!mounted) return;
      loadDashboard();
    });

    // Resync dashboard on socket reconnection
    _reconnectDisposer = _socketService.onReconnected((needsFullRefresh) {
      if (!mounted) return;
      if (kDebugMode) {
        debugPrint('Dashboard($leagueId): Socket reconnected, needsFullRefresh=$needsFullRefresh');
      }
      // Always reload dashboard on reconnect -- counts and statuses may have changed
      loadDashboard();
    });
  }

  @override
  void dispose() {
    _draftStartedDisposer?.call();
    _draftCompletedDisposer?.call();
    _tradeProposedDisposer?.call();
    _tradeCompletedDisposer?.call();
    _waiverProcessedDisposer?.call();
    _auctionLotUpdatedDisposer?.call();
    _reconnectDisposer?.call();
    _socketService.leaveLeague(leagueId);
    super.dispose();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final dashboard = await _leagueRepo.getDashboard(leagueId);
      state = state.copyWith(
        dashboard: dashboard,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: ErrorSanitizer.sanitize(e),
        isLoading: false,
      );
    }
  }

  void refresh() {
    loadDashboard();
  }
}

/// Provider for league dashboard
final leagueDashboardProvider = StateNotifierProvider.autoDispose
    .family<LeagueDashboardNotifier, LeagueDashboardState, int>(
  (ref, leagueId) => LeagueDashboardNotifier(
    ref.watch(leagueRepositoryProvider),
    ref.watch(socketServiceProvider),
    leagueId,
  ),
);
