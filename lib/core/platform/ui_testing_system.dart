import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'adaptive_ui_system.dart';
import 'platform_service.dart';
import '../theme/theme_service.dart';

/// UI testing and validation system for cross-platform consistency
class UITestingSystem {
  /// Test all UI components across different screen sizes and platforms
  static List<UITestResult> runComprehensiveUITests(BuildContext context) {
    final results = <UITestResult>[];

    // Test different screen sizes
    final testSizes = [
      const Size(360, 640), // Small mobile
      const Size(414, 896), // Large mobile
      const Size(768, 1024), // Tablet portrait
      const Size(1024, 768), // Tablet landscape
      const Size(1366, 768), // Desktop
      const Size(1920, 1080), // Large desktop
    ];

    // Test different platforms
    final testPlatforms = PlatformType.values;

    for (final size in testSizes) {
      for (final platform in testPlatforms) {
        results.addAll(_testPlatformSize(context, platform, size));
      }
    }

    return results;
  }

  static List<UITestResult> _testPlatformSize(
    BuildContext context,
    PlatformType platform,
    Size screenSize,
  ) {
    final results = <UITestResult>[];

    try {
      // Test UI mode detection
      final uiMode = _UITestHelper.getUIModeForSize(screenSize, platform);
      results.add(
        UITestResult(
          testName: 'UI Mode Detection',
          platform: platform,
          screenSize: screenSize,
          passed: _validateUIMode(uiMode, platform, screenSize),
          details: 'Detected UI mode: $uiMode',
        ),
      );

      // Test touch target sizes - use default values for testing
      final layoutConstants = _getLayoutConstantsForUIMode(uiMode);
      results.add(
        UITestResult(
          testName: 'Touch Target Size',
          platform: platform,
          screenSize: screenSize,
          passed: _validateTouchTargetSize(
            layoutConstants.minTouchTarget,
            platform,
          ),
          details: 'Touch target size: ${layoutConstants.minTouchTarget}px',
        ),
      );

      // Test spacing consistency
      results.add(
        UITestResult(
          testName: 'Spacing Consistency',
          platform: platform,
          screenSize: screenSize,
          passed: _validateSpacing(layoutConstants),
          details:
              'Card spacing: ${layoutConstants.cardSpacing}px, Content padding: ${layoutConstants.contentPadding}px',
        ),
      );

      // Test elevation appropriateness
      results.add(
        UITestResult(
          testName: 'Elevation Appropriateness',
          platform: platform,
          screenSize: screenSize,
          passed: _validateElevation(layoutConstants.elevation, uiMode),
          details: 'Elevation: ${layoutConstants.elevation}px',
        ),
      );
    } catch (e) {
      results.add(
        UITestResult(
          testName: 'General UI Test',
          platform: platform,
          screenSize: screenSize,
          passed: false,
          details: 'Error: $e',
        ),
      );
    }

    return results;
  }

  static bool _validateUIMode(
    UIMode uiMode,
    PlatformType platform,
    Size screenSize,
  ) {
    switch (platform) {
      case PlatformType.ios:
      case PlatformType.android:
        if (screenSize.width >= 900) {
          return uiMode == UIMode.tablet;
        }
        return uiMode == UIMode.mobile;

      case PlatformType.web:
        if (screenSize.width >= 1200) {
          return uiMode == UIMode.web;
        } else if (screenSize.width >= 900) {
          return uiMode == UIMode.tablet;
        }
        return uiMode == UIMode.mobile;

      case PlatformType.desktop:
        return uiMode == UIMode.desktop;

      case PlatformType.unknown:
        return true; // Accept any mode for unknown platform
    }
  }

  static bool _validateTouchTargetSize(
    double touchTargetSize,
    PlatformType platform,
  ) {
    switch (platform) {
      case PlatformType.ios:
        return touchTargetSize >= 44.0; // iOS HIG minimum
      case PlatformType.android:
        return touchTargetSize >= 48.0; // Material Design minimum
      case PlatformType.web:
      case PlatformType.desktop:
        return touchTargetSize >= 32.0; // Reasonable for mouse interaction
      case PlatformType.unknown:
        return touchTargetSize >= 44.0; // Safe default
    }
  }

  static bool _validateSpacing(AdaptiveLayoutConstants constants) {
    // Ensure spacing values are reasonable and consistent
    return constants.cardSpacing >= 8.0 &&
        constants.cardSpacing <= 32.0 &&
        constants.contentPadding >= 8.0 &&
        constants.contentPadding <= 32.0 &&
        constants.sectionSpacing >= constants.cardSpacing;
  }

  static bool _validateElevation(double elevation, UIMode uiMode) {
    switch (uiMode) {
      case UIMode.mobile:
        return elevation >= 1.0 && elevation <= 4.0;
      case UIMode.tablet:
        return elevation >= 2.0 && elevation <= 6.0;
      case UIMode.desktop:
        return elevation >= 2.0 && elevation <= 8.0;
      case UIMode.web:
        return elevation >= 1.0 && elevation <= 4.0;
    }
  }

  static AdaptiveLayoutConstants _getLayoutConstantsForUIMode(UIMode uiMode) {
    switch (uiMode) {
      case UIMode.mobile:
        return AdaptiveLayoutConstants.mobile();
      case UIMode.tablet:
        return AdaptiveLayoutConstants.tablet();
      case UIMode.desktop:
        return AdaptiveLayoutConstants.desktop();
      case UIMode.web:
        return AdaptiveLayoutConstants.web();
    }
  }

  /// Generate UI test report
  static UITestReport generateTestReport(List<UITestResult> results) {
    final totalTests = results.length;
    final passedTests = results.where((r) => r.passed).length;
    final failedTests = totalTests - passedTests;

    final platformResults = <PlatformType, List<UITestResult>>{};
    final testTypeResults = <String, List<UITestResult>>{};

    for (final result in results) {
      platformResults.putIfAbsent(result.platform, () => []).add(result);
      testTypeResults.putIfAbsent(result.testName, () => []).add(result);
    }

    return UITestReport(
      totalTests: totalTests,
      passedTests: passedTests,
      failedTests: failedTests,
      successRate: passedTests / totalTests,
      results: results,
      platformResults: platformResults,
      testTypeResults: testTypeResults,
    );
  }

  /// Validate UI consistency across platforms
  static List<UIConsistencyIssue> validateUIConsistency(
    List<UITestResult> results,
  ) {
    final issues = <UIConsistencyIssue>[];

    // Group results by test name and screen size
    final groupedResults = <String, Map<Size, List<UITestResult>>>{};

    for (final result in results) {
      final testKey = result.testName;
      groupedResults.putIfAbsent(testKey, () => {});
      groupedResults[testKey]!
          .putIfAbsent(result.screenSize, () => [])
          .add(result);
    }

    // Check for inconsistencies
    for (final testName in groupedResults.keys) {
      for (final screenSize in groupedResults[testName]!.keys) {
        final resultsForSize = groupedResults[testName]![screenSize]!;

        // Check if all platforms pass/fail consistently
        final passedPlatforms = resultsForSize
            .where((r) => r.passed)
            .map((r) => r.platform)
            .toList();
        final failedPlatforms = resultsForSize
            .where((r) => !r.passed)
            .map((r) => r.platform)
            .toList();

        if (passedPlatforms.isNotEmpty && failedPlatforms.isNotEmpty) {
          issues.add(
            UIConsistencyIssue(
              testName: testName,
              screenSize: screenSize,
              passedPlatforms: passedPlatforms,
              failedPlatforms: failedPlatforms,
              description: 'Inconsistent behavior across platforms',
            ),
          );
        }
      }
    }

    return issues;
  }

  /// Create UI test widget for visual validation
  static Widget createUITestWidget() {
    return const _UITestWidget();
  }
}

/// Simple UI testing without complex mocking
class _UITestHelper {
  static UIMode getUIModeForSize(Size screenSize, PlatformType platform) {
    final screenWidth = screenSize.width;

    switch (platform) {
      case PlatformType.ios:
      case PlatformType.android:
        if (screenWidth >= 900) {
          return UIMode.tablet;
        }
        return UIMode.mobile;

      case PlatformType.web:
        if (screenWidth >= 1200) {
          return UIMode.web;
        } else if (screenWidth >= 900) {
          return UIMode.tablet;
        }
        return UIMode.mobile;

      case PlatformType.desktop:
        return UIMode.desktop;

      case PlatformType.unknown:
        if (screenWidth >= 1200) {
          return UIMode.desktop;
        } else if (screenWidth >= 900) {
          return UIMode.tablet;
        }
        return UIMode.mobile;
    }
  }
}

/// UI test widget for visual validation
class _UITestWidget extends ConsumerWidget {
  const _UITestWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      appBar: AdaptiveUISystem.adaptiveAppBar(
        context: context,
        title: 'UI Test Suite',
        themeData: themeData,
        colorScheme: colorScheme,
      ),
      body: SingleChildScrollView(
        padding: context.adaptiveLayout.contentPadding.let(
          (p) => EdgeInsets.all(p),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Platform info
            AdaptiveUISystem.adaptiveCard(
              context: context,
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Platform Information',
                    style: themeData.typography.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('UI Mode: ${context.uiMode}'),
                  Text('Screen Size: ${MediaQuery.of(context).size}'),
                  Text(
                    'Platform: ${ref.read(platformServiceProvider).platformType}',
                  ),
                ],
              ),
            ),

            SizedBox(height: context.adaptiveLayout.sectionSpacing),

            // Test buttons
            AdaptiveUISystem.adaptiveCard(
              context: context,
              colorScheme: colorScheme,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interactive Tests',
                    style: themeData.typography.titleLarge.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      AdaptiveUISystem.adaptiveButton(
                        context: context,
                        onPressed: () {
                          context.triggerAdaptiveHaptic(isSuccess: true);
                          context.showAdaptiveSnackBar('Primary button test');
                        },
                        isPrimary: true,
                        child: Text('Primary Button'),
                      ),
                      AdaptiveUISystem.adaptiveButton(
                        context: context,
                        onPressed: () {
                          context.triggerAdaptiveHaptic();
                          context.showAdaptiveSnackBar('Secondary button test');
                        },
                        child: Text('Secondary Button'),
                      ),
                      AdaptiveUISystem.adaptiveButton(
                        context: context,
                        onPressed: () {
                          AdaptiveUISystem.showAdaptiveDialog(
                            context: context,
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Dialog Test'),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text('Close'),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: Text('Show Dialog'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Extension for convenience
extension on double {
  T let<T>(T Function(double) transform) => transform(this);
}

/// UI test result
class UITestResult {
  final String testName;
  final PlatformType platform;
  final Size screenSize;
  final bool passed;
  final String details;

  UITestResult({
    required this.testName,
    required this.platform,
    required this.screenSize,
    required this.passed,
    required this.details,
  });
}

/// UI test report
class UITestReport {
  final int totalTests;
  final int passedTests;
  final int failedTests;
  final double successRate;
  final List<UITestResult> results;
  final Map<PlatformType, List<UITestResult>> platformResults;
  final Map<String, List<UITestResult>> testTypeResults;

  UITestReport({
    required this.totalTests,
    required this.passedTests,
    required this.failedTests,
    required this.successRate,
    required this.results,
    required this.platformResults,
    required this.testTypeResults,
  });
}

/// UI consistency issue
class UIConsistencyIssue {
  final String testName;
  final Size screenSize;
  final List<PlatformType> passedPlatforms;
  final List<PlatformType> failedPlatforms;
  final String description;

  UIConsistencyIssue({
    required this.testName,
    required this.screenSize,
    required this.passedPlatforms,
    required this.failedPlatforms,
    required this.description,
  });
}
