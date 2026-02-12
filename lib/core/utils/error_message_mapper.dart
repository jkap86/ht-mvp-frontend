import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import '../api/api_exceptions.dart';

/// Categorizes errors into user-actionable types.
enum ErrorCategory {
  /// No internet or DNS failure.
  network,

  /// Request took too long.
  timeout,

  /// 401 - session expired / invalid credentials.
  auth,

  /// 403 - user lacks permission.
  forbidden,

  /// 404 - resource missing / removed.
  notFound,

  /// 400 - bad user input.
  validation,

  /// 409 - concurrent modification.
  conflict,

  /// 5xx - server-side failure.
  server,

  /// Everything else.
  unknown,
}

/// Describes the secondary action the UI can present alongside "Retry".
enum SecondaryAction {
  /// No secondary action.
  none,

  /// Navigate back.
  goBack,

  /// Trigger sign-in flow.
  signIn,

  /// Show a "Contact Support" option.
  contactSupport,
}

/// Structured error information ready for the UI layer.
class ErrorInfo {
  /// Human-readable message (safe for end-user display).
  final String message;

  /// Icon that represents the error category.
  final IconData icon;

  /// The broad category of the error.
  final ErrorCategory category;

  /// Whether a "Retry" button makes sense.
  final bool isRetryable;

  /// Suggested secondary action.
  final SecondaryAction secondaryAction;

  const ErrorInfo({
    required this.message,
    required this.icon,
    required this.category,
    required this.isRetryable,
    this.secondaryAction = SecondaryAction.none,
  });
}

/// Maps exceptions and arbitrary errors to structured [ErrorInfo] objects.
///
/// This is the single source of truth for how errors are presented in the UI.
/// It works in concert with [ErrorSanitizer] (which handles raw string
/// sanitization) but adds icon selection, retry-ability, and secondary actions.
class ErrorMessageMapper {
  ErrorMessageMapper._();

  /// Maps any error/exception to a structured [ErrorInfo].
  static ErrorInfo map(Object error) {
    // ── Dart platform exceptions ──────────────────────────────────────
    if (error is SocketException) {
      return const ErrorInfo(
        message: 'No internet connection. Check your connection and try again.',
        icon: Icons.wifi_off_rounded,
        category: ErrorCategory.network,
        isRetryable: true,
      );
    }

    if (error is TimeoutException) {
      return const ErrorInfo(
        message: 'Request timed out. Please try again.',
        icon: Icons.timer_off_rounded,
        category: ErrorCategory.timeout,
        isRetryable: true,
      );
    }

    // ── App-specific API exceptions ───────────────────────────────────
    if (error is NetworkException) {
      return const ErrorInfo(
        message: 'No internet connection. Check your connection and try again.',
        icon: Icons.wifi_off_rounded,
        category: ErrorCategory.network,
        isRetryable: true,
      );
    }

    if (error is UnauthorizedException) {
      return const ErrorInfo(
        message: 'Session expired. Please sign in again.',
        icon: Icons.lock_outline_rounded,
        category: ErrorCategory.auth,
        isRetryable: false,
        secondaryAction: SecondaryAction.signIn,
      );
    }

    if (error is ForbiddenException) {
      return const ErrorInfo(
        message: "You don't have permission to perform this action.",
        icon: Icons.block_rounded,
        category: ErrorCategory.forbidden,
        isRetryable: false,
        secondaryAction: SecondaryAction.goBack,
      );
    }

    if (error is NotFoundException) {
      return const ErrorInfo(
        message: 'The requested item could not be found. It may have been removed.',
        icon: Icons.search_off_rounded,
        category: ErrorCategory.notFound,
        isRetryable: false,
        secondaryAction: SecondaryAction.goBack,
      );
    }

    if (error is ValidationException) {
      return ErrorInfo(
        message: error.message,
        icon: Icons.warning_amber_rounded,
        category: ErrorCategory.validation,
        isRetryable: false,
        secondaryAction: SecondaryAction.goBack,
      );
    }

    if (error is ConflictException) {
      return ErrorInfo(
        message: error.message,
        icon: Icons.sync_problem_rounded,
        category: ErrorCategory.conflict,
        isRetryable: true,
      );
    }

    if (error is ServerException) {
      return const ErrorInfo(
        message: 'Something went wrong on our end. Please try again.',
        icon: Icons.cloud_off_rounded,
        category: ErrorCategory.server,
        isRetryable: true,
        secondaryAction: SecondaryAction.contactSupport,
      );
    }

    // Generic ApiException that didn't match a specific subtype
    if (error is ApiException) {
      return _mapGenericApiException(error);
    }

    // ── Timeout-like string errors ────────────────────────────────────
    if (error is String) {
      final lower = error.toLowerCase();
      if (lower.contains('timeout') || lower.contains('timed out')) {
        return const ErrorInfo(
          message: 'Request timed out. Please try again.',
          icon: Icons.timer_off_rounded,
          category: ErrorCategory.timeout,
          isRetryable: true,
        );
      }
      if (lower.contains('socket') ||
          lower.contains('connection') ||
          lower.contains('network')) {
        return const ErrorInfo(
          message:
              'No internet connection. Check your connection and try again.',
          icon: Icons.wifi_off_rounded,
          category: ErrorCategory.network,
          isRetryable: true,
        );
      }
    }

    // ── Fallback ──────────────────────────────────────────────────────
    return const ErrorInfo(
      message: 'An unexpected error occurred. Please try again.',
      icon: Icons.error_outline_rounded,
      category: ErrorCategory.unknown,
      isRetryable: true,
      secondaryAction: SecondaryAction.contactSupport,
    );
  }

  /// Maps a generic [ApiException] using its status code.
  static ErrorInfo _mapGenericApiException(ApiException error) {
    final code = error.statusCode;
    if (code == null) {
      return const ErrorInfo(
        message: 'No internet connection. Check your connection and try again.',
        icon: Icons.wifi_off_rounded,
        category: ErrorCategory.network,
        isRetryable: true,
      );
    }
    if (code == 401) {
      return const ErrorInfo(
        message: 'Session expired. Please sign in again.',
        icon: Icons.lock_outline_rounded,
        category: ErrorCategory.auth,
        isRetryable: false,
        secondaryAction: SecondaryAction.signIn,
      );
    }
    if (code == 403) {
      return const ErrorInfo(
        message: "You don't have permission to perform this action.",
        icon: Icons.block_rounded,
        category: ErrorCategory.forbidden,
        isRetryable: false,
        secondaryAction: SecondaryAction.goBack,
      );
    }
    if (code >= 500) {
      return const ErrorInfo(
        message: 'Something went wrong on our end. Please try again.',
        icon: Icons.cloud_off_rounded,
        category: ErrorCategory.server,
        isRetryable: true,
        secondaryAction: SecondaryAction.contactSupport,
      );
    }
    return ErrorInfo(
      message: error.message,
      icon: Icons.error_outline_rounded,
      category: ErrorCategory.unknown,
      isRetryable: true,
    );
  }
}
