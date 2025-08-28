import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/barrel.dart';

/// Desktop-optimized home screen with multi-pane layout and keyboard shortcuts
class DesktopHomeScreen extends ConsumerStatefulWidget {
  const DesktopHomeScreen({super.key});

  @override
  ConsumerState<DesktopHomeScreen> createState() => _DesktopHomeScreenState();
}

class _DesktopHomeScreenState extends ConsumerState<DesktopHomeScreen>
    with TickerProviderStateMixin {
  bool _isSidebarCollapsed = false;
  String _selectedView = 'overview';
  late AnimationController _animationController;

  final Map<LogicalKeySet, VoidCallback> _shortcuts = {};

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _setupKeyboardShortcuts();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    _shortcuts.addAll({
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.digit1,
      ): () =>
          _selectView('overview'),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.digit2,
      ): () =>
          _selectView('progress'),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.digit3,
      ): () =>
          _selectView('games'),
      LogicalKeySet(
        LogicalKeyboardKey.control,
        LogicalKeyboardKey.digit4,
      ): () =>
          _selectView('achievements'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyN): () =>
          context.go('/game-selection'),
      LogicalKeySet(LogicalKeyboardKey.control, LogicalKeyboardKey.keyS): () =>
          context.go('/settings'),
      LogicalKeySet(LogicalKeyboardKey.f11): () => _toggleFullscreen(),
    });
  }

  void _selectView(String view) {
    setState(() {
      _selectedView = view;
    });
  }

  void _toggleFullscreen() {
    // Platform-specific fullscreen implementation would go here
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return DesktopUIEnhancements.keyboardShortcuts(
      shortcuts: _shortcuts,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: DesktopUIEnhancements.desktopAppBar(
          title: 'Math Genius - Dashboard',
          themeData: themeData,
          colorScheme: colorScheme,
          actions: [
            _buildSearchField(colorScheme),
            const SizedBox(width: 16),
            IconButton(
              icon: Icon(Icons.notifications_outlined),
              onPressed: () => _showNotifications(context),
              tooltip: 'Notifications (Ctrl+N)',
            ),
            const SizedBox(width: 8),
            _buildUserMenu(themeData, colorScheme),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          children: [
            // Sidebar
            DesktopUIEnhancements.desktopSidebar(
              colorScheme: colorScheme,
              themeData: themeData,
              isCollapsed: _isSidebarCollapsed,
              onToggleCollapse: () {
                setState(() {
                  _isSidebarCollapsed = !_isSidebarCollapsed;
                });
              },
              children: _buildSidebarItems(themeData, colorScheme),
            ),
            // Main content area
            Expanded(child: _buildMainContent(themeData, colorScheme)),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(ColorScheme colorScheme) {
    return SizedBox(
      width: 300,
      height: 40,
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search lessons, games, progress...',
          prefixIcon: Icon(Icons.search, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  Widget _buildUserMenu(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return PopupMenuButton<String>(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 18,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          if (!_isSidebarCollapsed) ...[
            Text(
              'Student',
              style: themeData.typography.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
          ],
        ],
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'profile',
          child: ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Profile'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'logout',
          child: ListTile(
            leading: Icon(Icons.logout),
            title: Text('Sign Out'),
            dense: true,
          ),
        ),
      ],
      onSelected: (value) {
        switch (value) {
          case 'profile':
            context.go('/profile');
            break;
          case 'settings':
            context.go('/settings');
            break;
          case 'logout':
            // Handle logout
            break;
        }
      },
    );
  }

  List<Widget> _buildSidebarItems(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final items = [
      _SidebarItem('overview', 'Overview', Icons.dashboard_outlined, 'Ctrl+1'),
      _SidebarItem('progress', 'Progress', Icons.trending_up, 'Ctrl+2'),
      _SidebarItem('games', 'Games', Icons.games_outlined, 'Ctrl+3'),
      _SidebarItem(
        'achievements',
        'Achievements',
        Icons.emoji_events_outlined,
        'Ctrl+4',
      ),
      _SidebarItem('ai-tutor', 'AI Tutor', Icons.smart_toy_outlined, ''),
      _SidebarItem(
        'live-session',
        'Live Sessions',
        Icons.video_call_outlined,
        '',
      ),
      _SidebarItem('family', 'Family', Icons.family_restroom_outlined, ''),
    ];

    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: DesktopUIEnhancements.desktopNavItem(
          title: item.title,
          icon: item.icon,
          onTap: () => _selectView(item.id),
          colorScheme: colorScheme,
          themeData: themeData,
          isActive: _selectedView == item.id,
          isCollapsed: _isSidebarCollapsed,
          tooltip: _isSidebarCollapsed
              ? '${item.title} ${item.shortcut}'
              : null,
        ),
      );
    }).toList();
  }

  Widget _buildMainContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(_selectedView),
        padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
        child: _buildContentForView(_selectedView, themeData, colorScheme),
      ),
    );
  }

  Widget _buildContentForView(
    String view,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    switch (view) {
      case 'overview':
        return _buildOverviewContent(themeData, colorScheme);
      case 'progress':
        return _buildProgressContent(themeData, colorScheme);
      case 'games':
        return _buildGamesContent(themeData, colorScheme);
      case 'achievements':
        return _buildAchievementsContent(themeData, colorScheme);
      default:
        return _buildOverviewContent(themeData, colorScheme);
    }
  }

  Widget _buildOverviewContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats
          _buildStatsRow(themeData, colorScheme),
          SizedBox(height: context.adaptiveLayout.sectionSpacing),

          // Main content grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left column
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRecentActivityCard(themeData, colorScheme),
                    SizedBox(height: context.adaptiveLayout.cardSpacing),
                    _buildQuickActionsCard(themeData, colorScheme),
                  ],
                ),
              ),
              SizedBox(width: context.adaptiveLayout.cardSpacing),

              // Right column
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgressSummaryCard(themeData, colorScheme),
                    SizedBox(height: context.adaptiveLayout.cardSpacing),
                    _buildUpcomingCard(themeData, colorScheme),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final stats = [
      _StatItem('Total Score', '2,847', Icons.star, Colors.amber),
      _StatItem('Streak', '7 days', Icons.local_fire_department, Colors.orange),
      _StatItem('Completed', '156', Icons.check_circle, Colors.green),
      _StatItem('Accuracy', '94%', Icons.gps_fixed, Colors.blue),
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 16),
            child: DesktopUIEnhancements.desktopCard(
              colorScheme: colorScheme,
              padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: stat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(stat.icon, color: stat.color, size: 20),
                      ),
                      const Spacer(),
                      Icon(Icons.trending_up, color: Colors.green, size: 16),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    stat.value,
                    style: themeData.typography.headlineMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    stat.label,
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivityCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return DesktopUIEnhancements.desktopCard(
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: themeData.typography.titleLarge.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(onPressed: () {}, child: Text('View All')),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(5, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: colorScheme.primaryContainer,
                    child: Icon(
                      Icons.check_circle,
                      size: 16,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Completed Addition Quiz Level ${index + 1}',
                          style: themeData.typography.bodyLarge.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          '${index + 1} hour${index == 0 ? '' : 's'} ago',
                          style: themeData.typography.bodySmall.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${95 - index * 2}%',
                    style: themeData.typography.titleSmall.copyWith(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final actions = [
      _ActionItem(
        'Start New Game',
        Icons.play_arrow,
        () => context.go('/game-selection'),
      ),
      _ActionItem(
        'Practice Mode',
        Icons.fitness_center,
        () => context.go('/practice'),
      ),
      _ActionItem(
        'AI Tutor Session',
        Icons.smart_toy,
        () => context.go('/ai-tutor'),
      ),
      _ActionItem(
        'Join Live Session',
        Icons.video_call,
        () => context.go('/live-session'),
      ),
    ];

    return DesktopUIEnhancements.desktopCard(
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: themeData.typography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: actions.length,
            itemBuilder: (context, index) {
              final action = actions[index];
              return DesktopUIEnhancements.desktopButton(
                onPressed: action.onTap,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(action.icon, size: 18),
                    const SizedBox(width: 8),
                    Text(action.title),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummaryCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return DesktopUIEnhancements.desktopCard(
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Summary',
            style: themeData.typography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildProgressItem(
            'Addition',
            85,
            Colors.green,
            themeData,
            colorScheme,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            'Subtraction',
            72,
            Colors.blue,
            themeData,
            colorScheme,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            'Multiplication',
            68,
            Colors.orange,
            themeData,
            colorScheme,
          ),
          const SizedBox(height: 12),
          _buildProgressItem(
            'Division',
            45,
            Colors.red,
            themeData,
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
    String subject,
    int progress,
    Color color,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              subject,
              style: themeData.typography.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$progress%',
              style: themeData.typography.titleSmall.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
          borderRadius: BorderRadius.circular(3),
        ),
      ],
    );
  }

  Widget _buildUpcomingCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return DesktopUIEnhancements.desktopCard(
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upcoming',
            style: themeData.typography.titleLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.event, color: colorScheme.primary),
            title: Text('Math Challenge'),
            subtitle: Text('Tomorrow at 3:00 PM'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.video_call, color: colorScheme.secondary),
            title: Text('Live Tutoring'),
            subtitle: Text('Friday at 4:00 PM'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildProgressContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Text(
        'Progress View - Coming Soon',
        style: themeData.typography.headlineMedium,
      ),
    );
  }

  Widget _buildGamesContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Text(
        'Games View - Coming Soon',
        style: themeData.typography.headlineMedium,
      ),
    );
  }

  Widget _buildAchievementsContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Center(
      child: Text(
        'Achievements View - Coming Soon',
        style: themeData.typography.headlineMedium,
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    DesktopUIEnhancements.showDesktopDialog(
      context: context,
      width: 400,
      height: 300,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Expanded(child: Center(child: Text('No new notifications'))),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem {
  final String id;
  final String title;
  final IconData icon;
  final String shortcut;

  _SidebarItem(this.id, this.title, this.icon, this.shortcut);
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}

class _ActionItem {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  _ActionItem(this.title, this.icon, this.onTap);
}
