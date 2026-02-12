import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/chat_provider.dart';

/// Search bar for league chat with match navigation
class ChatSearchBar extends ConsumerStatefulWidget {
  final int leagueId;

  const ChatSearchBar({
    super.key,
    required this.leagueId,
  });

  @override
  ConsumerState<ChatSearchBar> createState() => _ChatSearchBarState();
}

class _ChatSearchBarState extends ConsumerState<ChatSearchBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounceTimer?.cancel();

    if (query.trim().isEmpty) {
      ref.read(chatProvider(widget.leagueId).notifier).clearSearch();
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      ref.read(chatProvider(widget.leagueId).notifier).searchMessages(query);
    });
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(chatProvider(widget.leagueId).notifier).clearSearch();
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider(widget.leagueId));
    final hasResults = chatState.searchResults.isNotEmpty;
    final currentIndex = chatState.currentSearchIndex;
    final total = chatState.searchTotal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search messages...',
                prefixIcon: chatState.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12.0),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          if (hasResults) ...[
            const SizedBox(width: 8),
            Text(
              '${currentIndex + 1}/$total',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_up),
              onPressed: () {
                ref.read(chatProvider(widget.leagueId).notifier).previousSearchResult();
              },
              tooltip: 'Previous match',
            ),
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () {
                ref.read(chatProvider(widget.leagueId).notifier).nextSearchResult();
              },
              tooltip: 'Next match',
            ),
          ],
        ],
      ),
    );
  }
}
