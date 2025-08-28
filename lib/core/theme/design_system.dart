import 'package:flutter/material.dart';
import 'theme_service.dart';

/// Standardized Design System for Math Genius
/// Ensures UI uniformity and professional layout standards
class DesignSystem {
  // Spacing Scale (8px base)
  static const double spacing4 = 4.0; // 0.5x base
  static const double spacing8 = 8.0; // 1x base
  static const double spacing12 = 12.0; // 1.5x base
  static const double spacing16 = 16.0; // 2x base
  static const double spacing20 = 20.0; // 2.5x base
  static const double spacing24 = 24.0; // 3x base
  static const double spacing32 = 32.0; // 4x base
  static const double spacing40 = 40.0; // 5x base
  static const double spacing48 = 48.0; // 6x base

  // Border Radius Scale
  static const double radius4 = 4.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius20 = 20.0;
  static const double radius24 = 24.0;

  // Card Elevation Scale
  static const double elevation1 = 1.0;
  static const double elevation2 = 2.0;
  static const double elevation4 = 4.0;
  static const double elevation8 = 8.0;
  static const double elevation12 = 12.0;

  // Icon Sizes
  static const double iconSize16 = 16.0;
  static const double iconSize20 = 20.0;
  static const double iconSize24 = 24.0;
  static const double iconSize32 = 32.0;
  static const double iconSize40 = 40.0;
  static const double iconSize48 = 48.0;

  // Responsive Breakpoints
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;
  static const double largeDesktopBreakpoint = 1600.0;

  // Standardized Padding
  static const EdgeInsets padding4 = EdgeInsets.all(spacing4);
  static const EdgeInsets padding8 = EdgeInsets.all(spacing8);
  static const EdgeInsets padding12 = EdgeInsets.all(spacing12);
  static const EdgeInsets padding16 = EdgeInsets.all(spacing16);
  static const EdgeInsets padding20 = EdgeInsets.all(spacing20);
  static const EdgeInsets padding24 = EdgeInsets.all(spacing24);
  static const EdgeInsets padding32 = EdgeInsets.all(spacing32);

  // Standardized Margins
  static const EdgeInsets margin4 = EdgeInsets.all(spacing4);
  static const EdgeInsets margin8 = EdgeInsets.all(spacing8);
  static const EdgeInsets margin12 = EdgeInsets.all(spacing12);
  static const EdgeInsets margin16 = EdgeInsets.all(spacing16);
  static const EdgeInsets margin20 = EdgeInsets.all(spacing20);
  static const EdgeInsets margin24 = EdgeInsets.all(spacing24);
  static const EdgeInsets margin32 = EdgeInsets.all(spacing32);

  // Standardized Spacing Widgets
  static const SizedBox gap4 = SizedBox(height: spacing4);
  static const SizedBox gap8 = SizedBox(height: spacing8);
  static const SizedBox gap12 = SizedBox(height: spacing12);
  static const SizedBox gap16 = SizedBox(height: spacing16);
  static const SizedBox gap20 = SizedBox(height: spacing20);
  static const SizedBox gap24 = SizedBox(height: spacing24);
  static const SizedBox gap32 = SizedBox(height: spacing32);

  // Standardized Border Radius
  static const BorderRadius borderRadius4 = BorderRadius.all(
    Radius.circular(radius4),
  );
  static const BorderRadius borderRadius8 = BorderRadius.all(
    Radius.circular(radius8),
  );
  static const BorderRadius borderRadius12 = BorderRadius.all(
    Radius.circular(radius12),
  );
  static const BorderRadius borderRadius16 = BorderRadius.all(
    Radius.circular(radius16),
  );
  static const BorderRadius borderRadius20 = BorderRadius.all(
    Radius.circular(radius20),
  );
  static const BorderRadius borderRadius24 = BorderRadius.all(
    Radius.circular(radius24),
  );

  // Standardized Card Styles
  static BoxDecoration cardDecoration({
    required ColorScheme colorScheme,
    double elevation = elevation2,
    BorderRadius? borderRadius,
  }) {
    return BoxDecoration(
      color: colorScheme.surface,
      borderRadius: borderRadius ?? borderRadius12,
      boxShadow: [
        BoxShadow(
          color: colorScheme.shadow.withValues(alpha: 0.1),
          blurRadius: elevation * 2,
          offset: Offset(0, elevation),
        ),
      ],
    );
  }

  // Standardized Input Decoration
  static InputDecoration inputDecoration({
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? hintText,
    String? errorText,
    ColorScheme? colorScheme,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(borderRadius: borderRadius8),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: spacing16,
        vertical: spacing12,
      ),
    );
  }

  // Standardized Button Styles
  static ButtonStyle primaryButtonStyle({
    required ColorScheme colorScheme,
    double? borderRadius,
  }) {
    return ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(
        horizontal: spacing24,
        vertical: spacing12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radius8),
      ),
    );
  }

  static ButtonStyle secondaryButtonStyle({
    required ColorScheme colorScheme,
    double? borderRadius,
  }) {
    return OutlinedButton.styleFrom(
      foregroundColor: colorScheme.primary,
      side: BorderSide(color: colorScheme.primary),
      padding: const EdgeInsets.symmetric(
        horizontal: spacing24,
        vertical: spacing12,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius ?? radius8),
      ),
    );
  }

  // Standardized Grid Layouts
  static SliverGridDelegateWithFixedCrossAxisCount responsiveGridDelegate({
    required bool isSidebarCollapsed,
    int collapsedCrossAxisCount = 3,
    int expandedCrossAxisCount = 2,
    double childAspectRatio = 1.2,
    double crossAxisSpacing = spacing16,
    double mainAxisSpacing = spacing16,
  }) {
    return SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: isSidebarCollapsed
          ? collapsedCrossAxisCount
          : expandedCrossAxisCount,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }

  // Standardized Card Widget
  static Widget standardCard({
    required Widget child,
    required ColorScheme colorScheme,
    EdgeInsets? padding,
    double elevation = elevation2,
    BorderRadius? borderRadius,
    VoidCallback? onTap,
  }) {
    final cardWidget = Container(
      padding: padding ?? padding20,
      decoration: cardDecoration(
        colorScheme: colorScheme,
        elevation: elevation,
        borderRadius: borderRadius,
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? borderRadius12,
        child: cardWidget,
      );
    }

    return cardWidget;
  }

  // Standardized Section Header
  static Widget sectionHeader({
    required String title,
    required MathGeniusThemeData themeData,
    required ColorScheme colorScheme,
    Widget? action,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: spacing16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: themeData.typography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (action != null) action,
        ],
      ),
    );
  }

  // Standardized Activity Item
  static Widget activityItem({
    required String title,
    required String time,
    required IconData icon,
    required Color color,
    required MathGeniusThemeData themeData,
    required ColorScheme colorScheme,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: spacing8),
      child: Row(
        children: [
          Container(
            padding: padding8,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: borderRadius8,
            ),
            child: Icon(icon, color: color, size: iconSize20),
          ),
          const SizedBox(width: spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: themeData.typography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: spacing4),
                Text(
                  time,
                  style: themeData.typography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Standardized Navigation Item
  static Widget navigationItem({
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required MathGeniusThemeData themeData,
    bool isCollapsed = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius12,
        child: Container(
          padding: EdgeInsets.all(isCollapsed ? spacing8 : spacing12),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: borderRadius12,
            border: isActive
                ? Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.3),
                    width: 1,
                  )
                : null,
          ),
          child: isCollapsed
              ? Icon(
                  icon,
                  color: isActive
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  size: iconSize24,
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: iconSize24,
                    ),
                    const SizedBox(width: spacing12),
                    Expanded(
                      child: Text(
                        title,
                        style: themeData.typography.titleMedium.copyWith(
                          color: isActive
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                          fontWeight: isActive
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // Standardized Form Field
  static Widget formField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    bool obscureText = false,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int? maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: inputDecoration(
        labelText: labelText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
      validator: validator,
    );
  }

  // Standardized Loading Indicator
  static Widget loadingIndicator({
    required ColorScheme colorScheme,
    String? message,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
          ),
          if (message != null) ...[
            const SizedBox(height: spacing16),
            Text(
              message,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Standardized Error Display
  static Widget errorDisplay({
    required String message,
    required ColorScheme colorScheme,
    VoidCallback? onRetry,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: iconSize48, color: colorScheme.error),
          const SizedBox(height: spacing16),
          Text(
            'Error',
            style: TextStyle(
              color: colorScheme.error,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: spacing8),
          Text(
            message,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: spacing24),
            ElevatedButton(
              onPressed: onRetry,
              style: primaryButtonStyle(colorScheme: colorScheme),
              child: const Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }

  // Standardized Empty State
  static Widget emptyState({
    required String title,
    required String message,
    required IconData icon,
    required ColorScheme colorScheme,
    VoidCallback? onAction,
    String? actionText,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize48, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: spacing16),
          Text(
            title,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: spacing8),
          Text(
            message,
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionText != null) ...[
            const SizedBox(height: spacing24),
            ElevatedButton(
              onPressed: onAction,
              style: primaryButtonStyle(colorScheme: colorScheme),
              child: Text(actionText),
            ),
          ],
        ],
      ),
    );
  }
}
