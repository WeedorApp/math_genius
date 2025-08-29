import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/scheduler.dart';

import 'platform_service.dart';

import 'mobile_ui_enhancements.dart';
import 'desktop_ui_enhancements.dart';
import 'web_ui_enhancements.dart';
import 'tablet_ui_enhancements.dart';
import '../theme/theme_service.dart';
import '../../features/home/mobile_home_screen.dart';
import '../../features/home/desktop_home_screen.dart';
import '../../features/home/web_home_screen.dart';
import '../../features/home/tablet_home_screen.dart';

/// Adaptive UI system that automatically selects the best UI components
/// based on platform and screen size
class AdaptiveUISystem {
  static const double _tabletBreakpoint = 900.0;
  static const double _desktopBreakpoint = 1200.0;

  /// Determine the optimal UI mode based on platform and screen size
  static UIMode getUIMode(BuildContext context, PlatformType platform) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Platform-specific overrides
    switch (platform) {
      case PlatformType.ios:
      case PlatformType.android:
        if (screenWidth >= _tabletBreakpoint) {
          return UIMode.tablet;
        }
        return UIMode.mobile;

      case PlatformType.web:
        if (screenWidth >= _desktopBreakpoint) {
          return UIMode.web;
        } else if (screenWidth >= _tabletBreakpoint) {
          return UIMode.tablet;
        }
        return UIMode.mobile;

      case PlatformType.desktop:
        return UIMode.desktop;

      case PlatformType.unknown:
        // Fallback based on screen size
        if (screenWidth >= _desktopBreakpoint) {
          return UIMode.desktop;
        } else if (screenWidth >= _tabletBreakpoint) {
          return UIMode.tablet;
        }
        return UIMode.mobile;
    }
  }

  /// Create adaptive button that works optimally on any platform
  static Widget adaptiveButton({
    required BuildContext context,
    required VoidCallback onPressed,
    required Widget child,
    ButtonStyle? style,
    bool isPrimary = false,
    double? width,
    double? height,
  }) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);

    Widget button;

    switch (uiMode) {
      case UIMode.mobile:
        button = MobileUIEnhancements.platformButton(
          platform: platform,
          onPressed: onPressed,
          child: child,
          style: style,
          isPrimary: isPrimary,
        );
        break;

      case UIMode.tablet:
        button = TabletUIEnhancements.tabletButton(
          onPressed: onPressed,
          child: child,
          style: style,
          isPrimary: isPrimary,
          width: width,
          height: height,
        );
        break;

      case UIMode.desktop:
        button = DesktopUIEnhancements.desktopButton(
          onPressed: onPressed,
          child: child,
          style: style,
          isPrimary: isPrimary,
          width: width,
          height: height,
        );
        break;

      case UIMode.web:
        button = WebUIEnhancements.webButton(
          onPressed: onPressed,
          child: child,
          style: style,
          isPrimary: isPrimary,
          width: width,
          height: height,
        );
        break;
    }

    // Apply explicit sizing if provided
    if (width != null || height != null) {
      return SizedBox(width: width, height: height, child: button);
    }

    return button;
  }

  /// Create adaptive card that works optimally on any platform
  static Widget adaptiveCard({
    required BuildContext context,
    required Widget child,
    required ColorScheme colorScheme,
    EdgeInsets? padding,
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);
    final layout = getLayoutConstants(context);
    final effectivePadding = padding ?? EdgeInsets.all(layout.contentPadding);

    switch (uiMode) {
      case UIMode.mobile:
        return MobileUIEnhancements.mobileCard(
          child: child,
          colorScheme: colorScheme,
          padding: effectivePadding,
          onTap: onTap,
        );

      case UIMode.tablet:
        return TabletUIEnhancements.tabletCard(
          child: child,
          colorScheme: colorScheme,
          padding: effectivePadding,
          onTap: onTap,
          isClickable: isClickable,
        );

      case UIMode.desktop:
        return DesktopUIEnhancements.desktopCard(
          child: child,
          colorScheme: colorScheme,
          padding: effectivePadding,
          onTap: onTap,
          isClickable: isClickable,
        );

      case UIMode.web:
        return WebUIEnhancements.webCard(
          child: child,
          colorScheme: colorScheme,
          padding: effectivePadding,
          onTap: onTap,
          isClickable: isClickable,
        );
    }
  }

  /// Create adaptive app bar that works optimally on any platform
  static PreferredSizeWidget adaptiveAppBar({
    required BuildContext context,
    required String title,
    required MathGeniusThemeData themeData,
    required ColorScheme colorScheme,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = false,
  }) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);

    switch (uiMode) {
      case UIMode.mobile:
        return MobileUIEnhancements.mobileAppBar(
          title: title,
          themeData: themeData,
          colorScheme: colorScheme,
          actions: actions,
          leading: leading,
          centerTitle: platform == PlatformType.ios,
        );

      case UIMode.tablet:
        return TabletUIEnhancements.tabletAppBar(
          title: title,
          themeData: themeData,
          colorScheme: colorScheme,
          actions: actions,
          leading: leading,
          centerTitle: centerTitle,
        );

      case UIMode.desktop:
        return DesktopUIEnhancements.desktopAppBar(
          title: title,
          themeData: themeData,
          colorScheme: colorScheme,
          actions: actions,
          leading: leading,
        );

      case UIMode.web:
        return DesktopUIEnhancements.desktopAppBar(
          title: title,
          themeData: themeData,
          colorScheme: colorScheme,
          actions: actions,
          leading: leading,
        );
    }
  }

  /// Show adaptive dialog that works optimally on any platform
  static Future<T?> showAdaptiveDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    double? width,
    double? height,
  }) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);

    switch (uiMode) {
      case UIMode.mobile:
        return MobileUIEnhancements.showMobileDialog<T>(
          context: context,
          platform: platform,
          child: child,
          barrierDismissible: barrierDismissible,
        );

      case UIMode.tablet:
        return TabletUIEnhancements.showTabletDialog<T>(
          context: context,
          child: child,
          barrierDismissible: barrierDismissible,
          width: width,
          height: height,
        );

      case UIMode.desktop:
        return DesktopUIEnhancements.showDesktopDialog<T>(
          context: context,
          child: child,
          barrierDismissible: barrierDismissible,
          width: width,
          height: height,
        );

      case UIMode.web:
        return WebUIEnhancements.showWebDialog<T>(
          context: context,
          child: child,
          barrierDismissible: barrierDismissible,
          width: width,
          height: height,
        );
    }
  }

  /// Show adaptive bottom sheet (mobile/tablet only)
  static Future<T?> showAdaptiveBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool enableDrag = true,
  }) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);

    switch (uiMode) {
      case UIMode.mobile:
        return MobileUIEnhancements.showMobileBottomSheet<T>(
          context: context,
          child: child,
          isScrollControlled: isScrollControlled,
          enableDrag: enableDrag,
        );

      case UIMode.tablet:
        return TabletUIEnhancements.showTabletBottomSheet<T>(
          context: context,
          child: child,
          isScrollControlled: isScrollControlled,
          enableDrag: enableDrag,
        );

      case UIMode.desktop:
      case UIMode.web:
        // For desktop/web, show dialog instead of bottom sheet
        return showAdaptiveDialog<T>(context: context, child: child);
    }
  }

  /// Create adaptive text field that works optimally on any platform
  static Widget adaptiveTextField({
    required BuildContext context,
    required String label,
    required TextEditingController controller,
    required ColorScheme colorScheme,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
    int? maxLines = 1,
    double? width,
  }) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);
    // Provide sensible default widths for larger form fields
    final defaultDesktopWidth = 420.0;
    final defaultWebWidth = 420.0;
    final defaultTabletWidth = 560.0;

    switch (uiMode) {
      case UIMode.mobile:
        return MobileUIEnhancements.mobileTextField(
          label: label,
          controller: controller,
          colorScheme: colorScheme,
          hint: hint,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          suffixIcon: suffixIcon,
          maxLines: maxLines,
        );

      case UIMode.tablet:
        return TabletUIEnhancements.tabletTextField(
          label: label,
          controller: controller,
          colorScheme: colorScheme,
          hint: hint,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          suffixIcon: suffixIcon,
          maxLines: maxLines,
          width: width ?? defaultTabletWidth,
        );

      case UIMode.desktop:
        return DesktopUIEnhancements.desktopTextField(
          label: label,
          controller: controller,
          colorScheme: colorScheme,
          hint: hint,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          suffixIcon: suffixIcon,
          maxLines: maxLines,
          width: width ?? defaultDesktopWidth,
        );

      case UIMode.web:
        return DesktopUIEnhancements.desktopTextField(
          label: label,
          controller: controller,
          colorScheme: colorScheme,
          hint: hint,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          onTap: onTap,
          readOnly: readOnly,
          suffixIcon: suffixIcon,
          maxLines: maxLines,
          width: width ?? defaultWebWidth,
        );
    }
  }

  /// Trigger adaptive haptic feedback
  static void triggerAdaptiveHaptic(
    BuildContext context, {
    bool isSuccess = false,
  }) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);

    switch (uiMode) {
      case UIMode.mobile:
        MobileUIEnhancements.triggerHaptic(platform, isSuccess: isSuccess);
        break;

      case UIMode.tablet:
        TabletUIEnhancements.triggerTabletHaptic(isSuccess: isSuccess);
        break;

      case UIMode.desktop:
      case UIMode.web:
        // No haptic feedback on desktop/web
        break;
    }
  }

  /// Show adaptive snackbar
  static void showAdaptiveSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);

    switch (uiMode) {
      case UIMode.mobile:
        MobileUIEnhancements.showMobileSnackBar(
          context: context,
          message: message,
          isError: isError,
          duration: duration,
          actionLabel: actionLabel,
          onActionPressed: onActionPressed,
        );
        break;

      case UIMode.tablet:
        TabletUIEnhancements.showTabletSnackBar(
          context: context,
          message: message,
          isError: isError,
          duration: duration,
          actionLabel: actionLabel,
          onActionPressed: onActionPressed,
        );
        break;

      case UIMode.desktop:
      case UIMode.web:
        // Use standard snackbar for desktop/web
        final colorScheme = Theme.of(context).colorScheme;
        SchedulerBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              duration: duration,
              backgroundColor: isError
                  ? colorScheme.error
                  : colorScheme.inverseSurface,
              action: actionLabel != null && onActionPressed != null
                  ? SnackBarAction(
                      label: actionLabel,
                      onPressed: onActionPressed,
                    )
                  : null,
            ),
          );
        });
        break;
    }
  }

  /// Get adaptive layout constants
  static AdaptiveLayoutConstants getLayoutConstants(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);
    final screenWidth = MediaQuery.of(context).size.width;

    switch (uiMode) {
      case UIMode.mobile:
        if (screenWidth < 360) return AdaptiveLayoutConstants.mobileCompact();
        if (screenWidth > 414) return AdaptiveLayoutConstants.mobileLarge();
        return AdaptiveLayoutConstants.mobile();
      case UIMode.tablet:
        if (screenWidth < 800) return AdaptiveLayoutConstants.tabletSmall();
        if (screenWidth > 1200) return AdaptiveLayoutConstants.tabletLarge();
        return AdaptiveLayoutConstants.tablet();
      case UIMode.desktop:
        if (screenWidth >= 1600) return AdaptiveLayoutConstants.desktopXL();
        if (screenWidth >= 1200) return AdaptiveLayoutConstants.desktopLarge();
        return AdaptiveLayoutConstants.desktop();
      case UIMode.web:
        if (screenWidth >= 1600) return AdaptiveLayoutConstants.webLarge();
        return AdaptiveLayoutConstants.web();
    }
  }

  /// Create adaptive home screen based on platform
  static Widget createAdaptiveHomeScreen(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    final platform = container.read(platformServiceProvider).platformType;
    final uiMode = getUIMode(context, platform);

    switch (uiMode) {
      case UIMode.mobile:
        return const MobileHomeScreen();
      case UIMode.tablet:
        return const TabletHomeScreen();
      case UIMode.desktop:
        return const DesktopHomeScreen();
      case UIMode.web:
        return const WebHomeScreen();
    }
  }
}

/// UI modes for different platforms and screen sizes
enum UIMode { mobile, tablet, desktop, web }

/// Adaptive layout constants that adjust based on UI mode
class AdaptiveLayoutConstants {
  final double cardSpacing;
  final double sectionSpacing;
  final double contentPadding;
  final double borderRadius;
  final double elevation;
  final double minTouchTarget;
  final double appBarHeight;

  const AdaptiveLayoutConstants({
    required this.cardSpacing,
    required this.sectionSpacing,
    required this.contentPadding,
    required this.borderRadius,
    required this.elevation,
    required this.minTouchTarget,
    required this.appBarHeight,
  });

  factory AdaptiveLayoutConstants.mobile() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 16.0,
      sectionSpacing: 24.0,
      contentPadding: 16.0,
      borderRadius: 12.0,
      elevation: 2.0,
      minTouchTarget: 44.0,
      appBarHeight: 56.0,
    );
  }

  factory AdaptiveLayoutConstants.mobileCompact() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 12.0,
      sectionSpacing: 20.0,
      contentPadding: 12.0,
      borderRadius: 12.0,
      elevation: 1.0,
      minTouchTarget: 44.0,
      appBarHeight: 56.0,
    );
  }

  factory AdaptiveLayoutConstants.mobileLarge() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 20.0,
      sectionSpacing: 28.0,
      contentPadding: 18.0,
      borderRadius: 12.0,
      elevation: 2.0,
      minTouchTarget: 48.0,
      appBarHeight: 60.0,
    );
  }

  factory AdaptiveLayoutConstants.tablet() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 20.0,
      sectionSpacing: 32.0,
      contentPadding: 20.0,
      borderRadius: 12.0,
      elevation: 3.0,
      minTouchTarget: 48.0,
      appBarHeight: 72.0,
    );
  }

  factory AdaptiveLayoutConstants.tabletSmall() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 18.0,
      sectionSpacing: 28.0,
      contentPadding: 18.0,
      borderRadius: 12.0,
      elevation: 3.0,
      minTouchTarget: 48.0,
      appBarHeight: 68.0,
    );
  }

  factory AdaptiveLayoutConstants.tabletLarge() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 24.0,
      sectionSpacing: 36.0,
      contentPadding: 24.0,
      borderRadius: 12.0,
      elevation: 3.0,
      minTouchTarget: 48.0,
      appBarHeight: 80.0,
    );
  }

  factory AdaptiveLayoutConstants.desktop() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 24.0,
      sectionSpacing: 32.0,
      contentPadding: 24.0,
      borderRadius: 8.0,
      elevation: 4.0,
      minTouchTarget: 36.0,
      appBarHeight: 64.0,
    );
  }

  factory AdaptiveLayoutConstants.desktopLarge() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 28.0,
      sectionSpacing: 36.0,
      contentPadding: 28.0,
      borderRadius: 8.0,
      elevation: 4.0,
      minTouchTarget: 36.0,
      appBarHeight: 68.0,
    );
  }

  factory AdaptiveLayoutConstants.desktopXL() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 32.0,
      sectionSpacing: 40.0,
      contentPadding: 32.0,
      borderRadius: 8.0,
      elevation: 4.0,
      minTouchTarget: 36.0,
      appBarHeight: 72.0,
    );
  }

  factory AdaptiveLayoutConstants.web() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 24.0,
      sectionSpacing: 32.0,
      contentPadding: 24.0,
      borderRadius: 8.0,
      elevation: 2.0,
      minTouchTarget: 40.0,
      appBarHeight: 64.0,
    );
  }

  factory AdaptiveLayoutConstants.webLarge() {
    return const AdaptiveLayoutConstants(
      cardSpacing: 28.0,
      sectionSpacing: 36.0,
      contentPadding: 28.0,
      borderRadius: 8.0,
      elevation: 2.0,
      minTouchTarget: 40.0,
      appBarHeight: 68.0,
    );
  }
}

/// Extension to easily access adaptive UI system from context
extension AdaptiveUIExtension on BuildContext {
  UIMode get uiMode {
    final container = ProviderScope.containerOf(this);
    final platform = container.read(platformServiceProvider).platformType;
    return AdaptiveUISystem.getUIMode(this, platform);
  }

  AdaptiveLayoutConstants get adaptiveLayout {
    return AdaptiveUISystem.getLayoutConstants(this);
  }

  void showAdaptiveSnackBar(
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    AdaptiveUISystem.showAdaptiveSnackBar(
      context: this,
      message: message,
      isError: isError,
      duration: duration,
      actionLabel: actionLabel,
      onActionPressed: onActionPressed,
    );
  }

  void triggerAdaptiveHaptic({bool isSuccess = false}) {
    AdaptiveUISystem.triggerAdaptiveHaptic(this, isSuccess: isSuccess);
  }
}

/// Provider for adaptive UI system
final adaptiveUIProvider = Provider<AdaptiveUISystem>((ref) {
  return AdaptiveUISystem();
});

/// Provider for current UI mode
final uiModeProvider = Provider<UIMode>((ref) {
  // This would be updated based on the current context
  // For now, return a default value
  return UIMode.mobile;
});
