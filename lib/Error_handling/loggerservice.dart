import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class LoggerService {
  static final Logger _logger = Logger();

  /// Logs an error message with optional error and stack trace.
  static void logError(String message, {dynamic error, StackTrace? stackTrace}) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  /// Displays an error message using a Snackbar in the UI.
  static void showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message, style: TextStyle(color: Colors.white)), backgroundColor: Colors.red),
    );
  }
}
