import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'responsive_layout_service.dart';
import '../theme/theme_service.dart';

/// Navigation item for the sidebar/bottom navigation
class NavigationItem {
  final String title;
  final IconData icon;
  final String route;
  final bool isActive;

  const NavigationItem({
    required this.title,
    required this.icon,
    required this.route,
    this.isActive = false,
  });
}

/// Responsive layout widget that adapts to screen size
class ResponsiveLayout extends ConsumerStatefulWidget {
  final Widget child;
  final String currentRoute;
  final List<NavigationItem> navigationItems;

  const ResponsiveLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.navigationItems,
  });

  @override
  ConsumerState<ResponsiveLayout> createState() => _ResponsiveLayoutState();
}

class _ResponsiveLayoutState extends ConsumerState<ResponsiveLayout> {
  @override
  void initState() {
    super.initState();
    _updateScreenType();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateScreenType();
  }

  void _updateScreenType() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final width = MediaQuery.of(context).size.width;
      final layoutService = ref.read(responsiveLayoutServiceProvider);
      final screenType = layoutService.getScreenType(width);

      ref.read(screenTypeProvider.notifier).state = screenType;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenType = ref.watch(screenTypeProvider);
    final layoutService = ref.watch(responsiveLayoutServiceProvider);
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);

    // Debug print for desktop detection (remove in production)
    // print(
    //   'Build - Screen type: $screenType, Sidebar collapsed: $isSidebarCollapsed, Window width: ${MediaQuery.of(context).size.width}',
    // );

    // Update screen type when layout changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final width = MediaQuery.of(context).size.width;
      final newScreenType = layoutService.getScreenType(width);
      if (newScreenType != screenType) {
        ref.read(screenTypeProvider.notifier).state = newScreenType;
      }
    });

    if (layoutService.shouldShowSidebar(screenType)) {
      return _buildSidebarLayout(
        colorScheme,
        screenType,
        layoutService,
        isSidebarCollapsed,
      );
    } else {
      return _buildMobileLayout(colorScheme, screenType, layoutService);
    }
  }

  Widget _buildSidebarLayout(
    ColorScheme colorScheme,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
    bool isSidebarCollapsed,
  ) {
    // Use tablet layout for all larger screens (tablet, desktop, largeDesktop)
    final effectiveSidebarWidth = isSidebarCollapsed
        ? 80.0
        : layoutService.getSidebarWidth(screenType, isSidebarCollapsed);
    final mainContentPadding = layoutService.getMainContentPadding(screenType);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Resizable Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: effectiveSidebarWidth,
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                right: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            child: Stack(
              children: [
                _buildSidebar(
                  colorScheme,
                  screenType,
                  layoutService,
                  isSidebarCollapsed,
                ),
                // Resize handle (disabled for tablet-like layout)
                // if (!isSidebarCollapsed &&
                //     (screenType == ScreenType.desktop ||
                //         screenType == ScreenType.largeDesktop))
                //   Positioned(
                //     right: 0,
                //     top: 0,
                //     bottom: 0,
                //     child: Container(
                //       decoration: BoxDecoration(
                //         border: Border(
                //           left: BorderSide(
                //             color: _isDragging || _isHovering
                //                 ? colorScheme.primary.withValues(alpha: 0.3)
                //                 : Colors.transparent,
                //             width: 2,
                //           ),
                //         ),
                //       ),
                //       child: _buildResizeHandle(colorScheme),
                //     ),
                //   ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(padding: mainContentPadding, child: widget.child),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(
    ColorScheme colorScheme,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
  ) {
    final mainContentPadding = layoutService.getMainContentPadding(screenType);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Container(padding: mainContentPadding, child: widget.child),
      bottomNavigationBar: _buildBottomNavigation(
        colorScheme,
        screenType,
        layoutService,
      ),
    );
  }

  Widget _buildSidebar(
    ColorScheme colorScheme,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
    bool isSidebarCollapsed,
  ) {
    final themeData = ref.watch(themeDataProvider);
    final spacing = layoutService.getNavigationItemSpacing(screenType);
    final canCollapse = layoutService.shouldAllowSidebarCollapse(screenType);

    return Column(
      children: [
        // App header
        Container(
          padding: EdgeInsets.all(spacing * 1.5),
          child: isSidebarCollapsed
              ? Column(
                  children: [
                    Center(
                      child: Icon(
                        Icons.school,
                        color: colorScheme.primary,
                        size: 32,
                      ),
                    ),
                    if (canCollapse) ...[
                      const SizedBox(height: 8),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          color: colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                        onPressed: () {
                          ref.read(sidebarCollapsedProvider.notifier).state =
                              false;
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          hoverColor: colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ],
                  ],
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.school, color: colorScheme.primary, size: 32),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        'Math Genius',
                        style: themeData.typography.titleLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (canCollapse) ...[
                      const SizedBox(width: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        child: IconButton(
                          icon: AnimatedRotation(
                            turns: isSidebarCollapsed ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: Icon(
                              Icons.chevron_left,
                              color: colorScheme.onSurfaceVariant,
                              size: 20,
                            ),
                          ),
                          onPressed: () {
                            ref.read(sidebarCollapsedProvider.notifier).state =
                                !isSidebarCollapsed;
                          },
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            hoverColor: colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            padding: const EdgeInsets.all(8),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        const Divider(height: 1),
        // Navigation items
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(spacing),
            itemCount: widget.navigationItems.length,
            separatorBuilder: (context, index) => SizedBox(height: spacing),
            itemBuilder: (context, index) {
              final item = widget.navigationItems[index];
              final isActive = item.route == widget.currentRoute;

              return _buildSidebarItem(
                item,
                isActive,
                colorScheme,
                themeData,
                spacing,
                isSidebarCollapsed,
                screenType,
                layoutService,
              );
            },
          ),
        ),
        // User section
        if (!isSidebarCollapsed) ...[
          Container(
            padding: EdgeInsets.all(spacing),
            child: _buildUserSection(colorScheme, themeData),
          ),
        ],
      ],
    );
  }

  Widget _buildSidebarItem(
    NavigationItem item,
    bool isActive,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
    double spacing,
    bool isSidebarCollapsed,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
  ) {
    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        child: InkWell(
          onTap: () => context.go(item.route),
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            padding: EdgeInsets.all(isSidebarCollapsed ? 8 : spacing),
            decoration: BoxDecoration(
              color: isActive
                  ? colorScheme.primaryContainer
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isActive
                  ? Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      width: 1,
                    )
                  : null,
            ),
            child: isSidebarCollapsed
                ? _buildCollapsedSidebarItem(
                    item,
                    isActive,
                    colorScheme,
                    screenType,
                    layoutService,
                  )
                : _buildExpandedSidebarItem(
                    item,
                    isActive,
                    colorScheme,
                    themeData,
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildCollapsedSidebarItem(
    NavigationItem item,
    bool isActive,
    ColorScheme colorScheme,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
  ) {
    final iconSize = layoutService.getCollapsedIconSize(screenType);

    return Tooltip(
      message: item.title,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: Icon(
            item.icon,
            color: isActive
                ? colorScheme.onPrimaryContainer
                : colorScheme.onSurfaceVariant,
            size: iconSize,
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedSidebarItem(
    NavigationItem item,
    bool isActive,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Row(
      children: [
        Icon(
          item.icon,
          color: isActive
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
          size: 24,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            item.title,
            style: themeData.typography.titleMedium.copyWith(
              color: isActive
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserSection(
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary,
            child: Icon(Icons.person, color: colorScheme.onPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Student',
                  style: themeData.typography.titleSmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Active Learner',
                  style: themeData.typography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onSurfaceVariant),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(
    ColorScheme colorScheme,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
  ) {
    final themeData = ref.watch(themeDataProvider);
    final spacing = layoutService.getNavigationItemSpacing(screenType);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: spacing / 2, // Reduced horizontal padding
            vertical: spacing / 2,
          ),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceEvenly, // Changed from spaceAround
            children: widget.navigationItems.map((item) {
              final isActive = item.route == widget.currentRoute;
              return Expanded(
                // Wrap in Expanded to prevent overflow
                child: _buildBottomNavItem(
                  item,
                  isActive,
                  colorScheme,
                  themeData,
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem(
    NavigationItem item,
    bool isActive,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 8,
          ), // Reduced padding
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: isActive
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                size: 20, // Reduced icon size
              ),
              const SizedBox(height: 2), // Reduced spacing
              Text(
                item.title,
                style: themeData.typography.labelSmall.copyWith(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 10, // Reduced font size
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
