import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/barrel.dart';

/// Tablet-optimized home screen with master-detail layout and large touch targets
class TabletHomeScreen extends ConsumerStatefulWidget {
  const TabletHomeScreen({super.key});

  @override
  ConsumerState<TabletHomeScreen> createState() => _TabletHomeScreenState();
}

class _TabletHomeScreenState extends ConsumerState<TabletHomeScreen>
    with TickerProviderStateMixin {
  int _selectedNavIndex = 0;
  String _selectedDetailView = 'overview';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<NavigationRailDestination> _navDestinations = [
    const NavigationRailDestination(
      icon: Icon(Icons.dashboard_outlined),
      selectedIcon: Icon(Icons.dashboard),
      label: Text('Overview'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.trending_up_outlined),
      selectedIcon: Icon(Icons.trending_up),
      label: Text('Progress'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.games_outlined),
      selectedIcon: Icon(Icons.games),
      label: Text('Games'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.smart_toy_outlined),
      selectedIcon: Icon(Icons.smart_toy),
      label: Text('AI Tutor'),
    ),
    const NavigationRailDestination(
      icon: Icon(Icons.emoji_events_outlined),
      selectedIcon: Icon(Icons.emoji_events),
      label: Text('Achievements'),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0.3, 0), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenSize = MediaQuery.of(context).size;
    final isPortrait = screenSize.height > screenSize.width;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: TabletUIEnhancements.tabletAppBar(
        title: 'Math Genius',
        themeData: themeData,
        colorScheme: colorScheme,
        actions: [
          _buildSearchButton(colorScheme),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(Icons.notifications_outlined, size: 28),
            onPressed: () => _showNotifications(context),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 16),
          _buildUserAvatar(themeData, colorScheme),
          const SizedBox(width: 20),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: TabletUIEnhancements.tabletMasterDetail(
          master: _buildMasterPane(themeData, colorScheme, isPortrait),
          detail: SlideTransition(
            position: _slideAnimation,
            child: _buildDetailPane(themeData, colorScheme, screenSize),
          ),
          colorScheme: colorScheme,
          showMasterInPortrait: true,
          isPortrait: isPortrait,
        ),
      ),
      floatingActionButton: TabletUIEnhancements.tabletFAB(
        onPressed: () => _startQuickGame(),
        colorScheme: colorScheme,
        isExtended: true,
        label: 'Quick Game',
        child: Icon(Icons.play_arrow, size: 24),
      ),
    );
  }

  Widget _buildSearchButton(ColorScheme colorScheme) {
    return Container(
      width: 200,
      height: 40,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: () => _showSearch(),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: colorScheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 8),
            Text(
              'Search...',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserAvatar(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _showUserMenu(),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(
              Icons.person,
              size: 20,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Student',
                style: themeData.typography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Level 7',
                style: themeData.typography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildMasterPane(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    bool isPortrait,
  ) {
    return Column(
      children: [
        // Welcome section
        Container(
          padding: const EdgeInsets.all(TabletLayoutConstants.contentPadding),
          child: TabletUIEnhancements.tabletCard(
            colorScheme: colorScheme,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.waving_hand,
                        color: colorScheme.onPrimaryContainer,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Welcome back!',
                            style: themeData.typography.titleLarge.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Ready to learn?',
                            style: themeData.typography.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStreakIndicator(themeData, colorScheme),
              ],
            ),
          ),
        ),

        // Navigation rail
        Expanded(
          child: TabletUIEnhancements.tabletNavigationRail(
            destinations: _navDestinations,
            selectedIndex: _selectedNavIndex,
            onDestinationSelected: (index) {
              setState(() {
                _selectedNavIndex = index;
                _selectedDetailView = _getDetailViewForIndex(index);
              });
              TabletUIEnhancements.triggerTabletHaptic();
            },
            colorScheme: colorScheme,
            themeData: themeData,
            extended: !isPortrait,
          ),
        ),

        // Quick actions
        Container(
          padding: const EdgeInsets.all(TabletLayoutConstants.contentPadding),
          child: Column(
            children: [
              TabletUIEnhancements.tabletButton(
                onPressed: () => context.go('/practice'),
                isPrimary: true,
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fitness_center, size: 20),
                    const SizedBox(width: 8),
                    Text('Practice'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TabletUIEnhancements.tabletButton(
                onPressed: () => context.go('/ai-tutor'),
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.smart_toy, size: 20),
                    const SizedBox(width: 8),
                    Text('AI Tutor'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStreakIndicator(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.1),
            colorScheme.secondary.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department, color: Colors.orange, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '7 Day Streak',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Keep it up!',
                style: themeData.typography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPane(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    return Container(
      padding: const EdgeInsets.all(TabletLayoutConstants.contentPadding),
      child: _buildDetailContent(
        _selectedDetailView,
        themeData,
        colorScheme,
        screenSize,
      ),
    );
  }

  Widget _buildDetailContent(
    String view,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    switch (view) {
      case 'overview':
        return _buildOverviewContent(themeData, colorScheme, screenSize);
      case 'progress':
        return _buildProgressContent(themeData, colorScheme, screenSize);
      case 'games':
        return _buildGamesContent(themeData, colorScheme, screenSize);
      case 'ai-tutor':
        return _buildAITutorContent(themeData, colorScheme, screenSize);
      case 'achievements':
        return _buildAchievementsContent(themeData, colorScheme, screenSize);
      default:
        return _buildOverviewContent(themeData, colorScheme, screenSize);
    }
  }

  Widget _buildOverviewContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Dashboard Overview',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TabletUIEnhancements.tabletButton(
                onPressed: () => _refreshData(),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh, size: 18),
                    const SizedBox(width: 8),
                    Text('Refresh'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: TabletLayoutConstants.sectionSpacing),

          // Stats grid
          _buildStatsGrid(themeData, colorScheme, screenSize),
          const SizedBox(height: TabletLayoutConstants.sectionSpacing),

          // Recent activity and quick actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildRecentActivityCard(themeData, colorScheme),
              ),
              const SizedBox(width: TabletLayoutConstants.cardSpacing),
              Expanded(
                flex: 1,
                child: _buildQuickActionsCard(themeData, colorScheme),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    final stats = [
      _StatItem('Total Score', '2,847', Icons.star, Colors.amber),
      _StatItem('Lessons Done', '156', Icons.check_circle, Colors.green),
      _StatItem('Accuracy', '94%', Icons.gps_fixed, Colors.blue),
      _StatItem('Time Spent', '24h', Icons.schedule, Colors.purple),
    ];

    return TabletUIEnhancements.tabletGridView(
      screenWidth: screenSize.width,
      childAspectRatio: 2.5,
      children: stats.map((stat) {
        return TabletUIEnhancements.tabletCard(
          colorScheme: colorScheme,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stat.icon, color: stat.color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      stat.value,
                      style: themeData.typography.headlineSmall.copyWith(
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
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentActivityCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return TabletUIEnhancements.tabletCard(
      colorScheme: colorScheme,
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
              TextButton(
                onPressed: () => context.go('/activity'),
                child: Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(4, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TabletUIEnhancements.tabletListTile(
                title: Text('Completed Addition Quiz Level ${index + 1}'),
                subtitle: Text('${index + 1} hour${index == 0 ? '' : 's'} ago'),
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                trailing: Chip(
                  label: Text('${95 - index * 2}%'),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: Colors.green),
                ),
                colorScheme: colorScheme,
                onTap: () => _viewActivityDetails(index),
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
        'New Game',
        Icons.play_arrow,
        () => context.go('/game-selection'),
      ),
      _ActionItem(
        'Practice',
        Icons.fitness_center,
        () => context.go('/practice'),
      ),
      _ActionItem('AI Help', Icons.smart_toy, () => context.go('/ai-tutor')),
      _ActionItem(
        'Live Session',
        Icons.video_call,
        () => context.go('/live-session'),
      ),
    ];

    return TabletUIEnhancements.tabletCard(
      colorScheme: colorScheme,
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
          ...actions.map((action) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                width: double.infinity,
                child: TabletUIEnhancements.tabletButton(
                  onPressed: () {
                    TabletUIEnhancements.triggerTabletHaptic(isSuccess: true);
                    action.onTap();
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(action.icon, size: 20),
                      const SizedBox(width: 8),
                      Text(action.title),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learning Progress',
            style: themeData.typography.headlineMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: TabletLayoutConstants.sectionSpacing),

          TabletUIEnhancements.tabletCard(
            colorScheme: colorScheme,
            child: Column(
              children: [
                _buildProgressItem(
                  'Addition',
                  85,
                  Colors.green,
                  themeData,
                  colorScheme,
                ),
                const SizedBox(height: 20),
                _buildProgressItem(
                  'Subtraction',
                  72,
                  Colors.blue,
                  themeData,
                  colorScheme,
                ),
                const SizedBox(height: 20),
                _buildProgressItem(
                  'Multiplication',
                  68,
                  Colors.orange,
                  themeData,
                  colorScheme,
                ),
                const SizedBox(height: 20),
                _buildProgressItem(
                  'Division',
                  45,
                  Colors.red,
                  themeData,
                  colorScheme,
                ),
              ],
            ),
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
              style: themeData.typography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$progress%',
              style: themeData.typography.titleLarge.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: progress / 100,
          backgroundColor: color.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildGamesContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Games Section',
            style: themeData.typography.headlineMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming Soon',
            style: themeData.typography.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAITutorContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'AI Tutor',
            style: themeData.typography.headlineMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal AI math tutor',
            style: themeData.typography.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Size screenSize,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.emoji_events, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Achievements',
            style: themeData.typography.headlineMedium.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your learning milestones',
            style: themeData.typography.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getDetailViewForIndex(int index) {
    switch (index) {
      case 0:
        return 'overview';
      case 1:
        return 'progress';
      case 2:
        return 'games';
      case 3:
        return 'ai-tutor';
      case 4:
        return 'achievements';
      default:
        return 'overview';
    }
  }

  void _showSearch() {
    TabletUIEnhancements.showTabletBottomSheet(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Search', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search lessons, games, progress...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _showUserMenu() {
    TabletUIEnhancements.showTabletDialog(
      context: context,
      width: 300,
      height: 200,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('User Menu', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.person),
              title: Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                context.go('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifications(BuildContext context) {
    TabletUIEnhancements.showTabletBottomSheet(
      context: context,
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Notifications',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text('No new notifications'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  }

  void _startQuickGame() {
    TabletUIEnhancements.triggerTabletHaptic(isSuccess: true);
    context.go('/game-selection');
  }

  void _refreshData() {
    TabletUIEnhancements.triggerTabletHaptic();
    // Implement refresh logic
  }

  void _viewActivityDetails(int index) {
    TabletUIEnhancements.triggerTabletHaptic();
    // Navigate to activity details
  }
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
