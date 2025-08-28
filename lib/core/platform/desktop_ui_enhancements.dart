import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_service.dart';

/// Desktop-specific UI enhancements for optimal mouse and keyboard experience
class DesktopUIEnhancements {
  static const double _desktopMinButtonWidth = 120.0;
  static const double _desktopMinButtonHeight = 36.0;
  static const double _desktopCardElevation = 4.0;
  static const double _desktopBorderRadius = 8.0;
  static const double _sidebarWidth = 280.0;
  static const double _collapsedSidebarWidth = 72.0;

  /// Create desktop-optimized button with proper sizing and hover effects
  static Widget desktopButton({
    required VoidCallback onPressed,
    required Widget child,
    ButtonStyle? style,
    bool isPrimary = false,
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width ?? _desktopMinButtonWidth,
      height: height ?? _desktopMinButtonHeight,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: (style ?? ElevatedButton.styleFrom()).copyWith(
                elevation: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) return 6.0;
                  if (states.contains(WidgetState.pressed)) return 2.0;
                  return 4.0;
                }),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: (style ?? OutlinedButton.styleFrom()).copyWith(
                elevation: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.hovered)) return 2.0;
                  return 0.0;
                }),
              ),
              child: child,
            ),
    );
  }

  /// Create desktop-optimized card with hover effects and proper elevation
  static Widget desktopCard({
    required Widget child,
    required ColorScheme colorScheme,
    EdgeInsets? padding,
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    return Card(
      elevation: _desktopCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_desktopBorderRadius),
      ),
      child: isClickable
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_desktopBorderRadius),
              hoverColor: colorScheme.primary.withValues(alpha: 0.04),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
            )
          : Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
    );
  }

  /// Create desktop-optimized sidebar with resizing capability
  static Widget desktopSidebar({
    required List<Widget> children,
    required ColorScheme colorScheme,
    required MathGeniusThemeData themeData,
    bool isCollapsed = false,
    VoidCallback? onToggleCollapse,
    double? width,
  }) {
    final effectiveWidth =
        width ?? (isCollapsed ? _collapsedSidebarWidth : _sidebarWidth);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: effectiveWidth,
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
            color: colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with collapse button
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (!isCollapsed) ...[
                  Icon(Icons.school, color: colorScheme.primary, size: 32),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Math Genius',
                      style: themeData.typography.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isCollapsed)
                  Icon(Icons.school, color: colorScheme.primary, size: 32),
                if (onToggleCollapse != null)
                  IconButton(
                    icon: Icon(
                      isCollapsed ? Icons.chevron_right : Icons.chevron_left,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onPressed: onToggleCollapse,
                    tooltip: isCollapsed
                        ? 'Expand sidebar'
                        : 'Collapse sidebar',
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

  /// Create desktop-optimized navigation item with hover effects
  static Widget desktopNavItem({
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    required ColorScheme colorScheme,
    required MathGeniusThemeData themeData,
    bool isActive = false,
    bool isCollapsed = false,
    String? tooltip,
  }) {
    final item = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        hoverColor: colorScheme.primary.withValues(alpha: 0.08),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? colorScheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: isCollapsed
              ? Center(
                  child: Icon(
                    icon,
                    color: isActive
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                )
              : Row(
                  children: [
                    Icon(
                      icon,
                      color: isActive
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
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

    if (isCollapsed && tooltip != null) {
      return Tooltip(message: tooltip, child: item);
    }

    return item;
  }

  /// Create desktop-optimized app bar with proper height and controls
  static PreferredSizeWidget desktopAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    required MathGeniusThemeData themeData,
    required ColorScheme colorScheme,
    bool showWindowControls = false,
  }) {
    return AppBar(
      title: Text(
        title,
        style: themeData.typography.titleLarge.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      leading: leading,
      actions: [
        if (actions != null) ...actions,
        if (showWindowControls) ...[
          IconButton(
            icon: Icon(Icons.minimize, size: 18),
            onPressed: () {
              // Minimize window - platform specific implementation needed
            },
            tooltip: 'Minimize',
          ),
          IconButton(
            icon: Icon(Icons.crop_square, size: 16),
            onPressed: () {
              // Maximize/restore window - platform specific implementation needed
            },
            tooltip: 'Maximize',
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18),
            onPressed: () {
              // Close window - platform specific implementation needed
            },
            tooltip: 'Close',
          ),
        ],
      ],
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      toolbarHeight: 64, // Taller for desktop
    );
  }

  /// Create desktop-optimized text field with proper sizing
  static Widget desktopTextField({
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
    double? width,
  }) {
    return SizedBox(
      width: width,
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
            borderRadius: BorderRadius.circular(_desktopBorderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_desktopBorderRadius),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_desktopBorderRadius),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  /// Create desktop-optimized dialog with proper sizing
  static Future<T?> showDesktopDialog<T>({
    required BuildContext context,
    required Widget child,
    bool barrierDismissible = true,
    double? width,
    double? height,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: width ?? 400,
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

  /// Create desktop-optimized context menu
  static void showDesktopContextMenu({
    required BuildContext context,
    required Offset position,
    required List<PopupMenuEntry> items,
  }) {
    showMenu(
      context: context,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx + 1,
        position.dy + 1,
      ),
      items: items,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  /// Create desktop-optimized data table
  static Widget desktopDataTable({
    required List<DataColumn> columns,
    required List<DataRow> rows,
    required ColorScheme colorScheme,
    bool sortAscending = true,
    int? sortColumnIndex,
    Function(int, bool)? onSort,
  }) {
    return Card(
      elevation: _desktopCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_desktopBorderRadius),
      ),
      child: SingleChildScrollView(
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
    );
  }

  /// Create desktop-optimized toolbar
  static Widget desktopToolbar({
    required List<Widget> children,
    required ColorScheme colorScheme,
    EdgeInsets? padding,
  }) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(children: children),
    );
  }

  /// Handle keyboard shortcuts
  static Widget keyboardShortcuts({
    required Widget child,
    Map<LogicalKeySet, VoidCallback>? shortcuts,
  }) {
    return Focus(autofocus: true, child: child);
  }
}

/// Desktop-specific layout constants
class DesktopLayoutConstants {
  static const double sidebarWidth = 280.0;
  static const double collapsedSidebarWidth = 72.0;
  static const double appBarHeight = 64.0;
  static const double toolbarHeight = 48.0;
  static const double cardSpacing = 24.0;
  static const double sectionSpacing = 32.0;
  static const double contentPadding = 24.0;
  static const double minWindowWidth = 800.0;
  static const double minWindowHeight = 600.0;

  // Grid layouts
  static const int desktopGridColumns = 4;
  static const int largeDesktopGridColumns = 6;
  static const double gridSpacing = 24.0;

  // Multi-pane layouts
  static const double masterPaneWidth = 320.0;
  static const double detailPaneMinWidth = 480.0;
}

/// Provider for desktop UI enhancements
final desktopUIProvider = Provider<DesktopUIEnhancements>((ref) {
  return DesktopUIEnhancements();
});
