import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'native_features_service.dart';

/// Mixin for integrating native features into widgets
///
/// Provides easy access to:
/// - Haptic feedback for user interactions
/// - Platform-specific optimizations
/// - Native performance enhancements
/// - Device capability detection
///
/// Usage:
///

/// class MyWidget extends ConsumerStatefulWidget {
///   // widget implementation
/// }
///
/// class _MyWidgetState extends ConsumerState&lt;MyWidget&gt;
///     with NativeIntegrationMixin&lt;MyWidget&gt; {
///   // Use native features like:
///   // await triggerSuccessHaptic();
///   // await optimizeForCurrentPlatform();
/// }
///

mixin NativeIntegrationMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  NativeFeaturesService? _nativeService;
  NativeCapabilities? _capabilities;

  /// Initialize native features for this widget
  @protected
  Future<void> initializeNativeFeatures() async {
    try {
      _nativeService = ref.read(nativeFeaturesServiceProvider);
      _capabilities = await _nativeService!.initializeNativeFeatures();

      debugPrint('🚀 Native features initialized for ${T.toString()}');
    } catch (e) {
      debugPrint('❌ Native features initialization failed: $e');
    }
  }

  /// Trigger haptic feedback for user interactions
  @protected
  Future<void> triggerHaptic(HapticType type) async {
    if (_nativeService != null && _capabilities?.hapticSupport == true) {
      await _nativeService!.triggerHapticFeedback(type);
    }
  }

  /// Convenience methods for common haptic patterns
  @protected
  Future<void> triggerSuccessHaptic() async {
    await triggerHaptic(HapticType.success);
  }

  @protected
  Future<void> triggerErrorHaptic() async {
    await triggerHaptic(HapticType.error);
  }

  @protected
  Future<void> triggerSelectionHaptic() async {
    await triggerHaptic(HapticType.selection);
  }

  @protected
  Future<void> triggerLightHaptic() async {
    await triggerHaptic(HapticType.light);
  }

  /// Check if device supports specific native features
  @protected
  bool supportsHapticFeedback() {
    return _capabilities?.hapticSupport ?? false;
  }

  @protected
  bool supportsNotifications() {
    return _capabilities?.notificationSupport ?? false;
  }

  @protected
  bool supportsBiometrics() {
    return _capabilities?.biometricSupport ?? false;
  }

  /// Get current platform information
  @protected
  String getCurrentPlatform() {
    return _capabilities?.deviceInfo.platform ?? 'unknown';
  }

  @protected
  bool isPhysicalDevice() {
    return _capabilities?.deviceInfo.isPhysicalDevice ?? false;
  }

  /// Optimize performance for current platform
  @protected
  Future<void> optimizeForCurrentPlatform() async {
    if (_nativeService != null) {
      await _nativeService!.optimizeForDevice();
    }
  }

  /// Get network status for adaptive features
  @protected
  Future<NetworkStatus> getNetworkStatus() async {
    if (_nativeService != null) {
      return await _nativeService!.getNetworkStatus();
    }
    return NetworkStatus.unknown;
  }

  /// Enable platform-specific animations
  @protected
  Duration getPlatformAnimationDuration(AnimationSpeed speed) {
    final platform = getCurrentPlatform();

    switch (speed) {
      case AnimationSpeed.fast:
        if (platform == 'iOS') return const Duration(milliseconds: 200);
        if (platform == 'Android') return const Duration(milliseconds: 150);
        return const Duration(milliseconds: 200);

      case AnimationSpeed.normal:
        if (platform == 'iOS') return const Duration(milliseconds: 300);
        if (platform == 'Android') return const Duration(milliseconds: 250);
        return const Duration(milliseconds: 300);

      case AnimationSpeed.slow:
        if (platform == 'iOS') return const Duration(milliseconds: 500);
        if (platform == 'Android') return const Duration(milliseconds: 400);
        return const Duration(milliseconds: 500);
    }
  }

  /// Get platform-specific curves
  @protected
  Curve getPlatformCurve() {
    final platform = getCurrentPlatform();

    switch (platform) {
      case 'iOS':
        return Curves.easeInOutCubic; // iOS-style smooth curves
      case 'Android':
        return Curves.fastOutSlowIn; // Material Design curves
      case 'Web':
        return Curves.easeInOut; // Web-optimized curves
      default:
        return Curves.easeInOutCubic;
    }
  }

  /// Show platform-appropriate loading indicator
  @protected
  Widget getPlatformLoadingIndicator(ColorScheme colorScheme) {
    final platform = getCurrentPlatform();

    switch (platform) {
      case 'iOS':
        return const CupertinoActivityIndicator();
      case 'Android':
      case 'Web':
      default:
        return CircularProgressIndicator(color: colorScheme.primary);
    }
  }

  /// Get platform-appropriate dialog style
  @protected
  Future<bool?> showPlatformDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'OK',
    String? cancelText,
  }) {
    final platform = getCurrentPlatform();

    if (platform == 'iOS') {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                child: Text(cancelText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(confirmText),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
    } else {
      return showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              TextButton(
                child: Text(cancelText),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ElevatedButton(
              child: Text(confirmText),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        ),
      );
    }
  }
}

// Enums for native integration
enum AnimationSpeed { fast, normal, slow }
