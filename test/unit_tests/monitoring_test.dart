import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:math_genius/core/monitoring/barrel.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  group('Crash Reporting Service Tests', () {
    late CrashReportingService crashService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      crashService = CrashReportingService(mockPrefs);
    });

    test('should create crash report correctly', () {
      final context = ErrorContext(
        userId: 'user_123',
        screenName: 'GameScreen',
        action: 'answer_question',
        metadata: {'question_id': 'q_456'},
        timestamp: DateTime.now(),
        deviceInfo: 'iOS 16.0',
        appVersion: '1.0.0',
      );

      final crashReport = CrashReport(
        id: 'crash_123',
        error: 'Null pointer exception',
        stackTrace: 'Stack trace here...',
        severity: CrashSeverity.high,
        context: context,
        isFatal: false,
        customData: {'additional': 'data'},
      );

      expect(crashReport.id, equals('crash_123'));
      expect(crashReport.error, equals('Null pointer exception'));
      expect(crashReport.severity, equals(CrashSeverity.high));
      expect(crashReport.context.userId, equals('user_123'));
      expect(crashReport.isFatal, isFalse);
    });

    test('should serialize and deserialize crash report', () {
      final originalContext = ErrorContext(
        userId: 'user_123',
        screenName: 'HomeScreen',
        action: 'load_content',
        metadata: {'content_type': 'math_problems'},
        timestamp: DateTime.now(),
        deviceInfo: 'Android 12',
        appVersion: '1.0.0',
      );

      final originalCrash = CrashReport(
        id: 'crash_456',
        error: 'Network timeout',
        severity: CrashSeverity.medium,
        context: originalContext,
        isFatal: false,
      );

      final json = originalCrash.toJson();
      final deserializedCrash = CrashReport.fromJson(json);

      expect(deserializedCrash.id, equals(originalCrash.id));
      expect(deserializedCrash.error, equals(originalCrash.error));
      expect(deserializedCrash.severity, equals(originalCrash.severity));
      expect(deserializedCrash.context.userId, equals(originalCrash.context.userId));
    });

    test('should calculate crash analytics correctly', () async {
      // Mock local crash reports
      when(mockPrefs.getString('crash_reports')).thenReturn('[]');
      
      final analytics = await crashService.getCrashAnalytics();
      
      expect(analytics['totalCrashes'], equals(0));
      expect(analytics['fatalCrashes'], equals(0));
      expect(analytics['recentCrashes'], equals(0));
      expect(analytics['crashRate'], equals(0.0));
    });
  });

  group('Performance Monitoring Service Tests', () {
    late PerformanceMonitoringService performanceService;
    late MockSharedPreferences mockPrefs;

    setUp(() {
      mockPrefs = MockSharedPreferences();
      performanceService = PerformanceMonitoringService(mockPrefs);
    });

    test('should create performance metric correctly', () {
      final metric = PerformanceMetric(
        id: 'metric_123',
        type: PerformanceMetricType.screenLoad,
        name: 'HomeScreen Load',
        duration: const Duration(milliseconds: 1500),
        startTime: DateTime.now().subtract(const Duration(milliseconds: 1500)),
        endTime: DateTime.now(),
        attributes: {'screen_name': 'HomeScreen'},
        value: 1500.0,
        unit: 'ms',
      );

      expect(metric.id, equals('metric_123'));
      expect(metric.type, equals(PerformanceMetricType.screenLoad));
      expect(metric.duration.inMilliseconds, equals(1500));
      expect(metric.attributes['screen_name'], equals('HomeScreen'));
    });

    test('should serialize and deserialize performance metric', () {
      final originalMetric = PerformanceMetric(
        id: 'metric_456',
        type: PerformanceMetricType.networkRequest,
        name: 'API Call',
        duration: const Duration(milliseconds: 2000),
        startTime: DateTime.now().subtract(const Duration(milliseconds: 2000)),
        endTime: DateTime.now(),
        attributes: {'endpoint': '/api/problems', 'method': 'GET'},
        value: 2000.0,
        unit: 'ms',
      );

      final json = originalMetric.toJson();
      final deserializedMetric = PerformanceMetric.fromJson(json);

      expect(deserializedMetric.id, equals(originalMetric.id));
      expect(deserializedMetric.type, equals(originalMetric.type));
      expect(deserializedMetric.duration, equals(originalMetric.duration));
      expect(deserializedMetric.attributes['endpoint'], equals('/api/problems'));
    });

    test('should calculate performance analytics correctly', () async {
      // Mock empty metrics
      when(mockPrefs.getString('performance_metrics')).thenReturn('[]');
      
      final analytics = await performanceService.getPerformanceAnalytics();
      
      expect(analytics['totalMetrics'], equals(0));
      expect(analytics['recentMetrics'], equals(0));
      expect(analytics['activeTraces'], equals(0));
    });

    test('should measure screen load time', () async {
      bool loadFunctionCalled = false;
      
      final metric = await performanceService.measureScreenLoad(
        'TestScreen',
        () async {
          loadFunctionCalled = true;
          await Future.delayed(const Duration(milliseconds: 100));
        },
      );

      expect(loadFunctionCalled, isTrue);
      expect(metric.name, equals('screen_load_TestScreen'));
      expect(metric.type, equals(PerformanceMetricType.screenLoad));
      expect(metric.duration.inMilliseconds, greaterThan(90));
    });

    test('should measure network request time', () async {
      bool requestFunctionCalled = false;
      const expectedResult = 'success';
      
      final result = await performanceService.measureNetworkRequest(
        'test_request',
        () async {
          requestFunctionCalled = true;
          await Future.delayed(const Duration(milliseconds: 50));
          return expectedResult;
        },
        url: 'https://api.example.com/test',
        method: 'POST',
      );

      expect(requestFunctionCalled, isTrue);
      expect(result, equals(expectedResult));
    });

    test('should measure database operation time', () async {
      bool operationFunctionCalled = false;
      const expectedResult = {'id': 1, 'name': 'test'};
      
      final result = await performanceService.measureDatabaseOperation(
        'test_query',
        () async {
          operationFunctionCalled = true;
          await Future.delayed(const Duration(milliseconds: 25));
          return expectedResult;
        },
        table: 'users',
        operation: 'SELECT',
      );

      expect(operationFunctionCalled, isTrue);
      expect(result, equals(expectedResult));
    });
  });

  group('Error Context Tests', () {
    test('should create error context with all required fields', () {
      final context = ErrorContext(
        userId: 'user_789',
        screenName: 'SettingsScreen',
        action: 'save_preferences',
        metadata: {
          'theme': 'dark',
          'language': 'en',
          'notifications': true,
        },
        timestamp: DateTime.now(),
        deviceInfo: 'iPhone 14 Pro',
        appVersion: '1.2.0',
      );

      expect(context.userId, equals('user_789'));
      expect(context.screenName, equals('SettingsScreen'));
      expect(context.action, equals('save_preferences'));
      expect(context.metadata['theme'], equals('dark'));
      expect(context.deviceInfo, equals('iPhone 14 Pro'));
      expect(context.appVersion, equals('1.2.0'));
    });

    test('should serialize and deserialize error context', () {
      final originalContext = ErrorContext(
        userId: 'user_101',
        screenName: 'GameScreen',
        action: 'submit_answer',
        metadata: {'question_type': 'multiple_choice', 'difficulty': 'hard'},
        timestamp: DateTime.now(),
        deviceInfo: 'Samsung Galaxy S23',
        appVersion: '1.1.5',
      );

      final json = originalContext.toJson();
      final deserializedContext = ErrorContext.fromJson(json);

      expect(deserializedContext.userId, equals(originalContext.userId));
      expect(deserializedContext.screenName, equals(originalContext.screenName));
      expect(deserializedContext.action, equals(originalContext.action));
      expect(deserializedContext.metadata['question_type'], equals('multiple_choice'));
      expect(deserializedContext.deviceInfo, equals(originalContext.deviceInfo));
    });
  });

  group('Performance Threshold Tests', () {
    test('should identify performance issues correctly', () {
      // Test that performance thresholds are working
      const thresholds = {
        PerformanceMetricType.screenLoad: 2000,
        PerformanceMetricType.networkRequest: 5000,
        PerformanceMetricType.databaseOperation: 1000,
        PerformanceMetricType.computation: 500,
        PerformanceMetricType.userInteraction: 100,
      };

      // Screen load over threshold
      final slowScreenLoad = PerformanceMetric(
        id: 'slow_1',
        type: PerformanceMetricType.screenLoad,
        name: 'SlowScreen',
        duration: const Duration(milliseconds: 3000), // Over 2000ms threshold
        startTime: DateTime.now().subtract(const Duration(milliseconds: 3000)),
        endTime: DateTime.now(),
      );

      expect(slowScreenLoad.duration.inMilliseconds, 
             greaterThan(thresholds[PerformanceMetricType.screenLoad]!));

      // Fast user interaction
      final fastInteraction = PerformanceMetric(
        id: 'fast_1',
        type: PerformanceMetricType.userInteraction,
        name: 'ButtonTap',
        duration: const Duration(milliseconds: 50), // Under 100ms threshold
        startTime: DateTime.now().subtract(const Duration(milliseconds: 50)),
        endTime: DateTime.now(),
      );

      expect(fastInteraction.duration.inMilliseconds, 
             lessThan(thresholds[PerformanceMetricType.userInteraction]!));
    });
  });
}
