import 'package:flutter/material.dart';
import '../../theme/app_spacing.dart';
import '../../utils/error_message_mapper.dart';

/// A reusable error view with message and optional retry button.
///
/// Can be constructed in two ways:
///
/// 1. **Simple** (backwards-compatible) - pass a [message] string directly:
///    ```dart
///    AppErrorView(message: 'Something went wrong', onRetry: () => reload());
///    ```
///
/// 2. **From exception** - pass the raw error and let [ErrorMessageMapper]
///    choose the icon, message, and secondary action automatically:
///    ```dart
///    AppErrorView.fromError(error: exception, onRetry: () => reload());
///    ```
class AppErrorView extends StatelessWidget {
  /// User-facing error message.
  final String message;

  /// Icon displayed above the message. Defaults to a generic error icon.
  final IconData icon;

  /// Primary action callback. When provided, a "Retry" button is shown.
  final VoidCallback? onRetry;

  /// Label for the primary action button.
  final String retryText;

  /// Optional secondary action callback (e.g. Go Back, Sign In).
  final VoidCallback? onSecondaryAction;

  /// Label for the secondary action button.
  final String? secondaryActionText;

  /// Whether the error is considered compact (inline) vs. full-screen.
  /// When true, reduces padding and icon size for use inside cards/lists.
  final bool compact;

  const AppErrorView({
    super.key,
    required this.message,
    this.icon = Icons.error_outline_rounded,
    this.onRetry,
    this.retryText = 'Retry',
    this.onSecondaryAction,
    this.secondaryActionText,
    this.compact = false,
  });

  /// Constructs an [AppErrorView] from a raw error/exception.
  ///
  /// Uses [ErrorMessageMapper] to derive a user-friendly message, contextual
  /// icon, and retry-ability. You can still override [onRetry] and
  /// [onSecondaryAction] to wire up your own callbacks.
  ///
  /// Example:
  /// ```dart
  /// AppErrorView.fromError(
  ///   error: caughtException,
  ///   onRetry: () => ref.read(provider.notifier).reload(),
  ///   onSecondaryAction: () => Navigator.pop(context),
  /// );
  /// ```
  factory AppErrorView.fromError({
    Key? key,
    required Object error,
    VoidCallback? onRetry,
    VoidCallback? onSecondaryAction,
    String? secondaryActionText,
    bool compact = false,
  }) {
    final info = ErrorMessageMapper.map(error);
    return AppErrorView(
      key: key,
      message: info.message,
      icon: info.icon,
      onRetry: info.isRetryable ? onRetry : null,
      retryText: 'Retry',
      onSecondaryAction: onSecondaryAction,
      secondaryActionText:
          secondaryActionText ?? _defaultSecondaryLabel(info.secondaryAction),
      compact: compact,
    );
  }

  /// Returns the default label for a given [SecondaryAction].
  static String? _defaultSecondaryLabel(SecondaryAction action) {
    switch (action) {
      case SecondaryAction.goBack:
        return 'Go Back';
      case SecondaryAction.signIn:
        return 'Sign In';
      case SecondaryAction.contactSupport:
        return 'Contact Support';
      case SecondaryAction.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    final double iconSize = compact ? 36 : 48;
    final double padding = compact ? AppSpacing.lg : AppSpacing.xl;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
          children: [
            Icon(
              icon,
              size: iconSize,
              color: errorColor,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(retryText),
              ),
            ],
            if (onSecondaryAction != null &&
                secondaryActionText != null) ...[
              const SizedBox(height: AppSpacing.sm),
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(secondaryActionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
