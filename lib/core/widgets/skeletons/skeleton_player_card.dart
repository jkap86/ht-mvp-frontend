import 'package:flutter/material.dart';

import 'skeleton_base.dart';

/// Skeleton loading state for player cards (matches RosterPlayerCard layout)
class SkeletonPlayerCard extends StatelessWidget {
  const SkeletonPlayerCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SkeletonShimmer(
          child: Row(
            children: [
              // Position badge placeholder
              const SkeletonBox(
                width: 40,
                height: 40,
                borderRadius: 8,
              ),
              const SizedBox(width: 12),

              // Player info placeholders
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name placeholder
                    const SkeletonBox(
                      width: 140,
                      height: 16,
                    ),
                    const SizedBox(height: 8),
                    // Team and details placeholder
                    Row(
                      children: [
                        const SkeletonBox(
                          width: 30,
                          height: 14,
                        ),
                        const SizedBox(width: 8),
                        const SkeletonBox(
                          width: 50,
                          height: 14,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Points placeholder
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  SkeletonBox(
                    width: 40,
                    height: 16,
                  ),
                  SizedBox(height: 4),
                  SkeletonBox(
                    width: 30,
                    height: 10,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// List of skeleton player cards
class SkeletonPlayerList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry? padding;

  const SkeletonPlayerList({
    super.key,
    this.itemCount = 10,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: SkeletonPlayerCard(),
      ),
    );
  }
}
