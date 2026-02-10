import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_theme.dart';

/// Global scaffold messenger key for showing snackbars without context.
///
/// This key must be passed to MaterialApp.scaffoldMessengerKey in main.dart.
final scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

/// Centralized service for showing snackbar messages.
///
/// This service provides a consistent way to display error, success, and info
/// messages across the app without needing direct access to BuildContext.
///
/// Usage with provider:
/// ```dart
/// ref.read(snackBarServiceProvider).showError('Something went wrong');
/// ```
///
/// Usage with context (when GlobalKey not available):
/// ```dart
/// SnackBarService.showErrorWithContext(context, 'Something went wrong');
/// ```
class SnackBarService {
  /// Show an error message (red background)
  void showError(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a success message (green background)
  void showSuccess(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.draftActionPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show an info message (default background)
  void showInfo(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show a warning message (orange background)
  void showWarning(String message) {
    scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.draftWarning,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Hide the current snackbar
  void hide() {
    scaffoldMessengerKey.currentState?.hideCurrentSnackBar();
  }

  // ============================================================
  // Static methods for use when context is available
  // (useful during transition or in widgets)
  // ============================================================

  /// Show error message using BuildContext
  static void showErrorWithContext(BuildContext context, String message) {
    final colorScheme = Theme.of(context).colorScheme;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show success message using BuildContext
  static void showSuccessWithContext(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.draftActionPrimary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show info message using BuildContext
  static void showInfoWithContext(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Global SnackBarService provider
final snackBarServiceProvider = Provider<SnackBarService>((ref) {
  return SnackBarService();
});
