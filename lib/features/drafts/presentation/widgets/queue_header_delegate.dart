import 'package:flutter/material.dart';

/// Delegate for the pinned queue header in the sliver list.
/// This keeps the queue visible at the top while allowing drag gestures
/// to propagate to the DraggableScrollableSheet.
class QueueHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  static const double _preferredHeight = 120.0;
  static const double _minHeight = 50.0;

  QueueHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox.expand(child: child);
  }

  @override
  double get maxExtent => _preferredHeight;

  @override
  double get minExtent => _minHeight;

  @override
  bool shouldRebuild(covariant QueueHeaderDelegate oldDelegate) {
    return oldDelegate.child != child;
  }
}
