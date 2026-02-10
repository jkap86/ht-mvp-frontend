import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/api/api_client.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../data/dm_repository.dart';
import '../providers/dm_inbox_provider.dart';

/// A bottom sheet for searching users and starting a new DM conversation.
class DmUserSearchSheet extends ConsumerStatefulWidget {
  /// Optional callback when a conversation is created.
  /// If provided, this is called instead of navigating to the conversation screen.
  /// Parameters: (conversationId, otherUsername)
  final void Function(int conversationId, String username)? onConversationCreated;

  const DmUserSearchSheet({
    super.key,
    this.onConversationCreated,
  });

  @override
  ConsumerState<DmUserSearchSheet> createState() => _DmUserSearchSheetState();
}

class _DmUserSearchSheetState extends ConsumerState<DmUserSearchSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<_UserSearchResult> _results = [];
  bool _isSearching = false;
  bool _isCreatingConversation = false;
  String? _error;
  Timer? _searchDebounce;

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
    _searchDebounce?.cancel();
    _searchController.removeListener(_onTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().length < 2) {
      setState(() {
        _results = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isSearching = true;
      _error = null;
    });

    try {
      final apiClient = ref.read(apiClientProvider);
      final response = await apiClient.get('/auth/users/search?q=${Uri.encodeComponent(query)}');
      final users = (response as List)
          .map((json) => _UserSearchResult.fromJson(json as Map<String, dynamic>))
          .toList();

      if (mounted) {
        setState(() {
          _results = users;
          _isSearching = false;
        });
      }
    } catch (e) {
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

        // Close the sheet
        Navigator.of(context).pop();

        // Use callback if provided, otherwise navigate
        if (widget.onConversationCreated != null) {
          widget.onConversationCreated!(conversation.id, conversation.otherUsername);
        } else {
          context.push('/messages/${conversation.id}');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Error starting conversation');
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingConversation = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              ),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'New Message',
              style: theme.textTheme.titleLarge,
            ),
          ),

          // Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: AppSpacing.cardRadius,
                ),
              ),
              onChanged: (query) {
                _searchDebounce?.cancel();
                _searchDebounce = Timer(const Duration(milliseconds: 300), () => _search(query));
              },
            ),
          ),

          const SizedBox(height: 8),

          // Results
          Expanded(
            child: _buildResults(theme),
          ),
        ],
      ),
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
          style: theme.textTheme.bodyMedium?.copyWith(
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
          'Enter at least 2 characters to search',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Text(
          'No users found',
          style: theme.textTheme.bodyMedium?.copyWith(
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
          leading: UserAvatar(name: user.username, size: 40),
          title: Text(user.username),
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
