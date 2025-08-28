import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../../core/barrel.dart';
import '../../../../core/theme/design_system.dart';

// Student UI components
import '../components/student_header.dart';
import '../components/student_dashboard.dart';

/// Desktop Student Layout
/// Expanded sidebar (280px) with resizable and collapsible functionality
class DesktopStudentLayout extends ConsumerStatefulWidget {
  final Widget child;

  const DesktopStudentLayout({super.key, required this.child});

  @override
  ConsumerState<DesktopStudentLayout> createState() =>
      _DesktopStudentLayoutState();
}

class _DesktopStudentLayoutState extends ConsumerState<DesktopStudentLayout> {
  final double _sidebarWidth = 280.0;
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Row(
        children: [
          // Resizable Sidebar
          _buildResizableSidebar(colorScheme),
          // Main Content Area
          Expanded(child: _buildMainContent(colorScheme)),
        ],
      ),
    );
  }

  Widget _buildResizableSidebar(ColorScheme colorScheme) {
    return Container(
      width: _isSidebarCollapsed ? 80.0 : _sidebarWidth,
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
    );
  }

  Widget _buildSidebarHeader(ColorScheme colorScheme) {
    return Container(
      padding: DesignSystem.padding16,
      child: Row(
        children: [
          Icon(
            Icons.school,
            color: colorScheme.primary,
            size: DesignSystem.iconSize24,
          ),
          if (!_isSidebarCollapsed) ...[
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Math Genius',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
          IconButton(
            onPressed: _toggleSidebar,
            icon: Icon(
              _isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
              color: colorScheme.onSurfaceVariant,
            ),
            tooltip: _isSidebarCollapsed
                ? 'Expand Sidebar'
                : 'Collapse Sidebar',
          ),
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
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: ListTile(
        leading: Icon(
          icon,
          color: isActive ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: DesignSystem.iconSize20,
        ),
        title: _isSidebarCollapsed
            ? null
            : Text(
                title,
                style: TextStyle(
                  color: isActive ? colorScheme.primary : colorScheme.onSurface,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
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
      padding: DesignSystem.padding16,
      child: Column(
        children: [
          // Student Profile Summary
          if (!_isSidebarCollapsed)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
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
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Student',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Level 5',
                          style: TextStyle(
                            color: colorScheme.primary.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
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
            title: _isSidebarCollapsed
                ? null
                : Text(
                    'Settings',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
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

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }
}
