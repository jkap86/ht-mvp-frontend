import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/auth_provider.dart';
import '../../features/leagues/data/league_repository.dart';
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
        borderRadius: BorderRadius.circular(8),
        color: Colors.red.shade900,
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
    return IconButton(
      icon: const Icon(Icons.developer_mode, color: Colors.white),
      onPressed: () => setState(() => _isExpanded = true),
      tooltip: 'Dev Console',
    );
  }

  Widget _buildExpanded() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.shade800,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Dev Console',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 16),
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
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 8),
                ],

                // Quick Login section
                const Text(
                  'Quick Login',
                  style: TextStyle(
                    color: Colors.white,
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
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                ],
                if (_isLoading) ...[
                  const SizedBox(height: 8),
                  const Center(
                    child: SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add to League',
              style: TextStyle(
                color: Colors.white,
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
                style: const TextStyle(color: Colors.white54, fontSize: 10),
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
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
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
          color: isSelected ? Colors.orange : Colors.transparent,
          border: Border.all(
            color: isSelected ? Colors.orange : Colors.white24,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        alignment: Alignment.center,
        child: Text(
          username.replaceFirst('test', ''),
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 10,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton(String username) {
    return SizedBox(
      width: 48,
      height: 24,
      child: OutlinedButton(
        onPressed: _isLoading ? null : () => _quickLogin(username),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
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
