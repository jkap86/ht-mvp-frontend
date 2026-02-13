import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';

/// Filter panel for league chat - allows hiding specific users or system messages
class ChatFilterPanel extends ConsumerWidget {
  final int leagueId;

  const ChatFilterPanel({
    super.key,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(leagueId));
    final theme = Theme.of(context);

    // Get unique users from messages
    final usersMap = <String, String>{}; // userId -> username
    for (final message in chatState.messages) {
      if (message.userId != null && message.username != null) {
        usersMap[message.userId!] = message.username!;
      }
    }

    final users = usersMap.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    // Count active filters
    final activeFiltersCount = chatState.hiddenUserIds.length +
        (chatState.hideSystemMessages ? 1 : 0);

    // Count filtered vs total messages
    final totalMessages = chatState.messages.length;
    final visibleMessages = chatState.filteredMessages.length;

    return Container(
      constraints: const BoxConstraints(maxHeight: 500),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filter Messages',
                      style: theme.textTheme.titleLarge,
                    ),
                    if (activeFiltersCount > 0)
                      Text(
                        'Showing $visibleMessages of $totalMessages messages',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                  ],
                ),
                if (activeFiltersCount > 0)
                  TextButton(
                    onPressed: () {
                      ref.read(chatProvider(leagueId).notifier).clearAllFilters();
                    },
                    child: const Text('Clear All'),
                  ),
              ],
            ),
          ),
          const Divider(),

          // System messages toggle
          SwitchListTile(
            title: const Text('Hide System Messages'),
            subtitle: const Text('Trade notifications, draft picks, etc.'),
            value: chatState.hideSystemMessages,
            onChanged: (_) {
              ref.read(chatProvider(leagueId).notifier).toggleSystemMessages();
            },
          ),
          const Divider(),

          // User filters
          if (users.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No users to filter'),
            )
          else ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                'Hide Users',
                style: theme.textTheme.titleMedium,
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final entry = users[index];
                  final userId = entry.key;
                  final username = entry.value;
                  final isHidden = chatState.hiddenUserIds.contains(userId);

                  return CheckboxListTile(
                    title: Text(username),
                    value: !isHidden, // Inverted: checked means visible
                    onChanged: (_) {
                      ref
                          .read(chatProvider(leagueId).notifier)
                          .toggleUserFilter(userId);
                    },
                    secondary: CircleAvatar(
                      child: Text(
                        username.substring(0, 1).toUpperCase(),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Button that opens the filter panel as a bottom sheet (mobile) or dialog (desktop)
class ChatFilterButton extends ConsumerWidget {
  final int leagueId;

  const ChatFilterButton({
    super.key,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatProvider(leagueId));
    final activeFiltersCount = chatState.hiddenUserIds.length +
        (chatState.hideSystemMessages ? 1 : 0);

    return Stack(
      children: [
        Builder(
          builder: (BuildContext innerContext) => IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // Use bottom sheet on mobile, dialog on desktop
              if (MediaQuery.of(innerContext).size.width < 600) {
                showModalBottomSheet(
                  context: innerContext,
                  builder: (context) => ChatFilterPanel(leagueId: leagueId),
                  isScrollControlled: true,
                );
              } else {
                showDialog(
                  context: innerContext,
                  builder: (context) => Dialog(
                    child: ChatFilterPanel(leagueId: leagueId),
                  ),
                );
              }
            },
            tooltip: 'Filter messages',
          ),
        ),
        if (activeFiltersCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  '$activeFiltersCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
