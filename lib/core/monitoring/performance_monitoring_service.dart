import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

/// Performance metric types
enum PerformanceMetricType {
  screenLoad,
  networkRequest,
  databaseOperation,
  computation,
  userInteraction,
  memoryUsage,
  batteryUsage,
}

/// Performance metric model
class PerformanceMetric {
  final String id;
  final PerformanceMetricType type;
  final String name;
  final Duration duration;
  final DateTime startTime;
  final DateTime endTime;
  final Map<String, dynamic> attributes;
  final double? value;
  final String? unit;

  const PerformanceMetric({
    required this.id,
    required this.type,
    required this.name,
    required this.duration,
    required this.startTime,
    required this.endTime,
    this.attributes = const {},
    this.value,
    this.unit,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'duration': duration.inMilliseconds,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'attributes': attributes,
      'value': value,
      'unit': unit,
    };
  }

  factory PerformanceMetric.fromJson(Map<String, dynamic> json) {
    return PerformanceMetric(
      id: json['id'] as String,
      type: PerformanceMetricType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PerformanceMetricType.computation,
      ),
      name: json['name'] as String,
      duration: Duration(milliseconds: json['duration'] as int),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      attributes: Map<String, dynamic>.from(json['attributes'] as Map? ?? {}),
      value: (json['value'] as num?)?.toDouble(),
      unit: json['unit'] as String?,
    );
  }
}

/// Performance trace wrapper
class PerformanceTrace {
  final Trace _firebaseTrace;
  final String name;
  final DateTime startTime;
  final Map<String, String> _attributes = {};
  final Map<String, int> _metrics = {};
  bool _isStopped = false;

  PerformanceTrace._(this._firebaseTrace, this.name, this.startTime);

  /// Create and start a performance trace
  static Future<PerformanceTrace> create(String name) async {
    final trace = FirebasePerformance.instance.newTrace(name);
    await trace.start();
    return PerformanceTrace._(trace, name, DateTime.now());
  }

  /// Set custom attribute
  void setAttribute(String name, String value) {
    if (!_isStopped) {
      _attributes[name] = value;
      _firebaseTrace.setCustomAttribute(name, value);
    }
  }

  /// Set custom metric
  void setMetric(String name, int value) {
    if (!_isStopped) {
      _metrics[name] = value;
      _firebaseTrace.setMetric(name, value);
    }
  }

  /// Increment metric
  void incrementMetric(String name, [int value = 1]) {
    if (!_isStopped) {
      _metrics[name] = (_metrics[name] ?? 0) + value;
      _firebaseTrace.incrementMetric(name, value);
    }
  }

  /// Stop the trace
  Future<PerformanceMetric> stop() async {
    if (_isStopped) {
      throw StateError('Trace already stopped');
    }

    _isStopped = true;
    final endTime = DateTime.now();
    await _firebaseTrace.stop();

    return PerformanceMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: PerformanceMetricType.computation,
      name: name,
      duration: endTime.difference(startTime),
      startTime: startTime,
      endTime: endTime,
      attributes: Map<String, dynamic>.from(_attributes),
    );
  }

  /// Get current duration
  Duration get currentDuration => DateTime.now().difference(startTime);

  /// Check if trace is stopped
  bool get isStopped => _isStopped;
}

/// Performance monitoring service
class PerformanceMonitoringService {
  static const String _performanceMetricsKey = 'performance_metrics';
  static const String _performanceConfigKey = 'performance_config';

  final SharedPreferences _prefs;
  bool _isInitialized = false;
  bool _performanceMonitoringEnabled = true;

  // Local metrics storage
  final List<PerformanceMetric> _localMetrics = [];
  final Map<String, PerformanceTrace> _activeTraces = {};

  // Performance thresholds (in milliseconds)
  static const Map<PerformanceMetricType, int> _performanceThresholds = {
    PerformanceMetricType.screenLoad: 2000,
    PerformanceMetricType.networkRequest: 5000,
    PerformanceMetricType.databaseOperation: 1000,
    PerformanceMetricType.computation: 500,
    PerformanceMetricType.userInteraction: 100,
  };

  PerformanceMonitoringService(this._prefs);

  /// Initialize performance monitoring
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Load configuration
      await _loadPerformanceConfiguration();

      if (_performanceMonitoringEnabled) {
        // Initialize Firebase Performance
        await _initializeFirebasePerformance();

        // Load local metrics
        await _loadLocalMetrics();

        // Start automatic monitoring
        _startAutomaticMonitoring();
      }

      _isInitialized = true;

      if (kDebugMode) {
        print('Performance monitoring initialized successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing performance monitoring: $e');
      }
    }
  }

  /// Initialize Firebase Performance
  Future<void> _initializeFirebasePerformance() async {
    try {
      // Enable/disable performance monitoring
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        _performanceMonitoringEnabled && !kDebugMode,
      );

      if (kDebugMode) {
        print('Firebase Performance initialized');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error initializing Firebase Performance: $e');
      }
    }
  }

  /// Load performance configuration
  Future<void> _loadPerformanceConfiguration() async {
    try {
      final configString = _prefs.getString(_performanceConfigKey);
      if (configString != null) {
        final config = jsonDecode(configString) as Map<String, dynamic>;
        _performanceMonitoringEnabled = config['enabled'] as bool? ?? true;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading performance configuration: $e');
      }
    }
  }

  /// Load local metrics
  Future<void> _loadLocalMetrics() async {
    try {
      final metricsString = _prefs.getString(_performanceMetricsKey);
      if (metricsString != null) {
        final metricsList = jsonDecode(metricsString) as List;
        _localMetrics.clear();
        _localMetrics.addAll(
          metricsList.map(
            (metric) =>
                PerformanceMetric.fromJson(metric as Map<String, dynamic>),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error loading local metrics: $e');
      }
    }
  }

  /// Start automatic monitoring
  void _startAutomaticMonitoring() {
    // Monitor app startup
    _measureAppStartup();

    // Monitor memory usage periodically
    Timer.periodic(const Duration(minutes: 5), (_) {
      _measureMemoryUsage();
    });
  }

  /// Measure app startup time
  void _measureAppStartup() async {
    final trace = await PerformanceTrace.create('app_startup');
    trace.setAttribute('startup_type', 'cold');

    // Simulate app startup completion
    await Future.delayed(const Duration(milliseconds: 100));

    final metric = await trace.stop();
    _recordLocalMetric(metric.copyWith(type: PerformanceMetricType.screenLoad));
  }

  /// Measure memory usage
  void _measureMemoryUsage() {
    // This is a placeholder - you would use actual memory monitoring
    final memoryUsage = 50.0; // MB

    final metric = PerformanceMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: PerformanceMetricType.memoryUsage,
      name: 'memory_usage',
      duration: Duration.zero,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      value: memoryUsage,
      unit: 'MB',
      attributes: {'timestamp': DateTime.now().toIso8601String()},
    );

    _recordLocalMetric(metric);
  }

  /// Start performance trace
  Future<String> startTrace(
    String name, {
    Map<String, String>? attributes,
  }) async {
    if (!_isInitialized || !_performanceMonitoringEnabled) {
      return '';
    }

    try {
      final trace = await PerformanceTrace.create(name);
      final traceId = DateTime.now().millisecondsSinceEpoch.toString();

      // Set attributes
      attributes?.forEach((key, value) {
        trace.setAttribute(key, value);
      });

      _activeTraces[traceId] = trace;

      if (kDebugMode) {
        print('Started performance trace: $name');
      }

      return traceId;
    } catch (e) {
      if (kDebugMode) {
        print('Error starting trace: $e');
      }
      return '';
    }
  }

  /// Stop performance trace
  Future<PerformanceMetric?> stopTrace(String traceId) async {
    if (!_activeTraces.containsKey(traceId)) {
      return null;
    }

    try {
      final trace = _activeTraces[traceId]!;
      final metric = await trace.stop();
      _activeTraces.remove(traceId);

      // Check if performance is below threshold
      _checkPerformanceThreshold(metric);

      // Record locally
      _recordLocalMetric(metric);

      if (kDebugMode) {
        print(
          'Stopped performance trace: ${trace.name} - ${metric.duration.inMilliseconds}ms',
        );
      }

      return metric;
    } catch (e) {
      if (kDebugMode) {
        print('Error stopping trace: $e');
      }
      return null;
    }
  }

  /// Measure screen load time
  Future<PerformanceMetric> measureScreenLoad(
    String screenName,
    Future<void> Function() loadFunction,
  ) async {
    final startTime = DateTime.now();
    final traceId = await startTrace(
      'screen_load_$screenName',
      attributes: {'screen_name': screenName},
    );

    try {
      await loadFunction();
    } finally {
      final metric = await stopTrace(traceId);
      return metric ??
          PerformanceMetric(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            type: PerformanceMetricType.screenLoad,
            name: 'screen_load_$screenName',
            duration: DateTime.now().difference(startTime),
            startTime: startTime,
            endTime: DateTime.now(),
            attributes: {'screen_name': screenName},
          );
    }
  }

  /// Measure network request
  Future<T> measureNetworkRequest<T>(
    String requestName,
    Future<T> Function() requestFunction, {
    String? url,
    String? method,
  }) async {
    final traceId = await startTrace(
      'network_$requestName',
      attributes: {'url': url ?? 'unknown', 'method': method ?? 'GET'},
    );

    try {
      final result = await requestFunction();
      final trace = _activeTraces[traceId];
      trace?.setAttribute('status', 'success');
      return result;
    } catch (e) {
      final trace = _activeTraces[traceId];
      trace?.setAttribute('status', 'error');
      trace?.setAttribute('error', e.toString());
      rethrow;
    } finally {
      await stopTrace(traceId);
    }
  }

  /// Measure database operation
  Future<T> measureDatabaseOperation<T>(
    String operationName,
    Future<T> Function() operationFunction, {
    String? table,
    String? operation,
  }) async {
    final traceId = await startTrace(
      'db_$operationName',
      attributes: {
        'table': table ?? 'unknown',
        'operation': operation ?? 'query',
      },
    );

    try {
      final result = await operationFunction();
      final trace = _activeTraces[traceId];
      trace?.setAttribute('status', 'success');
      return result;
    } catch (e) {
      final trace = _activeTraces[traceId];
      trace?.setAttribute('status', 'error');
      trace?.setAttribute('error', e.toString());
      rethrow;
    } finally {
      await stopTrace(traceId);
    }
  }

  /// Record custom metric
  void recordCustomMetric({
    required String name,
    required double value,
    String? unit,
    Map<String, dynamic>? attributes,
  }) {
    if (!_isInitialized || !_performanceMonitoringEnabled) return;

    final metric = PerformanceMetric(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: PerformanceMetricType.computation,
      name: name,
      duration: Duration.zero,
      startTime: DateTime.now(),
      endTime: DateTime.now(),
      value: value,
      unit: unit,
      attributes: attributes ?? {},
    );

    _recordLocalMetric(metric);
  }

  /// Check performance threshold
  void _checkPerformanceThreshold(PerformanceMetric metric) {
    final threshold = _performanceThresholds[metric.type];
    if (threshold != null && metric.duration.inMilliseconds > threshold) {
      if (kDebugMode) {
        print(
          'Performance threshold exceeded: ${metric.name} took ${metric.duration.inMilliseconds}ms (threshold: ${threshold}ms)',
        );
      }

      // You could send this to your crash reporting service
      // crashReportingService.reportError(
      //   error: 'Performance threshold exceeded',
      //   severity: CrashSeverity.medium,
      //   customData: metric.toJson(),
      // );
    }
  }

  /// Record local metric
  void _recordLocalMetric(PerformanceMetric metric) {
    _localMetrics.add(metric);
    _saveLocalMetrics();

    // Keep only last 500 metrics locally
    if (_localMetrics.length > 500) {
      _localMetrics.removeRange(0, _localMetrics.length - 500);
    }
  }

  /// Save local metrics
  Future<void> _saveLocalMetrics() async {
    try {
      final metricsJson = jsonEncode(
        _localMetrics.map((metric) => metric.toJson()).toList(),
      );
      await _prefs.setString(_performanceMetricsKey, metricsJson);
    } catch (e) {
      if (kDebugMode) {
        print('Error saving local metrics: $e');
      }
    }
  }

  /// Get performance analytics
  Future<Map<String, dynamic>> getPerformanceAnalytics() async {
    final totalMetrics = _localMetrics.length;

    final metricsByType = <String, List<PerformanceMetric>>{};
    for (final metric in _localMetrics) {
      metricsByType.putIfAbsent(metric.type.name, () => []).add(metric);
    }

    final averageDurations = <String, double>{};
    final maxDurations = <String, int>{};
    final minDurations = <String, int>{};

    metricsByType.forEach((type, metrics) {
      if (metrics.isNotEmpty) {
        final durations = metrics
            .map((m) => m.duration.inMilliseconds)
            .toList();
        averageDurations[type] =
            durations.reduce((a, b) => a + b) / durations.length;
        maxDurations[type] = durations.reduce((a, b) => a > b ? a : b);
        minDurations[type] = durations.reduce((a, b) => a < b ? a : b);
      }
    });

    final recentMetrics = _localMetrics
        .where(
          (m) => m.startTime.isAfter(
            DateTime.now().subtract(const Duration(hours: 24)),
          ),
        )
        .length;

    return {
      'totalMetrics': totalMetrics,
      'recentMetrics': recentMetrics,
      'metricsByType': metricsByType.map((k, v) => MapEntry(k, v.length)),
      'averageDurations': averageDurations,
      'maxDurations': maxDurations,
      'minDurations': minDurations,
      'activeTraces': _activeTraces.length,
    };
  }

  /// Enable/disable performance monitoring
  Future<void> setPerformanceMonitoringEnabled(bool enabled) async {
    _performanceMonitoringEnabled = enabled;

    final config = {'enabled': enabled};
    await _prefs.setString(_performanceConfigKey, jsonEncode(config));

    if (_isInitialized) {
      await FirebasePerformance.instance.setPerformanceCollectionEnabled(
        enabled,
      );
    }
  }

  /// Get local metrics
  List<PerformanceMetric> getLocalMetrics({
    int? limit,
    PerformanceMetricType? type,
  }) {
    var metrics = List<PerformanceMetric>.from(_localMetrics);

    if (type != null) {
      metrics = metrics.where((m) => m.type == type).toList();
    }

    metrics.sort((a, b) => b.startTime.compareTo(a.startTime));

    if (limit != null && limit < metrics.length) {
      return metrics.take(limit).toList();
    }

    return metrics;
  }

  /// Clear local metrics
  Future<void> clearLocalMetrics() async {
    _localMetrics.clear();
    await _prefs.remove(_performanceMetricsKey);
  }

  /// Stop all active traces
  Future<void> stopAllActiveTraces() async {
    final traceIds = List<String>.from(_activeTraces.keys);
    for (final traceId in traceIds) {
      await stopTrace(traceId);
    }
  }
}

extension PerformanceMetricExtension on PerformanceMetric {
  PerformanceMetric copyWith({
    String? id,
    PerformanceMetricType? type,
    String? name,
    Duration? duration,
    DateTime? startTime,
    DateTime? endTime,
    Map<String, dynamic>? attributes,
    double? value,
    String? unit,
  }) {
    return PerformanceMetric(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      duration: duration ?? this.duration,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      attributes: attributes ?? this.attributes,
      value: value ?? this.value,
      unit: unit ?? this.unit,
    );
  }
}

/// Riverpod providers for performance monitoring
final performanceMonitoringServiceProvider =
    Provider<PerformanceMonitoringService>((ref) {
      throw UnimplementedError(
        'PerformanceMonitoringService must be overridden',
      );
    });

final performanceAnalyticsProvider = FutureProvider<Map<String, dynamic>>((
  ref,
) async {
  final performanceService = ref.watch(performanceMonitoringServiceProvider);
  return await performanceService.getPerformanceAnalytics();
});
