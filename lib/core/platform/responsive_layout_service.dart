import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Screen size breakpoints for responsive design
class ResponsiveBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1600;
}

/// Screen type based on width
enum ScreenType { mobile, tablet, desktop, largeDesktop }

/// Layout type for different screen sizes
enum LayoutType {
  mobile, // Single column, bottom navigation
  tablet, // Single column, bottom navigation with larger spacing
  desktop, // Sidebar + main content
  largeDesktop, // Sidebar + main content with extra spacing
}

/// Responsive layout service
class ResponsiveLayoutService {
  static final ResponsiveLayoutService _instance =
      ResponsiveLayoutService._internal();
  factory ResponsiveLayoutService() => _instance;
  ResponsiveLayoutService._internal();

  /// Get screen type based on width
  ScreenType getScreenType(double width) {
    if (width < ResponsiveBreakpoints.mobile) {
      return ScreenType.mobile;
    } else if (width < ResponsiveBreakpoints.tablet) {
      return ScreenType.tablet;
    } else if (width < ResponsiveBreakpoints.desktop) {
      return ScreenType.desktop;
    } else {
      return ScreenType.largeDesktop;
    }
  }

  /// Get layout type based on screen type
  LayoutType getLayoutType(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return LayoutType.mobile;
      case ScreenType.tablet:
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return LayoutType.tablet; // Desktop now uses tablet layout
    }
  }

  /// Get sidebar width based on screen type and collapsed state
  double getSidebarWidth(ScreenType screenType, bool isCollapsed) {
    if (isCollapsed) {
      return 64; // Collapsed width for icon-only view
    }

    switch (screenType) {
      case ScreenType.mobile:
        return 0; // No sidebar on mobile
      case ScreenType.tablet:
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return 240; // All larger screens use tablet sidebar width
    }
  }

  /// Get main content padding based on screen type
  EdgeInsets getMainContentPadding(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return const EdgeInsets.all(16);
      case ScreenType.tablet:
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return const EdgeInsets.all(
          24,
        ); // All larger screens use tablet padding
    }
  }

  /// Check if sidebar should be shown
  bool shouldShowSidebar(ScreenType screenType) {
    return screenType == ScreenType.tablet ||
        screenType == ScreenType.desktop ||
        screenType == ScreenType.largeDesktop;
  }

  /// Check if bottom navigation should be shown
  bool shouldShowBottomNavigation(ScreenType screenType) {
    return screenType == ScreenType.mobile;
  }

  /// Check if sidebar should be collapsible
  bool shouldAllowSidebarCollapse(ScreenType screenType) {
    return screenType == ScreenType.tablet ||
        screenType == ScreenType.desktop ||
        screenType == ScreenType.largeDesktop;
  }

  /// Get navigation item spacing based on screen type
  double getNavigationItemSpacing(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 8;
      case ScreenType.tablet:
        return 12;
      case ScreenType.desktop:
        return 16;
      case ScreenType.largeDesktop:
        return 20;
    }
  }

  /// Get card elevation based on screen type
  double getCardElevation(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 2;
      case ScreenType.tablet:
        return 4;
      case ScreenType.desktop:
        return 6;
      case ScreenType.largeDesktop:
        return 8;
    }
  }

  /// Get border radius based on screen type
  double getBorderRadius(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 8;
      case ScreenType.tablet:
        return 12;
      case ScreenType.desktop:
        return 16;
      case ScreenType.largeDesktop:
        return 20;
    }
  }

  /// Get collapsed sidebar icon size
  double getCollapsedIconSize(ScreenType screenType) {
    switch (screenType) {
      case ScreenType.mobile:
        return 20;
      case ScreenType.tablet:
        return 24;
      case ScreenType.desktop:
        return 28;
      case ScreenType.largeDesktop:
        return 32;
    }
  }
}

/// Riverpod provider for responsive layout service
final responsiveLayoutServiceProvider = Provider<ResponsiveLayoutService>((
  ref,
) {
  return ResponsiveLayoutService();
});

/// Provider for current screen type
final screenTypeProvider = StateProvider<ScreenType>(
  (ref) => ScreenType.mobile,
);

/// Provider for current layout type
final layoutTypeProvider = Provider<LayoutType>((ref) {
  final screenType = ref.watch(screenTypeProvider);
  final layoutService = ref.watch(responsiveLayoutServiceProvider);
  return layoutService.getLayoutType(screenType);
});

/// Provider for sidebar collapsed state
final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);
