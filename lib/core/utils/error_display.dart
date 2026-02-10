import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/snack_bar_service.dart';
import 'error_sanitizer.dart';

/// Extension for showing sanitized error messages via SnackBar.
extension ErrorDisplay on Object {
  /// Shows a sanitized error message using the global SnackBarService.
  void showAsError(WidgetRef ref) {
    ref.read(snackBarServiceProvider).showError(toUserMessage());
  }

  /// Shows a sanitized error message using BuildContext.
  void showAsErrorWithContext(BuildContext context) {
    SnackBarService.showErrorWithContext(context, toUserMessage());
  }
}

/// Shows a success snackbar via the global SnackBarService.
void showSuccess(WidgetRef ref, String message) {
  ref.read(snackBarServiceProvider).showSuccess(message);
}

/// Shows a success snackbar using BuildContext.
void showSuccessWithContext(BuildContext context, String message) {
  SnackBarService.showSuccessWithContext(context, message);
}

/// Shows an info snackbar via the global SnackBarService.
void showInfo(WidgetRef ref, String message) {
  ref.read(snackBarServiceProvider).showInfo(message);
}

/// Standardized mutation error handler with action-specific prefix.
///
/// Handles rollback, displays a user-friendly error message, and optionally
/// triggers a refetch to resync state.
void handleMutationError(
  WidgetRef ref,
  Object error, {
  String? action,
  VoidCallback? onRollback,
  VoidCallback? onRefetch,
}) {
  onRollback?.call();
  final message = action != null
      ? '$action: ${error.toUserMessage()}'
      : error.toUserMessage();
  ref.read(snackBarServiceProvider).showError(message);
  onRefetch?.call();
}
