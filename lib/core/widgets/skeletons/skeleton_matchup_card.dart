import 'package:flutter/material.dart';

import 'skeleton_base.dart';

/// Skeleton loading state for matchup cards
class SkeletonMatchupCard extends StatelessWidget {
  const SkeletonMatchupCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SkeletonShimmer(
          child: Column(
            children: [
              // Week header placeholder
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  SkeletonBox(width: 80, height: 14),
                ],
              ),
              const SizedBox(height: 16),

              // Teams row
              Row(
                children: [
                  // Home team
                  Expanded(
                    child: Column(
                      children: const [
                        SkeletonCircle(size: 48),
                        SizedBox(height: 8),
                        SkeletonBox(width: 80, height: 14),
                        SizedBox(height: 4),
                        SkeletonBox(width: 40, height: 24),
                      ],
                    ),
                  ),

                  // VS divider
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SkeletonBox(width: 24, height: 14),
                  ),

                  // Away team
                  Expanded(
                    child: Column(
                      children: const [
                        SkeletonCircle(size: 48),
                        SizedBox(height: 8),
                        SkeletonBox(width: 80, height: 14),
                        SizedBox(height: 4),
                        SkeletonBox(width: 40, height: 24),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Status placeholder
              const SkeletonBox(width: 100, height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of skeleton matchup cards
class SkeletonMatchupList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry? padding;

  const SkeletonMatchupList({
    super.key,
    this.itemCount = 5,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: SkeletonMatchupCard(),
      ),
    );
  }
}
