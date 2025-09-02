import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

/// Performance tracking service for monitoring app performance
class PerformanceTracker {
  static final PerformanceTracker _instance = PerformanceTracker._internal();
  factory PerformanceTracker() => _instance;
  PerformanceTracker._internal();

  final Map<String, Stopwatch> _activeTimers = {};
  final List<PerformanceTrackerMetric> _metrics = [];
  final StreamController<PerformanceTrackerMetric> _metricsStream = 
      StreamController<PerformanceTrackerMetric>.broadcast();

  /// Stream of performance metrics
  Stream<PerformanceTrackerMetric> get metricsStream => _metricsStream.stream;

  /// Get all recorded metrics
  List<PerformanceTrackerMetric> get metrics => List.unmodifiable(_metrics);

  /// Start timing an operation
  void startTimer(String operationId, {Map<String, dynamic>? metadata}) {
    if (_activeTimers.containsKey(operationId)) {
      if (kDebugMode) {
        print('⚠️ Timer for $operationId already exists, stopping previous timer');
      }
      stopTimer(operationId);
    }

    _activeTimers[operationId] = Stopwatch()..start();
    
    if (kDebugMode) {
      print('⏱️ Started timer for: $operationId');
    }
  }

  /// Stop timing an operation and record the metric
  Duration? stopTimer(
    String operationId, {
    Map<String, dynamic>? metadata,
    bool shouldLog = true,
  }) {
    final stopwatch = _activeTimers.remove(operationId);
    if (stopwatch == null) {
      if (kDebugMode) {
        print('⚠️ No timer found for: $operationId');
      }
      return null;
    }

    stopwatch.stop();
    final duration = stopwatch.elapsed;

    final metric = PerformanceTrackerMetric(
      operationId: operationId,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _recordMetric(metric, shouldLog);
    return duration;
  }

  /// Record a metric directly (for operations you time manually)
  void recordMetric(
    String operationId,
    Duration duration, {
    Map<String, dynamic>? metadata,
    bool shouldLog = true,
  }) {
    final metric = PerformanceTrackerMetric(
      operationId: operationId,
      duration: duration,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    _recordMetric(metric, shouldLog);
  }

  /// Time a future operation
  Future<T> timeOperation<T>(
    String operationId,
    Future<T> Function() operation, {
    Map<String, dynamic>? metadata,
    bool shouldLog = true,
  }) async {
    startTimer(operationId, metadata: metadata);
    try {
      final result = await operation();
      stopTimer(operationId, metadata: metadata, shouldLog: shouldLog);
      return result;
    } catch (e) {
      stopTimer(operationId, 
        metadata: {
          ...?metadata,
          'error': e.toString(),
          'failed': true,
        }, 
        shouldLog: shouldLog,
      );
      rethrow;
    }
  }

  /// Time a synchronous operation
  T timeSync<T>(
    String operationId,
    T Function() operation, {
    Map<String, dynamic>? metadata,
    bool shouldLog = true,
  }) {
    startTimer(operationId, metadata: metadata);
    try {
      final result = operation();
      stopTimer(operationId, metadata: metadata, shouldLog: shouldLog);
      return result;
    } catch (e) {
      stopTimer(operationId, 
        metadata: {
          ...?metadata,
          'error': e.toString(),
          'failed': true,
        }, 
        shouldLog: shouldLog,
      );
      rethrow;
    }
  }

  /// Get metrics for a specific operation
  List<PerformanceTrackerMetric> getMetricsForOperation(String operationId) {
    return _metrics.where((m) => m.operationId == operationId).toList();
  }

  /// Get average duration for an operation
  Duration? getAverageDuration(String operationId) {
    final operationMetrics = getMetricsForOperation(operationId);
    if (operationMetrics.isEmpty) return null;

    final totalMs = operationMetrics
        .map((m) => m.duration.inMilliseconds)
        .reduce((a, b) => a + b);
    
    return Duration(milliseconds: totalMs ~/ operationMetrics.length);
  }

  /// Get performance summary
  PerformanceSummary getSummary() {
    final now = DateTime.now();
    final last24Hours = now.subtract(const Duration(hours: 24));
    
    final recentMetrics = _metrics
        .where((m) => m.timestamp.isAfter(last24Hours))
        .toList();

    final operationCounts = <String, int>{};
    final operationTotalDurations = <String, Duration>{};
    var slowOperations = 0;

    for (final metric in recentMetrics) {
      operationCounts[metric.operationId] = 
          (operationCounts[metric.operationId] ?? 0) + 1;
      
      final currentTotal = operationTotalDurations[metric.operationId] ?? Duration.zero;
      operationTotalDurations[metric.operationId] = currentTotal + metric.duration;

      // Consider operations > 1 second as slow
      if (metric.duration.inMilliseconds > 1000) {
        slowOperations++;
      }
    }

    return PerformanceSummary(
      totalOperations: recentMetrics.length,
      uniqueOperations: operationCounts.length,
      slowOperations: slowOperations,
      operationCounts: operationCounts,
      averageDurations: operationTotalDurations.map(
        (key, value) => MapEntry(
          key, 
          Duration(milliseconds: value.inMilliseconds ~/ operationCounts[key]!),
        ),
      ),
      timeRange: const Duration(hours: 24),
    );
  }

  /// Clear all metrics
  void clearMetrics() {
    _metrics.clear();
  }

  /// Clear metrics older than specified duration
  void clearOldMetrics([Duration maxAge = const Duration(days: 7)]) {
    final cutoff = DateTime.now().subtract(maxAge);
    _metrics.removeWhere((metric) => metric.timestamp.isBefore(cutoff));
  }

  void _recordMetric(PerformanceTrackerMetric metric, bool shouldLog) {
    _metrics.add(metric);
    
    // Keep only last 1000 metrics to prevent memory leaks
    if (_metrics.length > 1000) {
      _metrics.removeAt(0);
    }

    if (shouldLog && kDebugMode) {
      final duration = metric.duration.inMilliseconds;
      final emoji = duration > 1000 ? '🐌' : duration > 500 ? '⚠️' : '⚡';
      print('$emoji Performance: ${metric.operationId} took ${duration}ms');
    }

    _metricsStream.add(metric);
  }

  /// Dispose resources
  void dispose() {
    _activeTimers.clear();
    _metricsStream.close();
  }
}

/// Performance metric model for tracking operations
class PerformanceTrackerMetric {
  final String operationId;
  final Duration duration;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const PerformanceTrackerMetric({
    required this.operationId,
    required this.duration,
    required this.timestamp,
    required this.metadata,
  });

  @override
  String toString() {
    return 'PerformanceTrackerMetric(operation: $operationId, duration: ${duration.inMilliseconds}ms)';
  }

  Map<String, dynamic> toJson() {
    return {
      'operationId': operationId,
      'durationMs': duration.inMilliseconds,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}

/// Performance summary model
class PerformanceSummary {
  final int totalOperations;
  final int uniqueOperations;
  final int slowOperations;
  final Map<String, int> operationCounts;
  final Map<String, Duration> averageDurations;
  final Duration timeRange;

  const PerformanceSummary({
    required this.totalOperations,
    required this.uniqueOperations,
    required this.slowOperations,
    required this.operationCounts,
    required this.averageDurations,
    required this.timeRange,
  });

  @override
  String toString() {
    return 'PerformanceSummary(total: $totalOperations, unique: $uniqueOperations, slow: $slowOperations)';
  }
}

/// Riverpod providers for performance tracking
final performanceTrackerProvider = Provider<PerformanceTracker>((ref) {
  return PerformanceTracker();
});

final performanceMetricsStreamProvider = StreamProvider<PerformanceTrackerMetric>((ref) {
  final tracker = ref.read(performanceTrackerProvider);
  return tracker.metricsStream;
});

final performanceSummaryProvider = Provider<PerformanceSummary>((ref) {
  final tracker = ref.read(performanceTrackerProvider);
  return tracker.getSummary();
});
