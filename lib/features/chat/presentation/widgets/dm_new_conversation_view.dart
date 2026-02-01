import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../dm/data/dm_repository.dart';
import '../../../dm/presentation/providers/dm_inbox_provider.dart';

/// Inline user search view for starting a new DM conversation.
/// Designed to fit inside the floating chat widget.
class DmNewConversationView extends ConsumerStatefulWidget {
  final VoidCallback onBack;
  final void Function(int conversationId, String username) onConversationCreated;

  const DmNewConversationView({
    super.key,
    required this.onBack,
    required this.onConversationCreated,
  });

  @override
  ConsumerState<DmNewConversationView> createState() => _DmNewConversationViewState();
}

class _DmNewConversationViewState extends ConsumerState<DmNewConversationView> {
  final TextEditingController _searchController = TextEditingController();
  List<_UserSearchResult> _results = [];
  bool _isSearching = false;
  bool _isCreatingConversation = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {}); // Trigger rebuild for suffixIcon visibility
  }

  @override
  void dispose() {
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    debugPrint('_search called: "$query"');

    if (query.trim().length < 2) {
      debugPrint('Query too short, returning');
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    debugPrint('Setting isSearching=true');
    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      debugPrint('Getting apiClient...');
      final apiClient = ref.read(apiClientProvider);
      debugPrint('Calling API: /auth/users/search?q=${Uri.encodeComponent(query)}');
      final response = await apiClient.get('/auth/users/search?q=${Uri.encodeComponent(query)}');
      debugPrint('Got response: $response');
      final users = (response as List)
          .map((json) => _UserSearchResult.fromJson(json as Map<String, dynamic>))
          .toList();
      debugPrint('Parsed ${users.length} users');

      if (mounted) {
        setState(() {
          _results = users;
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('Search error: $e');
      if (mounted) {
        setState(() {
          _error = 'Error searching users';
          _isSearching = false;
        });
      }
    }
  }

  Future<void> _startConversation(_UserSearchResult user) async {
    setState(() => _isCreatingConversation = true);

    try {
      final dmRepo = ref.read(dmRepositoryProvider);
      final conversation = await dmRepo.getOrCreateConversation(user.id);

      if (mounted) {
        // Add conversation to inbox so it appears when user navigates back
        ref.read(dmInboxProvider.notifier).addConversationToTop(conversation);

        // Trigger callback to navigate to conversation
        widget.onConversationCreated(conversation.id, conversation.otherUsername);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error starting conversation';
          _isCreatingConversation = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        // Header with back button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: colorScheme.outlineVariant),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                onPressed: widget.onBack,
                padding: const EdgeInsets.all(8),
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 8),
              Text(
                'New Message',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Search field
        Padding(
          padding: const EdgeInsets.all(8),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: theme.textTheme.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _search('');
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    )
                  : null,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: _search,
          ),
        ),

        // Results
        Expanded(
          child: _buildResults(theme),
        ),
      ],
    );
  }

  Widget _buildResults(ThemeData theme) {
    if (_isCreatingConversation) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.error,
          ),
        ),
      );
    }

    if (_isSearching) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_searchController.text.trim().length < 2) {
      return Center(
        child: Text(
          'Enter at least 2 characters',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final user = _results[index];
        return ListTile(
          dense: true,
          leading: UserAvatar(name: user.username, size: 32),
          title: Text(user.username, style: theme.textTheme.bodyMedium),
          onTap: () => _startConversation(user),
        );
      },
    );
  }
}

class _UserSearchResult {
  final String id;
  final String username;

  _UserSearchResult({required this.id, required this.username});

  factory _UserSearchResult.fromJson(Map<String, dynamic> json) {
    return _UserSearchResult(
      id: json['id'] as String? ?? json['userId'] as String? ?? '',
      username: json['username'] as String? ?? 'Unknown',
    );
  }
}
