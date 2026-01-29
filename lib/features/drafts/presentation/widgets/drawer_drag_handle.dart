import 'package:flutter/material.dart';

/// Drag handle for DraggableScrollableSheet.
///
/// Provides a visual affordance (pill-shaped indicator) and optional
/// tap-to-toggle functionality for expanding/collapsing the drawer.
class DrawerDragHandle extends StatelessWidget {
  /// Called when the handle is tapped.
  final VoidCallback? onTap;

  const DrawerDragHandle({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.only(top: 8, bottom: 4),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}
