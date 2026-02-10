import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_theme.dart';
import '../theme/app_spacing.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/leagues/data/league_repository.dart';
import '../../features/leagues/presentation/providers/league_detail_provider.dart';
import '../socket/socket_service.dart';

/// Developer console widget for quick user switching and adding users to league.
/// Only visible in debug mode.
class DevConsole extends ConsumerStatefulWidget {
  final int? leagueId;

  const DevConsole({super.key, this.leagueId});

  @override
  ConsumerState<DevConsole> createState() => _DevConsoleState();
}

class _DevConsoleState extends ConsumerState<DevConsole> {
  bool _isExpanded = false;
  bool _isLoading = false;
  String? _statusMessage;
  final Set<String> _selectedUsers = {};

  final List<String> _testUsers = List.generate(12, (i) => 'test${i + 1}');

  Future<void> _quickLogin(String username) async {
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      await ref.read(authStateProvider.notifier).login(username, 'password');

      setState(() => _statusMessage = 'Logged in as $username');

      // Reconnect socket with new token
      ref.invalidate(socketServiceProvider);

      // Navigate to home to refresh
      if (mounted) context.go('/home');
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Failed: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addSelectedUsersToLeague() async {
    if (widget.leagueId == null || _selectedUsers.isEmpty) {
      setState(() => _statusMessage = 'Select users first');
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    try {
      final repository = ref.read(leagueRepositoryProvider);
      final results = await repository.devAddUsersToLeague(
        widget.leagueId!,
        _selectedUsers.toList(),
      );

      final successes = results.where((r) => r['success'] == true).length;
      final failures = results.where((r) => r['success'] == false).length;

      // Force refresh of league detail if any users were added
      if (successes > 0) {
        ref.invalidate(leagueDetailProvider(widget.leagueId!));
      }

      if (mounted) {
        setState(() {
          if (failures == 0) {
            _statusMessage = 'Added $successes user(s)';
            _selectedUsers.clear();
          } else {
            _statusMessage = 'Added $successes, $failures failed';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _statusMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) return const SizedBox.shrink();

    return Positioned(
      top: 100,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: AppSpacing.buttonRadius,
        color: Theme.of(context).colorScheme.error,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isExpanded ? 220 : 48,
          constraints: BoxConstraints(maxHeight: _isExpanded ? 500 : 48),
          child: _isExpanded ? _buildExpanded() : _buildCollapsed(),
        ),
      ),
    );
  }

  Widget _buildCollapsed() {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      icon: Icon(Icons.developer_mode, color: colorScheme.onError),
      onPressed: () => setState(() => _isExpanded = true),
      tooltip: 'Dev Console',
    );
  }

  Widget _buildExpanded() {
    final colorScheme = Theme.of(context).colorScheme;
    final onError = colorScheme.onError;
    final onErrorMuted = colorScheme.onError.withAlpha(179);
    final onErrorSubtle = colorScheme.onError.withAlpha(61);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.error,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusMd)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dev Console',
                style: TextStyle(
                  color: onError,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: onError, size: 16),
                onPressed: () => setState(() => _isExpanded = false),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),
        // Content
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Add to League section (only if leagueId is provided)
                if (widget.leagueId != null) ...[
                  _buildAddUsersSection(),
                  const SizedBox(height: 8),
                  Divider(color: onErrorSubtle),
                  const SizedBox(height: 8),
                ],

                // Quick Login section
                Text(
                  'Quick Login',
                  style: TextStyle(
                    color: onError,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: _testUsers.map((u) => _buildLoginButton(u)).toList(),
                ),

                // Status message
                if (_statusMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _statusMessage!,
                    style: TextStyle(color: onErrorMuted, fontSize: 10),
                  ),
                ],
                if (_isLoading) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: onError,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddUsersSection() {
    final colorScheme = Theme.of(context).colorScheme;
    final onError = colorScheme.onError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Add to League',
              style: TextStyle(
                color: onError,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  if (_selectedUsers.length == _testUsers.length) {
                    _selectedUsers.clear();
                  } else {
                    _selectedUsers.addAll(_testUsers);
                  }
                });
              },
              child: Text(
                _selectedUsers.length == _testUsers.length ? 'Clear' : 'All',
                style: TextStyle(color: onError.withAlpha(138), fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: _testUsers.map((u) => _buildSelectableUser(u)).toList(),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 28,
          child: ElevatedButton(
            onPressed: _isLoading || _selectedUsers.isEmpty
                ? null
                : _addSelectedUsersToLeague,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.draftWarning,
              foregroundColor: onError,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: Text(
              'Add (${_selectedUsers.length})',
              style: const TextStyle(fontSize: 11),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectableUser(String username) {
    final isSelected = _selectedUsers.contains(username);
    final colorScheme = Theme.of(context).colorScheme;
    final onError = colorScheme.onError;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedUsers.remove(username);
          } else {
            _selectedUsers.add(username);
          }
        });
      },
      child: Container(
        width: 48,
        height: 24,
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.draftWarning : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.draftWarning : onError.withAlpha(61),
          ),
          borderRadius: AppSpacing.badgeRadius,
        ),
        alignment: Alignment.center,
        child: Text(
          username.replaceFirst('test', ''),
          style: TextStyle(
            color: isSelected ? onError : onError.withAlpha(179),
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(String username) {
    final colorScheme = Theme.of(context).colorScheme;
    final onError = colorScheme.onError;

    return SizedBox(
      width: 48,
      height: 24,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _quickLogin(username),
        style: OutlinedButton.styleFrom(
          foregroundColor: onError,
          side: BorderSide(color: onError.withAlpha(61)),
          padding: EdgeInsets.zero,
        ),
        child: Text(
          username.replaceFirst('test', ''),
          style: const TextStyle(fontSize: 10),
        ),
      ),
    );
  }
}
