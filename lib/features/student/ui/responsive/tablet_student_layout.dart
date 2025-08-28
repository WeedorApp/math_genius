import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../../core/barrel.dart';
import '../../../../core/theme/design_system.dart';

// Student UI components
import '../components/student_header.dart';
import '../components/student_dashboard.dart';

/// Tablet Student Layout
/// Collapsed sidebar (80px) with hover-expand functionality
class TabletStudentLayout extends ConsumerStatefulWidget {
  final Widget child;

  const TabletStudentLayout({super.key, required this.child});

  @override
  ConsumerState<TabletStudentLayout> createState() =>
      _TabletStudentLayoutState();
}

class _TabletStudentLayoutState extends ConsumerState<TabletStudentLayout> {
  bool _isSidebarExpanded = false;

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Collapsed Sidebar with Hover Expand
          _buildCollapsedSidebar(colorScheme),
          // Main Content Area
          Expanded(child: _buildMainContent(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildCollapsedSidebar(ColorScheme colorScheme) {
    return MouseRegion(
      onEnter: (_) => _expandSidebar(),
      onExit: (_) => _collapseSidebar(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _isSidebarExpanded ? 200.0 : 80.0,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          border: Border(
            right: BorderSide(
              color: colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
        ),
        child: Column(
          children: [
            // Sidebar Header
            _buildSidebarHeader(colorScheme),
            // Navigation Items
            Expanded(child: _buildSidebarNavigation(colorScheme)),
            // Sidebar Footer
            _buildSidebarFooter(colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader(ColorScheme colorScheme) {
    return Container(
      padding: DesignSystem.padding12,
      child: Column(
        children: [
          Icon(
            Icons.school,
            color: colorScheme.primary,
            size: DesignSystem.iconSize24,
          ),
          if (_isSidebarExpanded) ...[
            const SizedBox(height: 8),
            Text(
              'Math Genius',
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSidebarNavigation(ColorScheme colorScheme) {
    final navigationItems = [
      _buildNavItem(
        Icons.home,
        'Home',
        '/student/home',
        colorScheme,
        isActive: true,
      ),
      _buildNavItem(Icons.games, 'Games', '/student/games', colorScheme),
      _buildNavItem(
        Icons.smart_toy,
        'AI Tutor',
        '/student/ai-tutor',
        colorScheme,
      ),
      _buildNavItem(
        Icons.trending_up,
        'Progress',
        '/student/progress',
        colorScheme,
      ),
      _buildNavItem(Icons.person, 'Profile', '/student/profile', colorScheme),
    ];

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: navigationItems,
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String title,
    String route,
    ColorScheme colorScheme, {
    bool isActive = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: DesignSystem.iconSize20,
        ),
        title: _isSidebarExpanded
            ? Text(
                title,
                style: TextStyle(
                  color: isActive ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  fontSize: 12,
                ),
              )
            : null,
        tileColor: isActive ? colorScheme.primaryContainer : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          // Navigation action
        },
      ),
    );
  }

  Widget _buildSidebarFooter(ColorScheme colorScheme) {
    return Container(
      padding: DesignSystem.padding12,
      child: Column(
        children: [
          // Student Profile Summary (only when expanded)
          if (_isSidebarExpanded)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primary,
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student',
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Level 5',
                    style: TextStyle(
                      color: colorScheme.primary.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Settings
          ListTile(
            leading: Icon(
              Icons.settings,
              color: colorScheme.onSurfaceVariant,
              size: DesignSystem.iconSize20,
            ),
            title: _isSidebarExpanded
                ? Text(
                    'Settings',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 12,
                    ),
                  )
                : null,
            onTap: () {
              // Settings action
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMainContent(ColorScheme colorScheme) {
    return Column(
      children: [
        // Header
        const StudentHeader(),
        // Dashboard Content
        Expanded(child: const StudentDashboard()),
      ],
    );
  }

  void _expandSidebar() {
    if (!_isSidebarExpanded) {
      setState(() {
        _isSidebarExpanded = true;
      });
    }
  }

  void _collapseSidebar() {
    if (_isSidebarExpanded) {
      setState(() {
        _isSidebarExpanded = false;
      });
    }
  }
}
