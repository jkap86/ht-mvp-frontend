import 'package:flutter/material.dart';

import 'skeleton_base.dart';

/// Skeleton loading state for lineup roster slots
class SkeletonRosterSlot extends StatelessWidget {
  const SkeletonRosterSlot({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: SkeletonShimmer(
          child: Row(
            children: [
              // Slot position placeholder
              const SkeletonBox(
                width: 36,
                height: 36,
                borderRadius: 6,
              ),
              const SizedBox(width: 12),

              // Player info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SkeletonBox(width: 120, height: 14),
                    const SizedBox(height: 6),
                    Row(
                      children: const [
                        SkeletonBox(width: 28, height: 12),
                        SizedBox(width: 8),
                        SkeletonBox(width: 60, height: 12),
                      ],
                    ),
                  ],
                ),
              ),

              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: const [
                  SkeletonBox(width: 36, height: 16),
                  SizedBox(height: 4),
                  SkeletonBox(width: 24, height: 10),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for a full lineup (starters + bench sections)
class SkeletonLineup extends StatelessWidget {
  final int starterCount;
  final int benchCount;

  const SkeletonLineup({
    super.key,
    this.starterCount = 9,
    this.benchCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Starters header
          const SkeletonShimmer(
            child: SkeletonBox(width: 80, height: 18),
          ),
          const SizedBox(height: 12),

          // Starter slots
          ...List.generate(
            starterCount,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SkeletonRosterSlot(),
            ),
          ),

          const SizedBox(height: 24),

          // Bench header
          const SkeletonShimmer(
            child: SkeletonBox(width: 60, height: 18),
          ),
          const SizedBox(height: 12),

          // Bench slots
          ...List.generate(
            benchCount,
            (index) => const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SkeletonRosterSlot(),
            ),
          ),
        ],
      ),
    );
  }
}
