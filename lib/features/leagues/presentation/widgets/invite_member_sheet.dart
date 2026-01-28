import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/invitation.dart';
import '../../../commissioner/presentation/providers/league_invitations_provider.dart';

/// Shows a bottom sheet for inviting members to a league
/// Available to all league members (not just commissioner)
void showInviteMemberSheet(BuildContext context, int leagueId) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => InviteMemberSheet(leagueId: leagueId),
  );
}

class InviteMemberSheet extends ConsumerStatefulWidget {
  final int leagueId;

  const InviteMemberSheet({super.key, required this.leagueId});

  @override
  ConsumerState<InviteMemberSheet> createState() => _InviteMemberSheetState();
}

class _InviteMemberSheetState extends ConsumerState<InviteMemberSheet> {
  final _searchController = TextEditingController();
  final _messageController = TextEditingController();
  Timer? _debounceTimer;
  bool _showMessageField = false;
  UserSearchResult? _selectedUser;

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

    final success = await ref
        .read(leagueInvitationsProvider(widget.leagueId).notifier)
        .sendInvitation(
          _selectedUser!.username,
          message: _messageController.text.isNotEmpty ? _messageController.text : null,
        );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitation sent to ${_selectedUser!.username}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    } else {
      final error = ref.read(leagueInvitationsProvider(widget.leagueId)).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Failed to send invitation'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leagueInvitationsProvider(widget.leagueId));
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.person_add_alt),
                const SizedBox(width: 8),
                Text(
                  'Invite a Member',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search field
            TextField(
              controller: _searchController,
              autofocus: true,
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
                  borderRadius: BorderRadius.circular(8),
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
                  borderRadius: BorderRadius.circular(8),
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

            // Help text when no selection
            if (_selectedUser == null && state.searchResults.isEmpty && _searchController.text.isEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Search for a username to send them an invitation to join your league.',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ],

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
