import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/invitations_provider.dart';
import 'widgets/browse_public_tab.dart';
import 'widgets/create_league_tab.dart';
import 'widgets/invites_tab.dart';

class AddLeagueScreen extends ConsumerStatefulWidget {
  const AddLeagueScreen({super.key});

  @override
  ConsumerState<AddLeagueScreen> createState() => _AddLeagueScreenState();
}

class _AddLeagueScreenState extends ConsumerState<AddLeagueScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load invitations on init
    Future.microtask(() => ref.read(invitationsProvider.notifier).loadInvitations());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invitationsState = ref.watch(invitationsProvider);
    final pendingCount = invitationsState.invitations.length;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Add League'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            const Tab(
              icon: Icon(Icons.explore),
              text: 'Browse',
            ),
            const Tab(
              icon: Icon(Icons.add_circle_outline),
              text: 'Create',
            ),
            Tab(
              icon: Badge(
                isLabelVisible: pendingCount > 0,
                label: Text(pendingCount.toString()),
                child: const Icon(Icons.mail_outline),
              ),
              text: 'Invites',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          BrowsePublicTab(),
          CreateLeagueTab(),
          InvitesTab(),
        ],
      ),
    );
  }
}
