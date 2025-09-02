import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Centralized error handling service for the Math Genius application
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  final List<AppError> _errors = [];
  final StreamController<AppError> _errorStream = StreamController<AppError>.broadcast();

  /// Stream of errors for listening to error events
  Stream<AppError> get errorStream => _errorStream.stream;

  /// Get all recorded errors
  List<AppError> get errors => List.unmodifiable(_errors);

  /// Handle an error with context and metadata
  void handleError(
    dynamic error, {
    StackTrace? stackTrace,
    String? context,
    Map<String, dynamic>? metadata,
    ErrorSeverity severity = ErrorSeverity.medium,
    bool shouldLog = true,
    bool shouldNotify = true,
  }) {
    final appError = AppError(
      error: error,
      stackTrace: stackTrace ?? StackTrace.current,
      context: context ?? 'Unknown',
      metadata: metadata ?? {},
      severity: severity,
      timestamp: DateTime.now(),
    );

    // Store error
    _errors.add(appError);
    
    // Keep only last 100 errors to prevent memory leaks
    if (_errors.length > 100) {
      _errors.removeAt(0);
    }

    // Log error if enabled
    if (shouldLog) {
      _logError(appError);
    }

    // Notify listeners if enabled
    if (shouldNotify) {
      _errorStream.add(appError);
    }
  }

  /// Handle Firebase-specific errors
  void handleFirebaseError(
    dynamic error, {
    StackTrace? stackTrace,
    String? operation,
    Map<String, dynamic>? metadata,
  }) {
    handleError(
      error,
      stackTrace: stackTrace,
      context: 'Firebase: ${operation ?? 'Unknown operation'}',
      metadata: {
        'service': 'firebase',
        'operation': operation,
        ...?metadata,
      },
      severity: ErrorSeverity.high,
    );
  }

  /// Handle network-related errors
  void handleNetworkError(
    dynamic error, {
    StackTrace? stackTrace,
    String? endpoint,
    int? statusCode,
    Map<String, dynamic>? metadata,
  }) {
    handleError(
      error,
      stackTrace: stackTrace,
      context: 'Network: ${endpoint ?? 'Unknown endpoint'}',
      metadata: {
        'service': 'network',
        'endpoint': endpoint,
        'statusCode': statusCode,
        ...?metadata,
      },
      severity: statusCode != null && statusCode >= 500 
        ? ErrorSeverity.high 
        : ErrorSeverity.medium,
    );
  }

  /// Handle game-specific errors
  void handleGameError(
    dynamic error, {
    StackTrace? stackTrace,
    String? gameType,
    String? sessionId,
    Map<String, dynamic>? metadata,
  }) {
    handleError(
      error,
      stackTrace: stackTrace,
      context: 'Game: ${gameType ?? 'Unknown game'}',
      metadata: {
        'service': 'game',
        'gameType': gameType,
        'sessionId': sessionId,
        ...?metadata,
      },
      severity: ErrorSeverity.medium,
    );
  }

  /// Handle user management errors
  void handleUserError(
    dynamic error, {
    StackTrace? stackTrace,
    String? operation,
    String? userId,
    Map<String, dynamic>? metadata,
  }) {
    handleError(
      error,
      stackTrace: stackTrace,
      context: 'User Management: ${operation ?? 'Unknown operation'}',
      metadata: {
        'service': 'user_management',
        'operation': operation,
        'userId': userId,
        ...?metadata,
      },
      severity: ErrorSeverity.high,
    );
  }

  /// Clear all errors
  void clearErrors() {
    _errors.clear();
  }

  /// Get errors by severity
  List<AppError> getErrorsBySeverity(ErrorSeverity severity) {
    return _errors.where((error) => error.severity == severity).toList();
  }

  /// Get recent errors (last N errors)
  List<AppError> getRecentErrors([int count = 10]) {
    final startIndex = _errors.length > count ? _errors.length - count : 0;
    return _errors.sublist(startIndex);
  }

  /// Log error to console and/or external service
  void _logError(AppError error) {
    if (kDebugMode) {
      print('🚨 ERROR [${error.severity.name.toUpperCase()}] ${error.context}');
      print('   Message: ${error.error}');
      print('   Time: ${error.timestamp}');
      if (error.metadata.isNotEmpty) {
        print('   Metadata: ${error.metadata}');
      }
      print('   Stack Trace: ${error.stackTrace}');
      print('');
    }

    // TODO: Send to external logging service in production
    // Example: Firebase Crashlytics, Sentry, etc.
  }

  /// Dispose resources
  void dispose() {
    _errorStream.close();
  }
}

/// Error severity levels
enum ErrorSeverity {
  low,      // Minor issues, warnings
  medium,   // Recoverable errors
  high,     // Critical errors affecting functionality
  critical, // App-breaking errors
}

/// Application error model
class AppError {
  final dynamic error;
  final StackTrace stackTrace;
  final String context;
  final Map<String, dynamic> metadata;
  final ErrorSeverity severity;
  final DateTime timestamp;

  const AppError({
    required this.error,
    required this.stackTrace,
    required this.context,
    required this.metadata,
    required this.severity,
    required this.timestamp,
  });

  @override
  String toString() {
    return 'AppError(context: $context, error: $error, severity: ${severity.name})';
  }

  /// Convert to JSON for logging/analytics
  Map<String, dynamic> toJson() {
    return {
      'error': error.toString(),
      'context': context,
      'metadata': metadata,
      'severity': severity.name,
      'timestamp': timestamp.toIso8601String(),
      'stackTrace': stackTrace.toString(),
    };
  }
}

/// Riverpod providers for error handling
final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});

final errorStreamProvider = StreamProvider<AppError>((ref) {
  final errorHandler = ref.read(errorHandlerProvider);
  return errorHandler.errorStream;
});

final recentErrorsProvider = Provider<List<AppError>>((ref) {
  final errorHandler = ref.read(errorHandlerProvider);
  return errorHandler.getRecentErrors();
});

final criticalErrorsProvider = Provider<List<AppError>>((ref) {
  final errorHandler = ref.read(errorHandlerProvider);
  return errorHandler.getErrorsBySeverity(ErrorSeverity.critical);
});
