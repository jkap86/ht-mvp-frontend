import 'package:flutter/material.dart';

import 'skeleton_base.dart';

/// Skeleton loading state for a DM inbox conversation tile
class SkeletonConversationTile extends StatelessWidget {
  const SkeletonConversationTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const SkeletonShimmer(
        child: SkeletonCircle(size: 48),
      ),
      title: SkeletonShimmer(
        child: Row(
          children: const [
            Expanded(child: SkeletonBox(height: 14, width: 100)),
            SizedBox(width: 8),
            SkeletonBox(width: 40, height: 10),
          ],
        ),
      ),
      subtitle: const SkeletonShimmer(
        child: SkeletonBox(height: 12, width: 160),
      ),
    );
  }
}

/// Skeleton list for DM inbox conversations
class SkeletonConversationList extends StatelessWidget {
  final int itemCount;

  const SkeletonConversationList({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: itemCount,
      itemBuilder: (context, index) => const SkeletonConversationTile(),
    );
  }
}
