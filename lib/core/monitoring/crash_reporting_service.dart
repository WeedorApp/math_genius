import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Crash severity levels
enum CrashSeverity { low, medium, high, critical }

/// Error context model
class ErrorContext {
  final String userId;
  final String screenName;
  final String action;
  final Map<String, dynamic> metadata;
  final DateTime timestamp;
  final String deviceInfo;
  final String appVersion;

  const ErrorContext({
    required this.userId,
    required this.screenName,
    required this.action,
    required this.metadata,
    required this.timestamp,
    required this.deviceInfo,
    required this.appVersion,
  });

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'screenName': screenName,
      'action': action,
      'metadata': metadata,
      'timestamp': timestamp.toIso8601String(),
      'deviceInfo': deviceInfo,
      'appVersion': appVersion,
    };
  }

  factory ErrorContext.fromJson(Map<String, dynamic> json) {
    return ErrorContext(
      userId: json['userId'] as String,
      screenName: json['screenName'] as String,
      action: json['action'] as String,
      metadata: Map<String, dynamic>.from(json['metadata'] as Map),
      timestamp: DateTime.parse(json['timestamp'] as String),
      deviceInfo: json['deviceInfo'] as String,
      appVersion: json['appVersion'] as String,
    );
  }
}

/// Crash report model
class CrashReport {
  final String id;
  final String error;
  final String? stackTrace;
  final CrashSeverity severity;
  final ErrorContext context;
  final bool isFatal;
  final Map<String, dynamic> customData;

  const CrashReport({
    required this.id,
    required this.error,
    this.stackTrace,
    required this.severity,
    required this.context,
    this.isFatal = false,
    this.customData = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'error': error,
      'stackTrace': stackTrace,
      'severity': severity.name,
      'context': context.toJson(),
      'isFatal': isFatal,
      'customData': customData,
    };
  }

  factory CrashReport.fromJson(Map<String, dynamic> json) {
    return CrashReport(
      id: json['id'] as String,
      error: json['error'] as String,
      stackTrace: json['stackTrace'] as String?,
      severity: CrashSeverity.values.firstWhere(
        (e) => e.name == json['severity'],
        orElse: () => CrashSeverity.medium,
      ),
      context: ErrorContext.fromJson(json['context'] as Map<String, dynamic>),
      isFatal: json['isFatal'] as bool? ?? false,
      customData: Map<String, dynamic>.from(json['customData'] as Map? ?? {}),
    );
  }
}

/// Comprehensive crash reporting service
class CrashReportingService {
  static const String _crashReportsKey = 'crash_reports';
  static const String _crashConfigKey = 'crash_config';

  final SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _crashReportingEnabled = true;
  String _currentUserId = 'anonymous';
  String _currentScreenName = 'unknown';

  // Local crash report storage
  final List<CrashReport> _localCrashReports = [];

  CrashReportingService(this._prefs);

  /// Initialize crash reporting services
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load configuration
      await _loadCrashConfiguration();

      if (_crashReportingEnabled) {
        // Initialize Firebase Crashlytics
        await _initializeFirebaseCrashlytics();

        // Initialize Sentry
        await _initializeSentry();

        // Set up Flutter error handling
        _setupFlutterErrorHandling();

        // Load local crash reports
        await _loadLocalCrashReports();
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('Crash reporting initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing crash reporting: $e');
      }
    }
  }

  /// Initialize Firebase Crashlytics
  Future<void> _initializeFirebaseCrashlytics() async {
    try {
      // Set Crashlytics collection enabled
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        _crashReportingEnabled && !kDebugMode,
      );

      // Set user identifier
      if (_currentUserId != 'anonymous') {
        await FirebaseCrashlytics.instance.setUserIdentifier(_currentUserId);
      }

      if (kDebugMode) {
        print('Firebase Crashlytics initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Crashlytics: $e');
      }
    }
  }

  /// Initialize Sentry
  Future<void> _initializeSentry() async {
    try {
      await SentryFlutter.init((options) {
        options.dsn = 'YOUR_SENTRY_DSN'; // Replace with your Sentry DSN
        options.debug = kDebugMode;
        options.environment = kDebugMode ? 'development' : 'production';
        options.release = '1.0.0'; // Replace with your app version
        options.tracesSampleRate = 0.1;
        options.enableAutoSessionTracking = true;
        options.attachStacktrace = true;
        options.sendDefaultPii = false; // Respect privacy

        // Filter out sensitive information
        options.beforeSend = (event, hint) {
          // Remove sensitive data
          event = event.copyWith(
            user: event.user?.copyWith(email: null, ipAddress: null),
          );
          return event;
        };
      });

      // Set user context
      if (_currentUserId != 'anonymous') {
        Sentry.configureScope((scope) {
          scope.setUser(SentryUser(id: _currentUserId));
        });
      }

      if (kDebugMode) {
        print('Sentry initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Sentry: $e');
      }
    }
  }

  /// Set up Flutter error handling
  void _setupFlutterErrorHandling() {
    // Capture Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) {
      // Report to Firebase Crashlytics
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);

      // Report to Sentry
      Sentry.captureException(details.exception, stackTrace: details.stack);

      // Store locally
      _recordLocalCrash(
        error: details.exception.toString(),
        stackTrace: details.stack.toString(),
        severity: CrashSeverity.high,
        isFatal: true,
      );

      if (kDebugMode) {
        FlutterError.presentError(details);
      }
    };

    // Capture async errors
    PlatformDispatcher.instance.onError = (error, stack) {
      // Report to Firebase Crashlytics
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);

      // Report to Sentry
      Sentry.captureException(error, stackTrace: stack);

      // Store locally
      _recordLocalCrash(
        error: error.toString(),
        stackTrace: stack.toString(),
        severity: CrashSeverity.critical,
        isFatal: true,
      );

      return true;
    };
  }

  /// Load crash configuration
  Future<void> _loadCrashConfiguration() async {
    try {
      final configString = _prefs.getString(_crashConfigKey);
      if (configString != null) {
        final config = jsonDecode(configString) as Map<String, dynamic>;
        _crashReportingEnabled = config['enabled'] as bool? ?? true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading crash configuration: $e');
      }
    }
  }

  /// Load local crash reports
  Future<void> _loadLocalCrashReports() async {
    try {
      final reportsString = _prefs.getString(_crashReportsKey);
      if (reportsString != null) {
        final reportsList = jsonDecode(reportsString) as List;
        _localCrashReports.clear();
        _localCrashReports.addAll(
          reportsList.map(
            (report) => CrashReport.fromJson(report as Map<String, dynamic>),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading local crash reports: $e');
      }
    }
  }

  /// Record local crash
  void _recordLocalCrash({
    required String error,
    String? stackTrace,
    required CrashSeverity severity,
    bool isFatal = false,
    Map<String, dynamic> customData = const {},
  }) {
    final crashReport = CrashReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      error: error,
      stackTrace: stackTrace,
      severity: severity,
      context: _getCurrentErrorContext(),
      isFatal: isFatal,
      customData: customData,
    );

    _localCrashReports.add(crashReport);
    _saveLocalCrashReports();

    // Keep only last 100 crash reports locally
    if (_localCrashReports.length > 100) {
      _localCrashReports.removeRange(0, _localCrashReports.length - 100);
    }
  }

  /// Get current error context
  ErrorContext _getCurrentErrorContext() {
    return ErrorContext(
      userId: _currentUserId,
      screenName: _currentScreenName,
      action: 'unknown',
      metadata: {
        'platform': defaultTargetPlatform.name,
        'isDebugMode': kDebugMode,
        'timestamp': DateTime.now().toIso8601String(),
      },
      timestamp: DateTime.now(),
      deviceInfo: _getDeviceInfo(),
      appVersion: '1.0.0', // Replace with actual version
    );
  }

  /// Get device information
  String _getDeviceInfo() {
    // This is a simplified version - you might want to use device_info_plus
    return '${defaultTargetPlatform.name} device';
  }

  /// Save local crash reports
  Future<void> _saveLocalCrashReports() async {
    try {
      final reportsJson = jsonEncode(
        _localCrashReports.map((report) => report.toJson()).toList(),
      );
      await _prefs.setString(_crashReportsKey, reportsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving local crash reports: $e');
      }
    }
  }

  /// Set current user
  Future<void> setUser(String userId) async {
    _currentUserId = userId;

    if (_isInitialized && _crashReportingEnabled) {
      // Update Firebase Crashlytics
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);

      // Update Sentry
      Sentry.configureScope((scope) {
        scope.setUser(SentryUser(id: userId));
      });
    }
  }

  /// Set current screen
  void setCurrentScreen(String screenName) {
    _currentScreenName = screenName;

    if (_isInitialized && _crashReportingEnabled) {
      // Set custom key in Crashlytics
      FirebaseCrashlytics.instance.setCustomKey('current_screen', screenName);

      // Add breadcrumb in Sentry
      Sentry.addBreadcrumb(
        Breadcrumb(
          message: 'Screen changed to $screenName',
          category: 'navigation',
          level: SentryLevel.info,
        ),
      );
    }
  }

  /// Report custom error
  Future<void> reportError({
    required String error,
    String? stackTrace,
    CrashSeverity severity = CrashSeverity.medium,
    Map<String, dynamic> customData = const {},
    bool isFatal = false,
  }) async {
    if (!_isInitialized || !_crashReportingEnabled) return;

    try {
      // Report to Firebase Crashlytics
      await FirebaseCrashlytics.instance.recordError(
        error,
        stackTrace != null ? StackTrace.fromString(stackTrace) : null,
        fatal: isFatal,
        information: customData.entries
            .map((e) => '${e.key}: ${e.value}')
            .toList(),
      );

      // Report to Sentry
      await Sentry.captureException(
        Exception(error),
        stackTrace: stackTrace != null
            ? StackTrace.fromString(stackTrace)
            : null,
        withScope: (scope) {
          scope.setLevel(_mapSeverityToSentryLevel(severity));
          customData.forEach((key, value) {
            scope.setExtra(key, value);
          });
        },
      );

      // Store locally
      _recordLocalCrash(
        error: error,
        stackTrace: stackTrace,
        severity: severity,
        isFatal: isFatal,
        customData: customData,
      );

      if (kDebugMode) {
        print('Error reported: $error');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error reporting crash: $e');
      }
    }
  }

  /// Map severity to Sentry level
  SentryLevel _mapSeverityToSentryLevel(CrashSeverity severity) {
    switch (severity) {
      case CrashSeverity.low:
        return SentryLevel.info;
      case CrashSeverity.medium:
        return SentryLevel.warning;
      case CrashSeverity.high:
        return SentryLevel.error;
      case CrashSeverity.critical:
        return SentryLevel.fatal;
    }
  }

  /// Add breadcrumb for debugging
  void addBreadcrumb({
    required String message,
    String category = 'custom',
    Map<String, dynamic>? data,
  }) {
    if (!_isInitialized || !_crashReportingEnabled) return;

    // Add to Firebase Crashlytics as custom key
    FirebaseCrashlytics.instance.setCustomKey('breadcrumb', message);

    // Add to Sentry
    Sentry.addBreadcrumb(
      Breadcrumb(
        message: message,
        category: category,
        data: data,
        level: SentryLevel.info,
      ),
    );
  }

  /// Set custom data
  Future<void> setCustomData(String key, dynamic value) async {
    if (!_isInitialized || !_crashReportingEnabled) return;

    // Set in Firebase Crashlytics
    await FirebaseCrashlytics.instance.setCustomKey(key, value);

    // Set in Sentry
    Sentry.configureScope((scope) {
      scope.setExtra(key, value);
    });
  }

  /// Get crash analytics
  Future<Map<String, dynamic>> getCrashAnalytics() async {
    final totalCrashes = _localCrashReports.length;
    final fatalCrashes = _localCrashReports.where((c) => c.isFatal).length;

    final severityBreakdown = <String, int>{};
    for (final crash in _localCrashReports) {
      severityBreakdown[crash.severity.name] =
          (severityBreakdown[crash.severity.name] ?? 0) + 1;
    }

    final recentCrashes = _localCrashReports
        .where(
          (c) => c.context.timestamp.isAfter(
            DateTime.now().subtract(const Duration(days: 7)),
          ),
        )
        .length;

    return {
      'totalCrashes': totalCrashes,
      'fatalCrashes': fatalCrashes,
      'nonFatalCrashes': totalCrashes - fatalCrashes,
      'recentCrashes': recentCrashes,
      'severityBreakdown': severityBreakdown,
      'crashRate': totalCrashes > 0 ? (fatalCrashes / totalCrashes * 100) : 0.0,
    };
  }

  /// Enable/disable crash reporting
  Future<void> setCrashReportingEnabled(bool enabled) async {
    _crashReportingEnabled = enabled;

    final config = {'enabled': enabled};
    await _prefs.setString(_crashConfigKey, jsonEncode(config));

    if (_isInitialized) {
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
        enabled,
      );
    }
  }

  /// Get local crash reports
  List<CrashReport> getLocalCrashReports({int? limit}) {
    final reports = List<CrashReport>.from(_localCrashReports);
    reports.sort((a, b) => b.context.timestamp.compareTo(a.context.timestamp));

    if (limit != null && limit < reports.length) {
      return reports.take(limit).toList();
    }

    return reports;
  }

  /// Clear local crash reports
  Future<void> clearLocalCrashReports() async {
    _localCrashReports.clear();
    await _prefs.remove(_crashReportsKey);
  }

  /// Test crash reporting (debug only)
  Future<void> testCrash() async {
    if (!kDebugMode) return;

    await reportError(
      error: 'Test crash report',
      severity: CrashSeverity.low,
      customData: {'test': true, 'timestamp': DateTime.now().toIso8601String()},
    );
  }
}

/// Riverpod providers for crash reporting
final crashReportingServiceProvider = Provider<CrashReportingService>((ref) {
  throw UnimplementedError('CrashReportingService must be overridden');
});

final crashAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final crashService = ref.watch(crashReportingServiceProvider);
  return await crashService.getCrashAnalytics();
});
