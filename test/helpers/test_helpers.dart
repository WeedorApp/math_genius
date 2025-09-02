import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed unused import
import 'package:math_genius/core/barrel.dart';

/// Test helpers for Math Genius unit and widget tests
class TestHelpers {
  /// Create a provider scope with mocked dependencies for testing
  static ProviderScope createTestProviderScope({
    required Widget child,
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(
          _createMockSharedPreferences(),
        ),
        hiveBoxProvider.overrideWithValue(null),
        ...overrides,
      ],
      child: child,
    );
  }

  /// Create mock SharedPreferences for testing
  static SharedPreferences _createMockSharedPreferences() {
    SharedPreferences.setMockInitialValues({});
    return SharedPreferences.getInstance() as SharedPreferences;
  }

  /// Create a test widget with all necessary providers
  static Widget createTestWidget(Widget child) {
    return createTestProviderScope(
      child: MaterialApp(
        home: child,
      ),
    );
  }

  /// Pump and settle with extended timeout for complex widgets
  static Future<void> pumpAndSettleExtended(
    WidgetTester tester, [
    Duration timeout = const Duration(seconds: 10),
  ]) async {
    await tester.pumpAndSettle(timeout);
  }

  /// Find widget by type and verify it exists
  static void expectWidgetExists<T extends Widget>() {
    expect(find.byType(T), findsOneWidget);
  }

  /// Find multiple widgets by type and verify count
  static void expectWidgetCount<T extends Widget>(int count) {
    expect(find.byType(T), findsNWidgets(count));
  }

  /// Tap widget and wait for animations
  static Future<void> tapAndSettle(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// Enter text and wait for changes
  static Future<void> enterTextAndSettle(
    WidgetTester tester,
    Finder finder,
    String text,
  ) async {
    await tester.enterText(finder, text);
    await tester.pumpAndSettle();
  }
}
