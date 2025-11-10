import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Global error utility to sanitize messages for end-users in production
/// while keeping detailed diagnostics visible in development.
class ErrorUtils {
  const ErrorUtils._();

  static bool get isRelease => kReleaseMode || bool.fromEnvironment('dart.vm.product');

  /// Convert any error/exception into a user-facing message.
  /// - In dev: returns the raw error string (helpful for debugging)
  /// - In release: returns a friendly message without technical details
  static String userMessage(Object? error, {String? fallback}) {
    final fallbackMsg = fallback ?? 'Something went wrong. Please try again.';

    if (!isRelease) {
      return _errorToString(error);
    }

    // Production: map common errors to friendly messages
    if (error is TimeoutException) {
      return 'Request timed out. Please try again.';
    }
    if (error is SocketException) {
      return 'Unable to connect. Check your internet connection and try again.';
    }
    if (error is HandshakeException) {
      return 'Secure connection failed. Please try again later.';
    }
    if (error is HttpException) {
      return 'Network error occurred. Please try again.';
    }
    if (error is FormatException) {
      return 'Unexpected response from server. Please try again later.';
    }

    // If it's already a string (like a server message), pass it through in production
    if (error is String) {
      return error.isNotEmpty ? error : fallbackMsg;
    }

    return fallbackMsg;
  }

  /// Log error details to console for diagnostics (no-op for users).
  static void log(Object? error, [StackTrace? stackTrace, String? context]) {
    final prefix = context != null ? '[$context] ' : '';
    debugPrint('$prefix${_errorToString(error)}');
    if (stackTrace != null) {
      debugPrint(stackTrace.toString());
    }
  }

  static String _errorToString(Object? error) => error?.toString() ?? 'Unknown error';
}

