import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/error_display.dart';
import '../../../../core/utils/idempotency.dart';
import '../../../leagues/domain/invitation.dart';
import '../providers/league_invitations_provider.dart';

/// Card for inviting members to the league
class InviteMemberCard extends ConsumerStatefulWidget {
  final int leagueId;

  const InviteMemberCard({super.key, required this.leagueId});

  @override
  ConsumerState<InviteMemberCard> createState() => _InviteMemberCardState();
}

class _InviteMemberCardState extends ConsumerState<InviteMemberCard> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  Timer? _debounceTimer;
  bool _showMessageField = false;
  UserSearchResult? _selectedUser;

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
        ref.read(leagueInvitationsProvider(widget.leagueId).notifier).loadPendingInvitations());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _messageController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(leagueInvitationsProvider(widget.leagueId).notifier).searchUsers(query);
    });
  }

  Future<void> _sendInvitation() async {
    if (_selectedUser == null) return;

    final key = newIdempotencyKey();
    final success = await ref
        .read(leagueInvitationsProvider(widget.leagueId).notifier)
        .sendInvitation(
          _selectedUser!.username,
          message: _messageController.text.isNotEmpty ? _messageController.text : null,
          idempotencyKey: key,
        );

    if (!mounted) return;

    if (success) {
      showSuccess(ref, 'Invitation sent to ${_selectedUser!.username}');
      _searchController.clear();
      _messageController.clear();
      setState(() {
        _selectedUser = null;
        _showMessageField = false;
      });
    } else {
      final error = ref.read(leagueInvitationsProvider(widget.leagueId)).error;
      (error ?? 'Failed to send invitation').showAsError(ref);
    }
  }

  Future<void> _cancelInvitation(int invitationId, String username) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Invitation'),
        content: Text('Cancel the invitation to $username?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final key = newIdempotencyKey();
    final success = await ref
        .read(leagueInvitationsProvider(widget.leagueId).notifier)
        .cancelInvitation(invitationId, idempotencyKey: key);

    if (!mounted) return;

    if (success) {
      showSuccess(ref, 'Invitation cancelled');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leagueInvitationsProvider(widget.leagueId));
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_add),
                const SizedBox(width: 8),
                Text(
                  'Invite Members',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const Divider(),

            // Search field
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by username...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: state.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              ref
                                  .read(leagueInvitationsProvider(widget.leagueId).notifier)
                                  .clearSearch();
                              setState(() => _selectedUser = null);
                            },
                          )
                        : null,
                border: const OutlineInputBorder(),
              ),
              onChanged: _onSearchChanged,
            ),

            // Search results
            if (state.searchResults.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: AppSpacing.buttonRadius,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: state.searchResults.length,
                  itemBuilder: (context, index) {
                    final user = state.searchResults[index];
                    final isSelected = _selectedUser?.id == user.id;

                    return ListTile(
                      dense: true,
                      selected: isSelected,
                      selectedTileColor: colorScheme.primaryContainer.withAlpha(77),
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        child: Text(
                          user.username[0].toUpperCase(),
                          style: TextStyle(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      title: Text(user.username),
                      trailing: user.isMember
                          ? Chip(
                              label: const Text('Member'),
                              backgroundColor: colorScheme.primaryContainer,
                              labelStyle: TextStyle(
                                fontSize: 11,
                                color: colorScheme.onPrimaryContainer,
                              ),
                            )
                          : user.hasPendingInvite
                              ? Chip(
                                  label: const Text('Invited'),
                                  backgroundColor: colorScheme.tertiaryContainer,
                                  labelStyle: TextStyle(
                                    fontSize: 11,
                                    color: colorScheme.onTertiaryContainer,
                                  ),
                                )
                              : null,
                      onTap: user.canInvite
                          ? () {
                              setState(() => _selectedUser = user);
                              _searchController.text = user.username;
                              ref
                                  .read(leagueInvitationsProvider(widget.leagueId).notifier)
                                  .clearSearch();
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],

            // Selected user & invite form
            if (_selectedUser != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withAlpha(51),
                  borderRadius: AppSpacing.buttonRadius,
                  border: Border.all(color: colorScheme.primaryContainer),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.person, size: 20, color: colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Invite ${_selectedUser!.username}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _selectedUser = null),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => setState(() => _showMessageField = !_showMessageField),
                      icon: Icon(_showMessageField ? Icons.remove : Icons.add, size: 16),
                      label: Text(_showMessageField ? 'Hide message' : 'Add a message (optional)'),
                    ),
                    if (_showMessageField) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Write a message to include with the invite...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                        maxLength: 200,
                      ),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: state.isSending ? null : _sendInvitation,
                        icon: state.isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.send, size: 18),
                        label: Text(state.isSending ? 'Sending...' : 'Send Invitation'),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Pending invitations section
            if (state.pendingInvitations.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Pending Invitations',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 8),
              ...state.pendingInvitations.map((inv) {
                final id = inv['id'] as int;
                final username = inv['invited_username'] as String? ?? 'Unknown';
                final createdAt = inv['created_at'] as String?;
                final isCancelling = state.cancellingId == id;

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.mail_outline, size: 16),
                  ),
                  title: Text(username),
                  subtitle: createdAt != null
                      ? Text(
                          'Sent ${_formatDate(createdAt)}',
                          style: TextStyle(
                            fontSize: 11,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        )
                      : null,
                  trailing: isCancelling
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: Icon(Icons.cancel_outlined, color: colorScheme.error),
                          onPressed: () => _cancelInvitation(id, username),
                          tooltip: 'Cancel invitation',
                        ),
                );
              }),
            ] else if (state.isLoading) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inDays == 0) {
        return 'today';
      } else if (diff.inDays == 1) {
        return 'yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} days ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (_) {
      return dateStr;
    }
  }
}
