import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../../core/utils/app_layout.dart';
import '../../../../core/utils/navigation_utils.dart';
import '../../../../core/widgets/live_badge.dart';
import '../../../../core/widgets/states/states.dart';
import '../../domain/matchup.dart';
import '../providers/matchup_detail_provider.dart';
import '../widgets/lineup_comparison_widget.dart';

class MatchupDetailScreen extends ConsumerStatefulWidget {
  final int leagueId;
  final int matchupId;

  const MatchupDetailScreen({
    super.key,
    required this.leagueId,
    required this.matchupId,
  });

  @override
  ConsumerState<MatchupDetailScreen> createState() => _MatchupDetailScreenState();
}

class _MatchupDetailScreenState extends ConsumerState<MatchupDetailScreen>
    with WidgetsBindingObserver {
  DateTime? _lastFetchedAt;
  Timer? _displayTimer;
  Timer? _fallbackRefreshTimer;
  bool _isFallbackActive = false;
  bool _isScreenVisible = true;

  /// Safety net: if socket events stop arriving, fetch data every 3 minutes.
  /// Socket-driven refresh via the notifier is the primary mechanism.
  static const _fallbackRefreshInterval = Duration(minutes: 3);

  /// Duration between UI ticks to update the "last updated" text.
  static const _displayTickInterval = Duration(seconds: 30);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _lastFetchedAt = DateTime.now();
    // Tick every 30s to update the "last updated" text
    _displayTimer = Timer.periodic(_displayTickInterval, (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _displayTimer?.cancel();
    _stopFallbackRefresh();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _isScreenVisible = true;
      // Re-evaluate fallback refresh when returning to foreground
      if (_isFallbackActive) {
        _startFallbackRefresh();
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _isScreenVisible = false;
      // Pause fallback refresh when screen is not visible
      _fallbackRefreshTimer?.cancel();
      _fallbackRefreshTimer = null;
    }
  }

  /// Start the fallback safety-net timer for live data.
  /// Only fires if socket events have stopped arriving.
  void _startFallbackRefresh() {
    _fallbackRefreshTimer?.cancel();
    if (!_isScreenVisible || !mounted) return;
    _isFallbackActive = true;
    _fallbackRefreshTimer = Timer.periodic(_fallbackRefreshInterval, (_) {
      if (mounted && _isScreenVisible) {
        _performFallbackRefresh();
      }
    });
    if (mounted) setState(() {});
  }

  /// Stop the fallback safety-net timer.
  void _stopFallbackRefresh() {
    _fallbackRefreshTimer?.cancel();
    _fallbackRefreshTimer = null;
    _isFallbackActive = false;
  }

  /// Fallback refresh: fetch data as a safety net when socket may be silent.
  Future<void> _performFallbackRefresh() async {
    final key = (leagueId: widget.leagueId, matchupId: widget.matchupId);
    final notifier = ref.read(matchupDetailProvider(key).notifier);
    await notifier.loadData();
  }

  /// Evaluate whether the fallback timer should be active based on matchup state.
  void _evaluateAutoRefresh(MatchupDetails details) {
    final shouldBeActive = details.matchup.hasLiveData;
    if (shouldBeActive && !_isFallbackActive) {
      _startFallbackRefresh();
    } else if (!shouldBeActive && _isFallbackActive) {
      _stopFallbackRefresh();
      if (mounted) setState(() {});
    }
  }

  /// Reset the fallback timer (e.g., after a manual refresh).
  void _resetFallbackTimer() {
    if (_isFallbackActive) {
      _startFallbackRefresh();
    }
  }

  String _formatLastUpdated() {
    if (_lastFetchedAt == null) return '';
    final diff = DateTime.now().difference(_lastFetchedAt!);
    if (diff.inSeconds < 60) return 'Updated just now';
    if (diff.inMinutes < 60) return 'Updated ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Updated ${diff.inHours}h ago';
    return 'Updated ${diff.inDays}d ago';
  }

  /// Whether data is stale (older than 5 minutes)
  bool get _isStale {
    if (_lastFetchedAt == null) return true;
    return DateTime.now().difference(_lastFetchedAt!) > const Duration(minutes: 5);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      matchupDetailProvider((leagueId: widget.leagueId, matchupId: widget.matchupId)),
    );

    // Update local timestamp when provider state updates
    if (state.lastUpdated != null && state.lastUpdated != _lastFetchedAt) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _lastFetchedAt = state.lastUpdated);
          if (state.details != null) {
            _evaluateAutoRefresh(state.details!);
          }
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navigateBack(context, fallback: '/leagues/${widget.leagueId}/matchups'),
        ),
        title: const Text('Matchup Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              ref.read(matchupDetailProvider(
                (leagueId: widget.leagueId, matchupId: widget.matchupId),
              ).notifier).loadData();
              _resetFallbackTimer();
            },
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, MatchupDetailState state) {
    if (state.isLoading && state.details == null) {
      return const AppLoadingView();
    }

    if (state.error != null && state.details == null) {
      return AppErrorView(
        message: state.error!,
        onRetry: () {
          ref.read(matchupDetailProvider(
            (leagueId: widget.leagueId, matchupId: widget.matchupId),
          ).notifier).loadData();
        },
      );
    }

    if (state.details == null) {
      return const AppLoadingView();
    }

    return _buildContent(context, state.details!);
  }

  Widget _buildContent(BuildContext context, MatchupDetails details) {
    final matchup = details.matchup;
    final team1 = details.team1;
    final team2 = details.team2;
    final colorScheme = Theme.of(context).colorScheme;

    // Use live actual points if available, otherwise use team total points
    final team1ActualPoints = matchup.isFinal
        ? team1.totalPoints
        : (matchup.roster1PointsActual ?? team1.totalPoints);
    final team2ActualPoints = matchup.isFinal
        ? team2.totalPoints
        : (matchup.roster2PointsActual ?? team2.totalPoints);

    final isTeam1Winner = team1ActualPoints > team2ActualPoints;
    final isTeam2Winner = team2ActualPoints > team1ActualPoints;
    final isTie = team1ActualPoints == team2ActualPoints && matchup.isFinal;

    return RefreshIndicator(
      onRefresh: () async {
        final key = (leagueId: widget.leagueId, matchupId: widget.matchupId);
        await ref.read(matchupDetailProvider(key).notifier).loadData();
        if (mounted) {
          _resetFallbackTimer();
        }
      },
      child: Center(
        child: ConstrainedBox(
          constraints: AppLayout.contentConstraints(context),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                // Score header
                _ScoreHeader(
                  team1Name: team1.teamName,
                  team2Name: team2.teamName,
                  team1Points: team1ActualPoints,
                  team2Points: team2ActualPoints,
                  team1ProjectedPoints: matchup.roster1PointsProjected,
                  team2ProjectedPoints: matchup.roster2PointsProjected,
                  isTeam1Winner: isTeam1Winner,
                  isTeam2Winner: isTeam2Winner,
                  isFinal: matchup.isFinal,
                  isLive: matchup.hasLiveData,
                  isPlayoff: matchup.isPlayoff,
                  week: matchup.week,
                ),

                if (isTie)
                  Container(
                    padding: const EdgeInsets.all(8),
                    color: colorScheme.tertiary.withAlpha(30),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.balance, size: 16, color: colorScheme.tertiary),
                        const SizedBox(width: 4),
                        Text(
                          'TIE',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),

                // Last updated indicator with auto-refresh status
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isStale)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.warning_amber_rounded,
                            size: 13,
                            color: colorScheme.error,
                          ),
                        ),
                      Text(
                        _formatLastUpdated(),
                        style: TextStyle(
                          fontSize: 11,
                          color: _isStale
                              ? colorScheme.error
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (_isFallbackActive) ...[
                        const SizedBox(width: 6),
                        _AutoRefreshIndicator(color: colorScheme.primary),
                      ],
                    ],
                  ),
                ),

                // Lineup comparison
                LineupComparisonWidget(
                  team1: team1,
                  team2: team2,
                  isTeam1Winner: isTeam1Winner,
                  isTeam2Winner: isTeam2Winner,
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final String team1Name;
  final String team2Name;
  final double team1Points;
  final double team2Points;
  final double? team1ProjectedPoints;
  final double? team2ProjectedPoints;
  final bool isTeam1Winner;
  final bool isTeam2Winner;
  final bool isFinal;
  final bool isLive;
  final bool isPlayoff;
  final int week;

  const _ScoreHeader({
    required this.team1Name,
    required this.team2Name,
    required this.team1Points,
    required this.team2Points,
    this.team1ProjectedPoints,
    this.team2ProjectedPoints,
    required this.isTeam1Winner,
    required this.isTeam2Winner,
    required this.isFinal,
    this.isLive = false,
    this.isPlayoff = false,
    required this.week,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isPlayoff
              ? [
                  colorScheme.tertiary.withValues(alpha: 0.12),
                  colorScheme.tertiary.withValues(alpha: 0.04),
                ]
              : [
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          // Week indicator with status
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isPlayoff
                      ? colorScheme.tertiary.withValues(alpha: 0.2)
                      : Theme.of(context).primaryColor.withValues(alpha: 0.2),
                  borderRadius: AppSpacing.cardRadius,
                ),
                child: Text(
                  isPlayoff ? 'Playoff - Week $week' : 'Week $week',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isPlayoff
                        ? colorScheme.tertiary
                        : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              if (isLive && !isFinal) ...[
                const SizedBox(width: 8),
                const LiveBadge(),
              ],
            ],
          ),
          const SizedBox(height: 16),

          // Score display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Team 1
              Expanded(
                child: Column(
                  children: [
                    Text(
                      team1Name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isTeam1Winner && isFinal
                            ? context.htColors.draftAction
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team1Points.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isTeam1Winner && isFinal
                            ? context.htColors.draftAction
                            : null,
                      ),
                    ),
                    // Projected points (for live games)
                    if (!isFinal && team1ProjectedPoints != null)
                      Text(
                        'Proj: ${team1ProjectedPoints!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (isTeam1Winner && isFinal)
                      Icon(Icons.emoji_events, color: colorScheme.tertiary, size: 20),
                  ],
                ),
              ),

              // VS divider
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    Text(
                      'VS',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (isFinal)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.htColors.draftAction.withAlpha(30),
                          borderRadius: AppSpacing.badgeRadius,
                        ),
                        child: Text(
                          'FINAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.htColors.draftAction,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Team 2
              Expanded(
                child: Column(
                  children: [
                    Text(
                      team2Name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isTeam2Winner && isFinal
                            ? context.htColors.draftAction
                            : null,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      team2Points.toStringAsFixed(2),
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: isTeam2Winner && isFinal
                            ? context.htColors.draftAction
                            : null,
                      ),
                    ),
                    // Projected points (for live games)
                    if (!isFinal && team2ProjectedPoints != null)
                      Text(
                        'Proj: ${team2ProjectedPoints!.toStringAsFixed(1)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    if (isTeam2Winner && isFinal)
                      Icon(Icons.emoji_events, color: colorScheme.tertiary, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// A small pulsing dot with "Auto-refreshing" text to indicate live data polling.
class _AutoRefreshIndicator extends StatefulWidget {
  final Color color;

  const _AutoRefreshIndicator({required this.color});

  @override
  State<_AutoRefreshIndicator> createState() => _AutoRefreshIndicatorState();
}

class _AutoRefreshIndicatorState extends State<_AutoRefreshIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Auto-refreshing',
            style: TextStyle(
              fontSize: 11,
              color: widget.color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
