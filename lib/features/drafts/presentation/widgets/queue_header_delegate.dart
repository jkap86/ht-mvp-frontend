import 'package:flutter/material.dart';

/// Delegate for the pinned queue header in the sliver list.
/// This keeps the queue visible at the top while allowing drag gestures
/// to propagate to the DraggableScrollableSheet.
class QueueHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  QueueHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  // Queue height: ~120px when populated (header row + card row)
  // ~50px when empty (compact single row)
  // Use 120 to accommodate the larger state
  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 120;

  @override
  bool shouldRebuild(covariant QueueHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
