import 'package:flutter/widgets.dart';

/// Shared layout constants and utilities for adaptive content widths.
///
/// Use [maxContentWidth] for main screen content areas that currently
/// use `ConstrainedBox(maxWidth: 600)`. This adapts to the device
/// width so tablet and desktop users get a wider content area.
class AppLayout {
  AppLayout._();

  /// Returns the maximum content width for the current screen size.
  ///
  /// - Phone (< 768px): 600px
  /// - Tablet (768-1199px): 800px
  /// - Desktop/web (>= 1200px): 1000px
  static double maxContentWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 1000;
    if (width >= 768) return 800;
    return 600;
  }

  /// Returns a [BoxConstraints] with the adaptive max content width.
  ///
  /// Convenience method so callers can write:
  /// ```dart
  /// ConstrainedBox(constraints: AppLayout.contentConstraints(context))
  /// ```
  static BoxConstraints contentConstraints(BuildContext context) {
    return BoxConstraints(maxWidth: maxContentWidth(context));
  }
}
