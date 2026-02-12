import 'package:flutter/material.dart';

import 'skeleton_base.dart';

/// Skeleton loading state for a chat message bubble (matches league chat layout)
class SkeletonChatMessage extends StatelessWidget {
  /// If true, renders as a right-aligned "sent" bubble (no avatar)
  final bool isMe;

  const SkeletonChatMessage({
    super.key,
    this.isMe = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        bottom: 4,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      child: SkeletonShimmer(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment:
              isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMe) ...[
              const SkeletonCircle(size: 28),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment:
                    isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe)
                    Row(
                      children: const [
                        SkeletonBox(width: 70, height: 12),
                        SizedBox(width: 8),
                        SkeletonBox(width: 40, height: 10),
                      ],
                    ),
                  if (!isMe) const SizedBox(height: 4),
                  // Message bubble placeholder
                  SkeletonBox(
                    width: isMe ? 160 : 180,
                    height: 36,
                    borderRadius: 12,
                  ),
                ],
              ),
            ),
            if (isMe) const SizedBox(width: 36),
          ],
        ),
      ),
    );
  }
}

/// Skeleton list for chat messages (reversed list like real chat)
class SkeletonChatMessageList extends StatelessWidget {
  final int itemCount;
  final EdgeInsetsGeometry? padding;

  const SkeletonChatMessageList({
    super.key,
    this.itemCount = 8,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    // Simulate a realistic chat with alternating senders
    return ListView.builder(
      padding: padding ?? const EdgeInsets.all(8),
      reverse: true,
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Alternate pattern: mostly "other" messages with a few "me" mixed in
        final isMe = index % 3 == 1;
        return SkeletonChatMessage(isMe: isMe);
      },
    );
  }
}
