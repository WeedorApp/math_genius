import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/theme_service.dart';

/// Tablet-specific UI enhancements for optimal large-screen touch experience
class TabletUIEnhancements {
  static const double _tabletMinTouchTarget = 48.0;
  static const double _tabletCardElevation = 3.0;
  static const double _tabletBorderRadius = 12.0;
  static const double _masterPaneWidth = 320.0;
  static const double _detailPaneMinWidth = 480.0;

  /// Create tablet-optimized button with larger touch targets
  static Widget tabletButton({
    required VoidCallback onPressed,
    required Widget child,
    ButtonStyle? style,
    bool isPrimary = false,
    double? width,
    double? height,
  }) {
    return SizedBox(
      width: width,
      height: height ?? _tabletMinTouchTarget,
      child: isPrimary
          ? ElevatedButton(
              onPressed: onPressed,
              style: (style ?? ElevatedButton.styleFrom()).copyWith(
                minimumSize: WidgetStateProperty.all(
                  Size(_tabletMinTouchTarget, _tabletMinTouchTarget),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                elevation: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.pressed)) return 1.0;
                  return 3.0;
                }),
              ),
              child: child,
            )
          : OutlinedButton(
              onPressed: onPressed,
              style: (style ?? OutlinedButton.styleFrom()).copyWith(
                minimumSize: WidgetStateProperty.all(
                  Size(_tabletMinTouchTarget, _tabletMinTouchTarget),
                ),
                padding: WidgetStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              child: child,
            ),
    );
  }

  /// Create tablet-optimized card with appropriate elevation and spacing
  static Widget tabletCard({
    required Widget child,
    required ColorScheme colorScheme,
    EdgeInsets? padding,
    VoidCallback? onTap,
    bool isClickable = false,
  }) {
    return Card(
      elevation: _tabletCardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_tabletBorderRadius),
      ),
      child: isClickable
          ? InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(_tabletBorderRadius),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(20),
                child: child,
              ),
            )
          : Padding(padding: padding ?? const EdgeInsets.all(20), child: child),
    );
  }

  /// Create tablet-optimized master-detail layout
  static Widget tabletMasterDetail({
    required Widget master,
    required Widget detail,
    required ColorScheme colorScheme,
    double? masterWidth,
    bool showMasterInPortrait = true,
    bool isPortrait = false,
  }) {
    final effectiveMasterWidth = masterWidth ?? _masterPaneWidth;

    if (isPortrait && !showMasterInPortrait) {
      // In portrait mode, show only detail pane
      return detail;
    }

    return Row(
      children: [
        // Master pane
        Container(
          width: effectiveMasterWidth,
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(
              right: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: master,
        ),
        // Detail pane
        Expanded(
          child: Container(
            constraints: BoxConstraints(minWidth: _detailPaneMinWidth),
            child: detail,
          ),
        ),
      ],
    );
  }

  /// Create tablet-optimized split view with resizable divider
  static Widget tabletSplitView({
    required Widget leftPane,
    required Widget rightPane,
    required ColorScheme colorScheme,
    double initialSplitRatio = 0.4,
    double minLeftWidth = 200.0,
    double minRightWidth = 200.0,
    bool allowResize = true,
  }) {
    return _TabletSplitView(
      leftPane: leftPane,
      rightPane: rightPane,
      colorScheme: colorScheme,
      initialSplitRatio: initialSplitRatio,
      minLeftWidth: minLeftWidth,
      minRightWidth: minRightWidth,
      allowResize: allowResize,
    );
  }

  /// Create tablet-optimized navigation rail
  static Widget tabletNavigationRail({
    required List<NavigationRailDestination> destinations,
    required int selectedIndex,
    required Function(int) onDestinationSelected,
    required ColorScheme colorScheme,
    required MathGeniusThemeData themeData,
    Widget? leading,
    Widget? trailing,
    bool extended = false,
    double? minWidth,
  }) {
    return NavigationRail(
      destinations: destinations,
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      leading: leading,
      trailing: trailing,
      extended: extended,
      minWidth: minWidth ?? 80,
      backgroundColor: colorScheme.surface,
      selectedIconTheme: IconThemeData(
        color: colorScheme.onPrimaryContainer,
        size: 24,
      ),
      unselectedIconTheme: IconThemeData(
        color: colorScheme.onSurfaceVariant,
        size: 24,
      ),
      selectedLabelTextStyle: themeData.typography.labelMedium.copyWith(
        color: colorScheme.onPrimaryContainer,
        fontWeight: FontWeight.w600,
      ),
      unselectedLabelTextStyle: themeData.typography.labelMedium.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      indicatorColor: colorScheme.primaryContainer,
      useIndicator: true,
    );
  }

  /// Create tablet-optimized app bar with larger height
  static PreferredSizeWidget tabletAppBar({
    required String title,
    List<Widget>? actions,
    Widget? leading,
    required MathGeniusThemeData themeData,
    required ColorScheme colorScheme,
    bool centerTitle = false,
    double? toolbarHeight,
  }) {
    return AppBar(
      title: Text(
        title,
        style: themeData.typography.headlineSmall.copyWith(
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
      scrolledUnderElevation: 2,
      toolbarHeight: toolbarHeight ?? 72, // Taller for tablet
    );
  }

  /// Create tablet-optimized floating action button
  static Widget tabletFAB({
    required VoidCallback onPressed,
    required Widget child,
    required ColorScheme colorScheme,
    bool isExtended = false,
    String? label,
    bool isLarge = false,
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

    if (isLarge) {
      return FloatingActionButton.large(
        onPressed: onPressed,
        elevation: 4,
        highlightElevation: 8,
        child: child,
      );
    }

    return FloatingActionButton(
      onPressed: onPressed,
      elevation: 4,
      highlightElevation: 8,
      child: child,
    );
  }

  /// Create tablet-optimized bottom sheet
  static Future<T?> showTabletBottomSheet<T>({
    required BuildContext context,
    required Widget child,
    bool isScrollControlled = true,
    bool enableDrag = true,
    bool showDragHandle = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: 600, // Limit width on tablets
      ),
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: child,
      ),
    );
  }

  /// Create tablet-optimized dialog
  static Future<T?> showTabletDialog<T>({
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: width ?? 500,
          height: height,
          constraints: const BoxConstraints(
            minWidth: 400,
            maxWidth: 700,
            minHeight: 300,
            maxHeight: 600,
          ),
          child: child,
        ),
      ),
    );
  }

  /// Create tablet-optimized grid view
  static Widget tabletGridView({
    required List<Widget> children,
    required double screenWidth,
    double? childAspectRatio,
    double crossAxisSpacing = 16,
    double mainAxisSpacing = 16,
    EdgeInsets? padding,
  }) {
    int crossAxisCount;
    if (screenWidth > 1000) {
      crossAxisCount = 4;
    } else if (screenWidth > 700) {
      crossAxisCount = 3;
    } else {
      crossAxisCount = 2;
    }

    return GridView.count(
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
      childAspectRatio: childAspectRatio ?? 1.0,
      padding: padding ?? const EdgeInsets.all(16),
      children: children,
    );
  }

  /// Create tablet-optimized list tile with larger touch targets
  static Widget tabletListTile({
    required Widget title,
    Widget? subtitle,
    Widget? leading,
    Widget? trailing,
    VoidCallback? onTap,
    required ColorScheme colorScheme,
    bool dense = false,
  }) {
    return Container(
      constraints: BoxConstraints(
        minHeight: dense ? 56 : 72, // Larger for tablet
      ),
      child: ListTile(
        title: title,
        subtitle: subtitle,
        leading: leading,
        trailing: trailing,
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_tabletBorderRadius),
        ),
        minLeadingWidth: 56,
      ),
    );
  }

  /// Create tablet-optimized text field
  static Widget tabletTextField({
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
        style: const TextStyle(fontSize: 16), // Larger text for tablet
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_tabletBorderRadius),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_tabletBorderRadius),
            borderSide: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_tabletBorderRadius),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  /// Trigger tablet-appropriate haptic feedback
  static void triggerTabletHaptic({bool isSuccess = false}) {
    if (isSuccess) {
      HapticFeedback.lightImpact();
    } else {
      HapticFeedback.selectionClick();
    }
  }

  /// Create tablet-optimized snackbar
  static void showTabletSnackBar({
    required BuildContext context,
    required String message,
    bool isError = false,
    Duration duration = const Duration(seconds: 4),
    String? actionLabel,
    VoidCallback? onActionPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    SchedulerBinding.instance.addPostFrameCallback((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration,
          backgroundColor: isError
              ? colorScheme.error
              : colorScheme.inverseSurface,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_tabletBorderRadius),
          ),
          width: 400, // Fixed width for tablet
          action: actionLabel != null && onActionPressed != null
              ? SnackBarAction(
                  label: actionLabel,
                  onPressed: onActionPressed,
                  textColor: colorScheme.inversePrimary,
                )
              : null,
        ),
      );
    });
  }
}

/// Custom split view widget for tablets
class _TabletSplitView extends StatefulWidget {
  final Widget leftPane;
  final Widget rightPane;
  final ColorScheme colorScheme;
  final double initialSplitRatio;
  final double minLeftWidth;
  final double minRightWidth;
  final bool allowResize;

  const _TabletSplitView({
    required this.leftPane,
    required this.rightPane,
    required this.colorScheme,
    required this.initialSplitRatio,
    required this.minLeftWidth,
    required this.minRightWidth,
    required this.allowResize,
  });

  @override
  State<_TabletSplitView> createState() => _TabletSplitViewState();
}

class _TabletSplitViewState extends State<_TabletSplitView> {
  late double _splitRatio;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _splitRatio = widget.initialSplitRatio;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final leftWidth = constraints.maxWidth * _splitRatio;

        return Row(
          children: [
            // Left pane
            SizedBox(width: leftWidth, child: widget.leftPane),
            // Divider
            if (widget.allowResize)
              GestureDetector(
                onPanStart: (_) => setState(() => _isDragging = true),
                onPanEnd: (_) => setState(() => _isDragging = false),
                onPanUpdate: (details) {
                  final newRatio =
                      (leftWidth + details.delta.dx) / constraints.maxWidth;
                  final newLeftWidth = constraints.maxWidth * newRatio;

                  if (newLeftWidth >= widget.minLeftWidth &&
                      (constraints.maxWidth - newLeftWidth) >=
                          widget.minRightWidth) {
                    setState(() {
                      _splitRatio = newRatio;
                    });
                  }
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: Container(
                    width: 8,
                    color: _isDragging
                        ? widget.colorScheme.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                    child: Center(
                      child: Container(
                        width: 1,
                        color: widget.colorScheme.outline.withValues(
                          alpha: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              )
            else
              Container(
                width: 1,
                color: widget.colorScheme.outline.withValues(alpha: 0.2),
              ),
            // Right pane
            Expanded(child: widget.rightPane),
          ],
        );
      },
    );
  }
}

/// Tablet-specific layout constants
class TabletLayoutConstants {
  static const double minTouchTarget = 48.0;
  static const double cardElevation = 3.0;
  static const double borderRadius = 12.0;
  static const double appBarHeight = 72.0;
  static const double navigationRailWidth = 80.0;
  static const double extendedNavigationRailWidth = 256.0;
  static const double masterPaneWidth = 320.0;
  static const double detailPaneMinWidth = 480.0;
  static const double cardSpacing = 20.0;
  static const double sectionSpacing = 32.0;
  static const double contentPadding = 20.0;

  // Grid layouts
  static const int portraitGridColumns = 2;
  static const int landscapeGridColumns = 3;
  static const int largeTabletGridColumns = 4;
  static const double gridSpacing = 20.0;

  // Responsive breakpoints
  static const double smallTabletWidth = 600.0;
  static const double largeTabletWidth = 900.0;
}

/// Provider for tablet UI enhancements
final tabletUIProvider = Provider<TabletUIEnhancements>((ref) {
  return TabletUIEnhancements();
});
