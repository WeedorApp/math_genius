import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../../core/barrel.dart';

// Student UI components
import '../components/student_header.dart';
import '../components/student_dashboard.dart';

/// Student Home Screen
/// Main screen for student users with responsive layout
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenType = ref.watch(screenTypeProvider);
    final layoutService = ref.watch(responsiveLayoutServiceProvider);
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);

    final navigationItems = [
      const NavigationItem(
        title: 'Home',
        icon: Icons.home,
        route: '/student/home',
      ),
      const NavigationItem(
        title: 'Games',
        icon: Icons.games,
        route: '/student/games',
      ),
      const NavigationItem(
        title: 'AI Tutor',
        icon: Icons.smart_toy,
        route: '/student/ai-tutor',
      ),
      const NavigationItem(
        title: 'Progress',
        icon: Icons.trending_up,
        route: '/student/progress',
      ),
      const NavigationItem(
        title: 'Profile',
        icon: Icons.person,
        route: '/student/profile',
      ),
    ];

    return ResponsiveLayout(
      currentRoute: '/student/home',
      navigationItems: navigationItems,
      child: _buildStudentContent(
        context,
        ref,
        colorScheme,
        screenType,
        layoutService,
        isSidebarCollapsed,
      ),
    );
  }

  Widget _buildStudentContent(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
    bool isSidebarCollapsed,
  ) {
    switch (screenType) {
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return _buildDesktopLayout(colorScheme);
      case ScreenType.tablet:
        return _buildTabletLayout(colorScheme);
      case ScreenType.mobile:
        return _buildMobileLayout(colorScheme);
    }
  }

  Widget _buildDesktopLayout(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header
          const StudentHeader(),
          // Dashboard Content
          Expanded(child: const StudentDashboard()),
        ],
      ),
    );
  }

  Widget _buildTabletLayout(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header
          const StudentHeader(),
          // Dashboard Content
          Expanded(child: const StudentDashboard()),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(ColorScheme colorScheme) {
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Column(
        children: [
          // Header
          const StudentHeader(),
          // Dashboard Content
          Expanded(child: const StudentDashboard()),
        ],
      ),
    );
  }
}
