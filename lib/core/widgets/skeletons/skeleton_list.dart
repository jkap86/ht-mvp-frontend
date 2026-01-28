import 'package:flutter/material.dart';

import 'skeleton_base.dart';

/// Generic skeleton list with configurable item builder
class SkeletonList extends StatelessWidget {
  final int itemCount;
  final Widget Function(BuildContext context, int index)? itemBuilder;
  final EdgeInsetsGeometry? padding;
  final double itemSpacing;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const SkeletonList({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
    this.padding,
    this.itemSpacing = 8,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  Widget build(BuildContext context) {
    final builder = itemBuilder ?? _defaultItemBuilder;

    return ListView.separated(
      padding: padding ?? const EdgeInsets.all(16),
      itemCount: itemCount,
      shrinkWrap: shrinkWrap,
      physics: physics,
      separatorBuilder: (context, index) => SizedBox(height: itemSpacing),
      itemBuilder: builder,
    );
  }

  Widget _defaultItemBuilder(BuildContext context, int index) {
    return const SkeletonListItem();
  }
}

/// Default skeleton list item
class SkeletonListItem extends StatelessWidget {
  const SkeletonListItem({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SkeletonShimmer(
          child: Row(
            children: [
              const SkeletonCircle(size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 14, width: 120),
                    SizedBox(height: 8),
                    SkeletonBox(height: 12, width: 80),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Skeleton for trade cards
class SkeletonTradeCard extends StatelessWidget {
  const SkeletonTradeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SkeletonShimmer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with status
              Row(
                children: const [
                  SkeletonBox(width: 70, height: 24, borderRadius: 4),
                  Spacer(),
                  SkeletonBox(width: 50, height: 12),
                ],
              ),
              const SizedBox(height: 12),

              // Teams
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(width: 100, height: 14),
                        SizedBox(height: 4),
                        SkeletonBox(width: 60, height: 12),
                      ],
                    ),
                  ),
                  const SkeletonBox(width: 24, height: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        SkeletonBox(width: 100, height: 14),
                        SizedBox(height: 4),
                        SkeletonBox(width: 60, height: 12),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),

              // Player preview
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        SkeletonBox(height: 12),
                        SizedBox(height: 4),
                        SkeletonBox(height: 12, width: 80),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        SkeletonBox(height: 12),
                        SizedBox(height: 4),
                        SkeletonBox(height: 12, width: 80),
                      ],
                    ),
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

/// List of skeleton trade cards
class SkeletonTradeList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry? padding;

  const SkeletonTradeList({
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
        child: SkeletonTradeCard(),
      ),
    );
  }
}

/// Skeleton for standings table rows
class SkeletonStandingsRow extends StatelessWidget {
  const SkeletonStandingsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: SkeletonShimmer(
        child: Row(
          children: const [
            SkeletonBox(width: 24, height: 20),
            SizedBox(width: 12),
            SkeletonCircle(size: 32),
            SizedBox(width: 12),
            Expanded(child: SkeletonBox(height: 14)),
            SizedBox(width: 16),
            SkeletonBox(width: 40, height: 14),
            SizedBox(width: 16),
            SkeletonBox(width: 50, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for standings table
class SkeletonStandingsTable extends StatelessWidget {
  final int rowCount;

  const SkeletonStandingsTable({
    super.key,
    this.rowCount = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: SkeletonShimmer(
            child: Row(
              children: const [
                SkeletonBox(width: 30, height: 12),
                SizedBox(width: 44),
                Expanded(child: SkeletonBox(height: 12)),
                SizedBox(width: 16),
                SkeletonBox(width: 40, height: 12),
                SizedBox(width: 16),
                SkeletonBox(width: 50, height: 12),
              ],
            ),
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: rowCount,
            itemBuilder: (context, index) => const SkeletonStandingsRow(),
          ),
        ),
      ],
    );
  }
}
