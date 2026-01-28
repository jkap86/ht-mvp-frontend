import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// AppBar back button that properly handles navigation within the league shell.
/// When at a root tab screen, navigates back to leagues list.
/// When nested deeper, pops to the previous screen.
class LeagueBackButton extends StatelessWidget {
  final int leagueId;

  const LeagueBackButton({
    super.key,
    required this.leagueId,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        if (context.canPop()) {
          context.pop();
        } else {
          // At root of tab, go to leagues list
          context.go('/leagues');
        }
      },
    );
  }
}

/// Helper to determine if we should show back button based on route depth
bool shouldShowBackButton(BuildContext context) {
  // Check if we can pop (meaning we're not at root of navigation)
  return GoRouter.of(context).canPop();
}
