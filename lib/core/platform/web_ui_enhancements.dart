import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../theme/theme_service.dart';

/// Web-specific UI enhancements for optimal browser experience and PWA features
class WebUIEnhancements {
  static const double _webMinButtonHeight = 40.0;
  static const double _webCardElevation = 2.0;
  static const double _webBorderRadius = 8.0;
  static const double _webMaxContentWidth = 1200.0;

  /// Initialize PWA features and web-specific settings
  static void initializePWA() {
    // Set up service worker for offline functionality
    _registerServiceWorker();

    // Set up web app manifest
    _setupWebAppManifest();

    // Handle browser-specific features
    _setupBrowserFeatures();
  }

  static void _registerServiceWorker() {
    // Service worker registration would be handled by the web build process
    // This is a placeholder for PWA initialization
  }

  static void _setupWebAppManifest() {
    // Web app manifest is typically set up in web/manifest.json
    // This method can handle dynamic manifest updates if needed
  }

  static void _setupBrowserFeatures() {
    // Set up browser-specific features like keyboard shortcuts
    if (kIsWeb) {
      // Web-specific keyboard handling would go here
      // This is a placeholder for web-only functionality
    }
  }

  /// Create web-optimized button with proper hover states
  static Widget webButton({
    required VoidCallback onPressed,
    required Widget child,
    ButtonStyle? style,
    bool isPrimary = false,
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height ?? _webMinButtonHeight,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: (style ?? ElevatedButton.styleFrom()).copyWith(
                elevation: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) return 4.0;
                  if (states.contains(WidgetState.pressed)) return 1.0;
                  return 2.0;
                }),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: (style ?? OutlinedButton.styleFrom()).copyWith(),
              child: child,
            ),
    );
  }

  /// Create web-optimized card with hover effects
  static Widget webCard({
    required Widget child,
    required ColorScheme colorScheme,
    EdgeInsets? padding,
    VoidCallback? onTap,
    bool isClickable = false,
    bool showHoverEffect = true,
  }) {
    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: Card(
          elevation: _webCardElevation,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_webBorderRadius),
          ),
          child: isClickable
              ? InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(_webBorderRadius),
                  hoverColor: showHoverEffect
                      ? colorScheme.primary.withValues(alpha: 0.04)
                      : null,
                  child: Padding(
                    padding: padding ?? const EdgeInsets.all(16),
                    child: child,
                  ),
                )
              : Padding(
                  padding: padding ?? const EdgeInsets.all(16),
                  child: child,
                ),
        ),
      ),
    );
  }

  /// Create web-optimized responsive container with max width
  static Widget webContainer({
    required Widget child,
    double? maxWidth,
    EdgeInsets? padding,
    bool centerContent = true,
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      child: centerContent
          ? Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth ?? _webMaxContentWidth,
                ),
                child: child,
              ),
            )
          : ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: maxWidth ?? _webMaxContentWidth,
              ),
              child: child,
            ),
    );
  }

  /// Create web-optimized navigation bar with breadcrumbs
  static Widget webNavigationBar({
    required List<String> breadcrumbs,
    required MathGeniusThemeData themeData,
    required ColorScheme colorScheme,
    List<Widget>? actions,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Breadcrumbs
          Expanded(
            child: Row(
              children: breadcrumbs.asMap().entries.map((entry) {
                final index = entry.key;
                final breadcrumb = entry.value;
                final isLast = index == breadcrumbs.length - 1;

                return Row(
                  children: [
                    if (index > 0) ...[
                      Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      breadcrumb,
                      style: themeData.typography.bodyMedium.copyWith(
                        color: isLast
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant,
                        fontWeight: isLast
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                    if (!isLast) const SizedBox(width: 8),
                  ],
                );
              }).toList(),
            ),
          ),
          // Actions
          if (actions != null) ...actions,
        ],
      ),
    );
  }

  /// Create web-optimized modal dialog
  static Future<T?> showWebDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    double? width,
    double? height,
    bool fullScreen = false,
  }) {
    if (fullScreen) {
      return Navigator.of(context).push<T>(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => child,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          fullscreenDialog: true,
        ),
      );
    }

    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: width ?? 500,
          height: height,
          constraints: const BoxConstraints(
            minWidth: 300,
            maxWidth: 800,
            minHeight: 200,
            maxHeight: 600,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Create web-optimized sidebar with collapsible sections
  static Widget webSidebar({
    required List<Widget> children,
    required ColorScheme colorScheme,
    required MathGeniusThemeData themeData,
    double? width,
    bool isCollapsed = false,
  }) {
    return Container(
      width: width ?? (isCollapsed ? 60 : 280),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: isCollapsed
                ? Icon(Icons.school, color: colorScheme.primary, size: 28)
                : Row(
                    children: [
                      Icon(Icons.school, color: colorScheme.primary, size: 28),
                      const SizedBox(width: 12),
                      Text(
                        'Math Genius',
                        style: themeData.typography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
          ),
          const Divider(height: 1),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  /// Create web-optimized data table with sorting and filtering
  static Widget webDataTable({
    required List<DataColumn> columns,
    required List<DataRow> rows,
    required ColorScheme colorScheme,
    bool sortAscending = true,
    int? sortColumnIndex,
    Function(int, bool)? onSort,
    Widget? header,
    List<Widget>? actions,
  }) {
    return Card(
      elevation: _webCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_webBorderRadius),
      ),
      child: Column(
        children: [
          if (header != null || actions != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.3,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(_webBorderRadius),
                ),
              ),
              child: Row(
                children: [
                  if (header != null) Expanded(child: header),
                  if (actions != null) ...actions,
                ],
              ),
            ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: columns,
              rows: rows,
              sortAscending: sortAscending,
              sortColumnIndex: sortColumnIndex,

              headingRowColor: WidgetStateProperty.all(
                colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              dataRowMinHeight: 48,
              dataRowMaxHeight: 64,
              horizontalMargin: 24,
              columnSpacing: 32,
            ),
          ),
        ],
      ),
    );
  }

  /// Create web-optimized search field with suggestions
  static Widget webSearchField({
    required TextEditingController controller,
    required ColorScheme colorScheme,
    String? hintText,
    List<String>? suggestions,
    Function(String)? onChanged,
    Function(String)? onSubmitted,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hintText ?? 'Search...',
          prefixIcon: prefixIcon ?? Icon(Icons.search),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Handle web-specific keyboard shortcuts
  static Widget webKeyboardShortcuts({
    required Widget child,
    Map<String, VoidCallback>? shortcuts,
  }) {
    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent && shortcuts != null) {
          final key = event.logicalKey;
          final isCtrl = HardwareKeyboard.instance.isControlPressed;
          final isShift = HardwareKeyboard.instance.isShiftPressed;
          final isAlt = HardwareKeyboard.instance.isAltPressed;

          String shortcutKey = '';
          if (isCtrl) shortcutKey += 'ctrl+';
          if (isShift) shortcutKey += 'shift+';
          if (isAlt) shortcutKey += 'alt+';
          shortcutKey += key.keyLabel.toLowerCase();

          final callback = shortcuts[shortcutKey];
          if (callback != null) {
            callback();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: child,
    );
  }

  /// Create web-optimized tooltip with rich content
  static Widget webTooltip({
    required Widget child,
    required String message,
    Widget? richContent,
    Duration? showDuration,
  }) {
    if (richContent != null) {
      return Tooltip(
        message: '',
        richMessage: WidgetSpan(child: richContent),
        showDuration: showDuration ?? const Duration(seconds: 3),
        child: child,
      );
    }

    return Tooltip(
      message: message,
      showDuration: showDuration ?? const Duration(seconds: 3),
      child: child,
    );
  }

  /// Create web-optimized loading indicator
  static Widget webLoadingIndicator({
    String? message,
    required ColorScheme colorScheme,
    required MathGeniusThemeData themeData,
  }) {
    return Center(
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: colorScheme.primary),
              if (message != null) ...[
                const SizedBox(height: 16),
                Text(
                  message,
                  style: themeData.typography.bodyLarge.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Install PWA prompt
  static void showInstallPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Install Math Genius'),
        content: Text(
          'Install Math Genius as a Progressive Web App for the best experience. '
          'You can access it offline and get native app-like performance.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Maybe Later'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Trigger PWA install prompt
              _triggerInstallPrompt();
            },
            child: Text('Install'),
          ),
        ],
      ),
    );
  }

  static void _triggerInstallPrompt() {
    // This would trigger the browser's install prompt
    // Implementation depends on the specific PWA setup
  }

  /// Check if running as PWA
  static bool isPWA() {
    if (kIsWeb) {
      // In a real implementation, this would check the display mode
      return false; // Placeholder
    }
    return false;
  }

  /// Handle browser back button
  static void handleBrowserNavigation(VoidCallback onBack) {
    if (kIsWeb) {
      // In a real implementation, this would handle browser navigation
      // This is a placeholder for web-only functionality
    }
  }
}

/// Web-specific layout constants
class WebLayoutConstants {
  static const double maxContentWidth = 1200.0;
  static const double sidebarWidth = 280.0;
  static const double collapsedSidebarWidth = 60.0;
  static const double appBarHeight = 64.0;
  static const double cardSpacing = 24.0;
  static const double sectionSpacing = 32.0;
  static const double contentPadding = 24.0;

  // Responsive breakpoints for web
  static const double mobileBreakpoint = 768.0;
  static const double tabletBreakpoint = 1024.0;
  static const double desktopBreakpoint = 1200.0;

  // Grid layouts
  static const int mobileGridColumns = 1;
  static const int tabletGridColumns = 2;
  static const int desktopGridColumns = 3;
  static const int largeDesktopGridColumns = 4;
}

/// Provider for web UI enhancements
final webUIProvider = Provider<WebUIEnhancements>((ref) {
  return WebUIEnhancements();
});
