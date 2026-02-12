import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../config/app_theme.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/hype_train_colors.dart';
import '../../../drafts/domain/draft_order_entry.dart';
import '../../../drafts/domain/draft_status.dart';
import '../../domain/league.dart';

/// Helper class for tracking team positions during shuffle animation
class _ShuffleTeam {
  final String name;
  int currentSlot;

  _ShuffleTeam({required this.name, required this.currentSlot});
}

class LeagueDraftsSection extends StatelessWidget {
  final int leagueId;
  final List<Draft> drafts;
  final List<Roster> members;
  final bool isCommissioner;
  final VoidCallback onCreateDraft;
  final Future<void> Function(Draft draft) onStartDraft;
  final Future<List<DraftOrderEntry>?> Function(Draft draft) onRandomizeDraftOrder;
  final Future<List<DraftOrderEntry>?> Function(Draft draft)? onSetOrderFromVetDraft;
  final Future<void> Function(Draft draft) onEditSettings;
  final Future<void> Function(Draft draft, DateTime? scheduledStart)? onEditSchedule;

  const LeagueDraftsSection({
    super.key,
    required this.leagueId,
    required this.drafts,
    required this.members,
    this.isCommissioner = false,
    required this.onCreateDraft,
    required this.onStartDraft,
    required this.onRandomizeDraftOrder,
    this.onSetOrderFromVetDraft,
    required this.onEditSettings,
    this.onEditSchedule,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Drafts',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (isCommissioner)
                  TextButton.icon(
                    onPressed: onCreateDraft,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (drafts.isEmpty)
              _buildEmptyState(context)
            else
              ...drafts.map((draft) => _DraftItem(
                    key: ValueKey(draft.id),
                    leagueId: leagueId,
                    draft: draft,
                    members: members,
                    isCommissioner: isCommissioner,
                    onStartDraft: onStartDraft,
                    onRandomizeDraftOrder: onRandomizeDraftOrder,
                    onSetOrderFromVetDraft: onSetOrderFromVetDraft,
                    onEditSettings: onEditSettings,
                    onEditSchedule: onEditSchedule,
                  )),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.event, size: 48, color: Theme.of(context).colorScheme.outlineVariant),
            const SizedBox(height: 8),
            Text(
              'No drafts yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftItem extends StatefulWidget {
  final int leagueId;
  final Draft draft;
  final List<Roster> members;
  final bool isCommissioner;
  final Future<void> Function(Draft draft) onStartDraft;
  final Future<List<DraftOrderEntry>?> Function(Draft draft) onRandomizeDraftOrder;
  final Future<List<DraftOrderEntry>?> Function(Draft draft)? onSetOrderFromVetDraft;
  final Future<void> Function(Draft draft) onEditSettings;
  final Future<void> Function(Draft draft, DateTime? scheduledStart)? onEditSchedule;

  const _DraftItem({
    super.key,
    required this.leagueId,
    required this.draft,
    required this.members,
    required this.isCommissioner,
    required this.onStartDraft,
    required this.onRandomizeDraftOrder,
    this.onSetOrderFromVetDraft,
    required this.onEditSettings,
    this.onEditSchedule,
  });

  @override
  State<_DraftItem> createState() => _DraftItemState();
}

class _DraftItemState extends State<_DraftItem> with SingleTickerProviderStateMixin {
  List<DraftOrderEntry>? _draftOrder;
  bool _isShuffling = false;
  List<_ShuffleTeam> _shuffleTeams = [];
  Timer? _shuffleTimer;

  @override
  void dispose() {
    _shuffleTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleRandomize() async {
    setState(() {
      _isShuffling = true;
      _draftOrder = null;
    });

    // Start the shuffle animation
    _startShuffleAnimation();

    // Run API call and minimum 5 second timer in parallel
    final results = await Future.wait([
      widget.onRandomizeDraftOrder(widget.draft),
      Future.delayed(const Duration(seconds: 5)),
    ]);

    final order = results[0] as List<DraftOrderEntry>?;

    // Stop the animation
    _shuffleTimer?.cancel();

    if (mounted) {
      setState(() {
        _isShuffling = false;
        _draftOrder = order;
        _shuffleTeams = [];
      });
    }
  }

  Future<void> _handleSetFromVetDraft() async {
    if (widget.onSetOrderFromVetDraft == null) return;

    setState(() {
      _isShuffling = true;
      _draftOrder = null;
    });

    // Start the shuffle animation
    _startShuffleAnimation();

    // Run API call and minimum 5 second timer in parallel
    final results = await Future.wait([
      widget.onSetOrderFromVetDraft!(widget.draft),
      Future.delayed(const Duration(seconds: 5)),
    ]);

    final order = results[0] as List<DraftOrderEntry>?;

    // Stop the animation
    _shuffleTimer?.cancel();

    if (mounted) {
      setState(() {
        _isShuffling = false;
        _draftOrder = order;
        _shuffleTeams = [];
      });
    }
  }

  void _startShuffleAnimation() {
    final random = Random();

    // Initialize teams from members list with actual usernames
    final memberNames = widget.members
        .where((m) => m.userId != null)
        .map((m) => m.teamName ?? m.username)
        .toList();

    // Fallback if no members
    if (memberNames.isEmpty) {
      memberNames.addAll(['Team 1', 'Team 2', 'Team 3', 'Team 4']);
    }

    // Initialize each team with their starting slot
    _shuffleTeams = List.generate(
      memberNames.length,
      (index) => _ShuffleTeam(name: memberNames[index], currentSlot: index),
    );

    _shuffleTimer = Timer.periodic(const Duration(milliseconds: 400), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        // Fisher-Yates shuffle - all teams get new positions simultaneously
        if (_shuffleTeams.length >= 2) {
          final slots = List.generate(_shuffleTeams.length, (i) => i);
          for (int i = slots.length - 1; i > 0; i--) {
            final j = random.nextInt(i + 1);
            final temp = slots[i];
            slots[i] = slots[j];
            slots[j] = temp;
          }
          // Assign new slots to each team
          for (int i = 0; i < _shuffleTeams.length; i++) {
            _shuffleTeams[i].currentSlot = slots[i];
          }
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Slow auctions don't use draft order - nominations are open to all teams
    final isSlowAuction = widget.draft.isAuction &&
        widget.draft.settings?.isFastAuction != true;

    final canRandomize = widget.isCommissioner &&
        widget.draft.status == DraftStatus.notStarted &&
        !widget.draft.orderConfirmed &&
        !isSlowAuction;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: AppSpacing.buttonRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.draft.displayName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.draft.draftType.label} • ${widget.draft.rounds} rounds',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (widget.draft.scheduledStart != null ||
                        (widget.isCommissioner && widget.draft.status == DraftStatus.notStarted)) ...[
                      const SizedBox(height: 4),
                      _buildScheduledTimeRow(context),
                    ],
                  ],
                ),
              ),
              // Edit settings button for commissioners (not shown for completed drafts)
              if (widget.isCommissioner && widget.draft.status != DraftStatus.completed)
                IconButton(
                  icon: const Icon(Icons.settings, size: 20),
                  tooltip: 'Edit Settings',
                  onPressed: () => widget.onEditSettings(widget.draft),
                ),
              _buildStatusBadge(context),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/leagues/${widget.leagueId}/drafts/${widget.draft.id}'),
                  child: const Text('View Draft Room'),
                ),
              ),
              if (widget.draft.status == DraftStatus.notStarted && widget.isCommissioner) ...[
                const SizedBox(width: 8),
                _buildStartButton(context),
              ],
            ],
          ),
          if (canRandomize) ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _isShuffling ? null : () => _showRandomizeConfirmation(context),
                icon: _isShuffling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.shuffle, size: 18),
                label: Text(_isShuffling ? 'Shuffling...' : 'Randomize Order'),
              ),
            ),
            // "Use Vet Draft Results" button for rookie drafts
            if (widget.draft.isRookieDraft && widget.onSetOrderFromVetDraft != null) ...[
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _isShuffling ? null : () => _showVetDraftOrderConfirmation(context),
                  icon: const Icon(Icons.format_list_numbered, size: 18),
                  label: const Text('Use Vet Draft Results'),
                ),
              ),
            ],
          ],
          // Shuffle animation display
          if (_isShuffling && _shuffleTeams.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildShuffleAnimation(),
          ],
          // Show draft order after randomization
          if (_draftOrder != null && _draftOrder!.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildDraftOrderDisplay(),
          ],
          // Show order confirmed message if already randomized
          if (widget.draft.orderConfirmed && _draftOrder == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.check_circle, size: 16, color: context.htColors.draftAction),
                const SizedBox(width: 4),
                Text(
                  'Draft order confirmed',
                  style: TextStyle(
                    fontSize: 12,
                    color: context.htColors.draftAction,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildShuffleAnimation() {
    const double rowHeight = 32.0;
    const double slotLabelWidth = 36.0;
    final teamCount = _shuffleTeams.length;
    final containerHeight = rowHeight * teamCount;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: AppSpacing.buttonRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shuffle,
                size: 14,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 4),
              Text(
                'Shuffling teams...',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: containerHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Slot position labels column
                SizedBox(
                  width: slotLabelWidth,
                  child: Column(
                    children: List.generate(teamCount, (index) {
                      return SizedBox(
                        height: rowHeight,
                        child: Center(
                          child: Text(
                            _getOrdinal(index + 1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                // Animated team chips
                Expanded(
                  child: Stack(
                    children: _shuffleTeams.map((team) {
                      return AnimatedPositioned(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        top: team.currentSlot * rowHeight,
                        left: 0,
                        right: 0,
                        height: rowHeight,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              team.name,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getOrdinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }

  Widget _buildDraftOrderDisplay() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: context.htColors.draftAction.withValues(alpha: 0.1),
        borderRadius: AppSpacing.buttonRadius,
        border: Border.all(color: context.htColors.draftAction.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, size: 16, color: context.htColors.draftAction),
              const SizedBox(width: 6),
              Text(
                'Draft Order Set!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: context.htColors.draftAction,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...(_draftOrder!.map((entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: AppSpacing.cardRadius,
                      ),
                      child: Text(
                        '${entry.draftPosition}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.username,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ))),
        ],
      ),
    );
  }

  String _formatScheduledTime(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final amPm = dt.hour < 12 ? 'AM' : 'PM';
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} $hour:$minute $amPm';
  }

  Widget _buildScheduledTimeRow(BuildContext context) {
    final theme = Theme.of(context);
    final scheduled = widget.draft.scheduledStart;
    final canEdit = widget.isCommissioner &&
        widget.draft.status == DraftStatus.notStarted &&
        widget.onEditSchedule != null;

    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: scheduled != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            scheduled != null
                ? 'Starts: ${_formatScheduledTime(scheduled.toLocal())}'
                : 'Not scheduled',
            style: TextStyle(
              fontSize: 12,
              color: scheduled != null
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        if (canEdit)
          GestureDetector(
            onTap: () => _showScheduleDialog(context),
            child: Icon(
              Icons.edit,
              size: 14,
              color: theme.colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Future<void> _showScheduleDialog(BuildContext context) async {
    final now = DateTime.now();
    final initialDate = widget.draft.scheduledStart ?? now.add(const Duration(days: 1));

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(widget.draft.scheduledStart ?? initialDate),
      );

      if (time != null && context.mounted) {
        final scheduledStart = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
        await widget.onEditSchedule?.call(widget.draft, scheduledStart);
      }
    }
  }

  Widget _buildStatusBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor;
    Color textColor;
    String label;

    switch (widget.draft.status) {
      case DraftStatus.notStarted:
        backgroundColor = colorScheme.surfaceContainerHighest;
        textColor = colorScheme.onSurfaceVariant;
        label = 'Not Started';
        break;
      case DraftStatus.inProgress:
        backgroundColor = context.htColors.draftAction;
        textColor = colorScheme.onPrimary;
        label = 'Live';
        break;
      case DraftStatus.completed:
        backgroundColor = colorScheme.primaryContainer;
        textColor = colorScheme.onPrimaryContainer;
        label = 'Completed';
        break;
      case DraftStatus.paused:
        backgroundColor = AppTheme.draftWarning;
        textColor = colorScheme.onPrimary;
        label = 'Paused';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: AppSpacing.cardRadius,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context) {
    // Auctions don't require order confirmation (initial order is created automatically)
    final canStart = widget.draft.orderConfirmed || widget.draft.isAuction;
    return Tooltip(
      message: canStart ? '' : 'Randomize draft order first',
      child: ElevatedButton(
        onPressed: canStart ? () => widget.onStartDraft(widget.draft) : null,
        child: const Text('Start'),
      ),
    );
  }

  void _showRandomizeConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Randomize Draft Order?'),
        content: const Text(
          'This will randomly shuffle the draft order for all teams. '
          'This action can only be done before the draft starts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _handleRandomize();
            },
            icon: const Icon(Icons.shuffle),
            label: const Text('Randomize'),
          ),
        ],
      ),
    );
  }

  void _showVetDraftOrderConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Use Vet Draft Results?'),
        content: const Text(
          'Set draft order based on Round 1 pick ownership from the vet draft? '
          'Teams will draft in the order they acquired their Round 1 picks.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              _handleSetFromVetDraft();
            },
            icon: const Icon(Icons.format_list_numbered),
            label: const Text('Set Order'),
          ),
        ],
      ),
    );
  }
}
