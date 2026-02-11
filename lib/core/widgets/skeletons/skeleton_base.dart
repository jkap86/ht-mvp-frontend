import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../../theme/hype_train_colors.dart';

/// Base shimmer wrapper for skeleton loading states
class SkeletonShimmer extends StatelessWidget {
  final Widget child;

  const SkeletonShimmer({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.htColors.surfaceContainer,
      highlightColor: context.htColors.surface,
      child: child,
    );
  }
}

/// A skeleton placeholder box with configurable dimensions
class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const SkeletonBox({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

/// A circular skeleton placeholder
class SkeletonCircle extends StatelessWidget {
  final double size;

  const SkeletonCircle({
    super.key,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
      ),
    );
  }
}
