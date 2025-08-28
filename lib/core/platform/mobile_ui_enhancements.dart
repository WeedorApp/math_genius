import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'platform_service.dart';
import '../theme/theme_service.dart';

/// Mobile-specific UI enhancements for optimal touch experience
class MobileUIEnhancements {
  static const double _minTouchTarget = 44.0; // iOS HIG minimum
  static const double _androidMinTouchTarget = 48.0; // Material Design minimum
  static const double _mobileCardElevation = 2.0;
  static const double _mobileBorderRadius = 12.0;

  /// Get platform-appropriate touch target size
  static double getTouchTargetSize(PlatformType platform) {
    switch (platform) {
      case PlatformType.ios:
        return _minTouchTarget;
      case PlatformType.android:
        return _androidMinTouchTarget;
      default:
        return _androidMinTouchTarget;
    }
  }

  /// Create platform-specific button with optimal touch target
  static Widget platformButton({
    required PlatformType platform,
    required VoidCallback onPressed,
    required Widget child,
    ButtonStyle? style,
    bool isPrimary = false,
  }) {
    final minSize = getTouchTargetSize(platform);

    if (platform == PlatformType.ios && isPrimary) {
      return CupertinoButton.filled(
        onPressed: onPressed,
        padding: EdgeInsets.symmetric(
          horizontal: minSize / 2,
          vertical: (minSize - 28).clamp(8.0, 20.0),
        ),
        child: child,
      );
    }

    return ElevatedButton(
      onPressed: onPressed,
      style: (style ?? ElevatedButton.styleFrom()).copyWith(
        minimumSize: WidgetStateProperty.all(Size(minSize, minSize)),
        tapTargetSize: MaterialTapTargetSize.padded,
      ),
      child: child,
    );
  }

  /// Create mobile-optimized card with proper elevation and spacing
  static Widget mobileCard({
    required Widget child,
    required ColorScheme colorScheme,
    EdgeInsets? padding,
    VoidCallback? onTap,
  }) {
    return Card(
      elevation: _mobileCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_mobileBorderRadius),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_mobileBorderRadius),
        child: Padding(
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  /// Create mobile-optimized list tile with proper spacing
  static Widget mobileListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    required ColorScheme colorScheme,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56), // Material minimum
      child: ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_mobileBorderRadius),
        ),
      ),
    );
  }

  /// Create mobile-optimized bottom sheet
  static Future<T?> showMobileBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool enableDrag = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }

  /// Create mobile-optimized dialog
  static Future<T?> showMobileDialog<T>({
    required BuildContext context,
    required PlatformType platform,
    required Widget child,
    bool barrierDismissible = true,
  }) {
    if (platform == PlatformType.ios) {
      return showCupertinoDialog<T>(
        context: context,
        barrierDismissible: barrierDismissible,
        builder: (context) => child,
      );
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => child,
    );
  }

  /// Create mobile-optimized floating action button
  static Widget mobileFAB({
    required VoidCallback onPressed,
    required Widget child,
    required ColorScheme colorScheme,
    bool isExtended = false,
    String? label,
  }) {
    if (isExtended && label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: child,
        label: Text(label),
        elevation: 4,
        highlightElevation: 8,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      elevation: 4,
      highlightElevation: 8,
      child: child,
    );
  }

  /// Create mobile-optimized app bar with proper height
  static PreferredSizeWidget mobileAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    bool centerTitle = true,
    required MathGeniusThemeData themeData,
    required ColorScheme colorScheme,
  }) {
    return AppBar(
      title: Text(
        title,
        style: themeData.typography.titleLarge.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: centerTitle,
      leading: leading,
      actions: actions,
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      toolbarHeight: 56, // Standard mobile height
    );
  }

  /// Create mobile-optimized text field with proper touch targets
  static Widget mobileTextField({
    required String label,
    required TextEditingController controller,
    required ColorScheme colorScheme,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
    VoidCallback? onTap,
    bool readOnly = false,
    Widget? suffixIcon,
    int? maxLines = 1,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        onTap: onTap,
        readOnly: readOnly,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_mobileBorderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_mobileBorderRadius),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_mobileBorderRadius),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  /// Trigger platform-appropriate haptic feedback
  static void triggerHaptic(PlatformType platform, {bool isSuccess = false}) {
    switch (platform) {
      case PlatformType.ios:
        if (isSuccess) {
          HapticFeedback.lightImpact();
        } else {
          HapticFeedback.selectionClick();
        }
        break;
      case PlatformType.android:
        HapticFeedback.lightImpact();
        break;
      default:
        // No haptic feedback for other platforms
        break;
    }
  }

  /// Create mobile-optimized snackbar
  static void showMobileSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: isError
            ? colorScheme.error
            : colorScheme.inverseSurface,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_mobileBorderRadius),
        ),
        action: actionLabel != null && onActionPressed != null
            ? SnackBarAction(
                label: actionLabel,
                onPressed: onActionPressed,
                textColor: colorScheme.inversePrimary,
              )
            : null,
      ),
    );
  }
}

/// Mobile-specific layout constants
class MobileLayoutConstants {
  static const double bottomNavHeight = 80.0;
  static const double appBarHeight = 56.0;
  static const double fabSize = 56.0;
  static const double cardSpacing = 16.0;
  static const double sectionSpacing = 24.0;
  static const double contentPadding = 16.0;

  // Safe area considerations
  static EdgeInsets getSafeAreaPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return EdgeInsets.only(
      top: mediaQuery.padding.top,
      bottom: mediaQuery.padding.bottom,
      left: mediaQuery.padding.left,
      right: mediaQuery.padding.right,
    );
  }

  // Screen size helpers
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 414;
  }
}

/// Provider for mobile UI enhancements
final mobileUIProvider = Provider<MobileUIEnhancements>((ref) {
  return MobileUIEnhancements();
});
