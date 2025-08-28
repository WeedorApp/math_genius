import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/barrel.dart';

/// Web-optimized home screen with PWA features and responsive design
class WebHomeScreen extends ConsumerStatefulWidget {
  const WebHomeScreen({super.key});

  @override
  ConsumerState<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends ConsumerState<WebHomeScreen>
    with TickerProviderStateMixin {
  late TextEditingController _searchController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  String _selectedCategory = 'all';
  bool _showInstallPrompt = false;

  final Map<String, VoidCallback> _keyboardShortcuts = {};

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _setupKeyboardShortcuts();
    _checkPWAStatus();
    _animationController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _setupKeyboardShortcuts() {
    _keyboardShortcuts.addAll({
      'ctrl+k': () => _focusSearch(),
      'ctrl+n': () => context.go('/game-selection'),
      'ctrl+p': () => context.go('/practice'),
      'ctrl+t': () => context.go('/ai-tutor'),
      'ctrl+s': () => context.go('/settings'),
      'ctrl+h': () => _showKeyboardShortcuts(),
    });
  }

  void _checkPWAStatus() {
    if (!WebUIEnhancements.isPWA()) {
      // Show install prompt after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showInstallPrompt = true;
          });
        }
      });
    }
  }

  void _focusSearch() {
    // Focus search field
  }

  void _showKeyboardShortcuts() {
    WebUIEnhancements.showWebDialog(
      context: context,
      width: 500,
      height: 400,
      child: _buildKeyboardShortcutsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenWidth = MediaQuery.of(context).size.width;

    return WebUIEnhancements.webKeyboardShortcuts(
      shortcuts: _keyboardShortcuts,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              // Install prompt banner
              if (_showInstallPrompt) _buildInstallPromptBanner(colorScheme),

              // Navigation bar with breadcrumbs
              WebUIEnhancements.webNavigationBar(
                breadcrumbs: ['Home', 'Dashboard'],
                themeData: themeData,
                colorScheme: colorScheme,
                actions: [
                  WebUIEnhancements.webSearchField(
                    controller: _searchController,
                    colorScheme: colorScheme,
                    hintText: 'Search lessons, games, progress... (Ctrl+K)',
                    onChanged: _handleSearch,
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(Icons.notifications_outlined),
                    onPressed: () => _showNotifications(),
                    tooltip: 'Notifications',
                  ),
                  const SizedBox(width: 8),
                  _buildUserMenu(themeData, colorScheme),
                  const SizedBox(width: 16),
                ],
              ),

              // Main content
              Expanded(
                child: WebUIEnhancements.webContainer(
                  maxWidth: WebLayoutConstants.maxContentWidth,
                  padding: EdgeInsets.all(
                    context.adaptiveLayout.contentPadding,
                  ),
                  child: _buildWebContent(screenWidth, themeData, colorScheme),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: _buildWebFAB(colorScheme),
      ),
    );
  }

  Widget _buildInstallPromptBanner(ColorScheme colorScheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        border: Border(
          bottom: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.install_mobile,
            color: colorScheme.onPrimaryContainer,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Install Math Genius for the best experience - works offline!',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _showInstallPrompt = false;
              });
            },
            child: Text(
              'Maybe Later',
              style: TextStyle(color: colorScheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              WebUIEnhancements.showInstallPrompt(context);
              setState(() {
                _showInstallPrompt = false;
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: Text('Install'),
          ),
        ],
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
          Text(
            'Student',
            style: themeData.typography.titleSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
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
            trailing: Text('Ctrl+S', style: TextStyle(fontSize: 12)),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'shortcuts',
          child: ListTile(
            leading: Icon(Icons.keyboard_outlined),
            title: Text('Keyboard Shortcuts'),
            trailing: Text('Ctrl+H', style: TextStyle(fontSize: 12)),
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
          case 'shortcuts':
            _showKeyboardShortcuts();
            break;
          case 'logout':
            // Handle logout
            break;
        }
      },
    );
  }

  Widget _buildWebContent(
    double screenWidth,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final isLargeScreen = screenWidth > WebLayoutConstants.desktopBreakpoint;
    final isTablet =
        screenWidth > WebLayoutConstants.tabletBreakpoint &&
        screenWidth <= WebLayoutConstants.desktopBreakpoint;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero section
          _buildHeroSection(themeData, colorScheme, isLargeScreen),
          const SizedBox(height: WebLayoutConstants.sectionSpacing),

          // Stats overview
          _buildStatsSection(themeData, colorScheme, isLargeScreen, isTablet),
          const SizedBox(height: WebLayoutConstants.sectionSpacing),

          // Category filter
          _buildCategoryFilter(themeData, colorScheme),
          const SizedBox(height: WebLayoutConstants.cardSpacing),

          // Main content grid
          _buildContentGrid(themeData, colorScheme, isLargeScreen, isTablet),
          const SizedBox(height: WebLayoutConstants.sectionSpacing),

          // Recent activity and progress
          _buildBottomSection(themeData, colorScheme, isLargeScreen),
        ],
      ),
    );
  }

  Widget _buildHeroSection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    bool isLargeScreen,
  ) {
    return WebUIEnhancements.webCard(
      colorScheme: colorScheme,
      padding: EdgeInsets.all(isLargeScreen ? 40 : 24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome back to Math Genius!',
                  style: themeData.typography.displaySmall.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Continue your mathematical journey with AI-powered learning, interactive games, and personalized progress tracking.',
                  style: themeData.typography.bodyLarge.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    WebUIEnhancements.webButton(
                      onPressed: () => context.go('/game-selection'),
                      isPrimary: true,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow, size: 18),
                          const SizedBox(width: 8),
                          Text('Start Learning'),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    WebUIEnhancements.webButton(
                      onPressed: () => context.go('/ai-tutor'),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.smart_toy, size: 18),
                          const SizedBox(width: 8),
                          Text('AI Tutor'),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isLargeScreen) ...[
            const SizedBox(width: 40),
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.2),
                    colorScheme.secondary.withValues(alpha: 0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(Icons.school, size: 80, color: colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    bool isLargeScreen,
    bool isTablet,
  ) {
    final stats = [
      _StatItem(
        'Learning Streak',
        '7 days',
        Icons.local_fire_department,
        Colors.orange,
      ),
      _StatItem('Total Score', '2,847', Icons.star, Colors.amber),
      _StatItem('Lessons Completed', '156', Icons.check_circle, Colors.green),
      _StatItem('Average Accuracy', '94%', Icons.gps_fixed, Colors.blue),
    ];

    final crossAxisCount = isLargeScreen ? 4 : (isTablet ? 2 : 1);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: WebLayoutConstants.cardSpacing,
        mainAxisSpacing: WebLayoutConstants.cardSpacing,
        childAspectRatio: 2.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return WebUIEnhancements.webCard(
          colorScheme: colorScheme,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: stat.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(stat.icon, color: stat.color, size: 24),
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
      },
    );
  }

  Widget _buildCategoryFilter(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final categories = [
      _CategoryItem('all', 'All Topics'),
      _CategoryItem('arithmetic', 'Arithmetic'),
      _CategoryItem('algebra', 'Algebra'),
      _CategoryItem('geometry', 'Geometry'),
      _CategoryItem('statistics', 'Statistics'),
    ];

    return Row(
      children: [
        Text(
          'Categories:',
          style: themeData.typography.titleMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Wrap(
            spacing: 8,
            children: categories.map((category) {
              final isSelected = _selectedCategory == category.id;
              return FilterChip(
                label: Text(category.title),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category.id;
                  });
                },
                backgroundColor: colorScheme.surfaceContainerHighest,
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildContentGrid(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    bool isLargeScreen,
    bool isTablet,
  ) {
    final crossAxisCount = isLargeScreen ? 3 : (isTablet ? 2 : 1);

    final items = [
      _ContentItem(
        'Quick Practice',
        'Sharpen your skills with quick exercises',
        Icons.fitness_center,
        Colors.blue,
      ),
      _ContentItem(
        'Math Games',
        'Learn through fun and interactive games',
        Icons.games,
        Colors.green,
      ),
      _ContentItem(
        'AI Tutor',
        'Get personalized help from our AI tutor',
        Icons.smart_toy,
        Colors.purple,
      ),
      _ContentItem(
        'Live Sessions',
        'Join live learning sessions',
        Icons.video_call,
        Colors.orange,
      ),
      _ContentItem(
        'Progress Tracking',
        'Monitor your learning journey',
        Icons.analytics,
        Colors.teal,
      ),
      _ContentItem(
        'Achievements',
        'Unlock badges and rewards',
        Icons.emoji_events,
        Colors.amber,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: WebLayoutConstants.cardSpacing,
        mainAxisSpacing: WebLayoutConstants.cardSpacing,
        childAspectRatio: 1.2,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return WebUIEnhancements.webCard(
          colorScheme: colorScheme,
          isClickable: true,
          onTap: () => _handleContentItemTap(item),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item.icon, color: item.color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                item.title,
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                item.description,
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomSection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    bool isLargeScreen,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: _buildRecentActivityCard(themeData, colorScheme),
        ),
        const SizedBox(width: WebLayoutConstants.cardSpacing),
        Expanded(flex: 1, child: _buildProgressCard(themeData, colorScheme)),
      ],
    );
  }

  Widget _buildRecentActivityCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return WebUIEnhancements.webCard(
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
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primaryContainer,
                  child: Icon(
                    Icons.check_circle,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text('Completed Algebra Quiz Level ${index + 1}'),
                subtitle: Text('${index + 1} hour${index == 0 ? '' : 's'} ago'),
                trailing: Chip(
                  label: Text('${95 - index * 3}%'),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  labelStyle: TextStyle(color: Colors.green),
                ),
                contentPadding: EdgeInsets.zero,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildProgressCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return WebUIEnhancements.webCard(
      colorScheme: colorScheme,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progress Overview',
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

  Widget _buildWebFAB(ColorScheme colorScheme) {
    return FloatingActionButton.extended(
      onPressed: () => context.go('/game-selection'),
      icon: Icon(Icons.play_arrow),
      label: Text('Quick Start'),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      tooltip: 'Start a quick game (Ctrl+N)',
    );
  }

  Widget _buildKeyboardShortcutsDialog() {
    final shortcuts = [
      'Ctrl+K - Focus search',
      'Ctrl+N - New game',
      'Ctrl+P - Practice mode',
      'Ctrl+T - AI Tutor',
      'Ctrl+S - Settings',
      'Ctrl+H - Show shortcuts',
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Text(
            'Keyboard Shortcuts',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: shortcuts.length,
              itemBuilder: (context, index) {
                return ListTile(title: Text(shortcuts[index]), dense: true);
              },
            ),
          ),
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
    );
  }

  void _handleSearch(String query) {
    // Implement search functionality
  }

  void _handleContentItemTap(_ContentItem item) {
    switch (item.title) {
      case 'Quick Practice':
        context.go('/practice');
        break;
      case 'Math Games':
        context.go('/games');
        break;
      case 'AI Tutor':
        context.go('/ai-tutor');
        break;
      case 'Live Sessions':
        context.go('/live-session');
        break;
      case 'Progress Tracking':
        context.go('/progress');
        break;
      case 'Achievements':
        context.go('/achievements');
        break;
    }
  }

  void _showNotifications() {
    WebUIEnhancements.showWebDialog(
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

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _StatItem(this.label, this.value, this.icon, this.color);
}

class _CategoryItem {
  final String id;
  final String title;

  _CategoryItem(this.id, this.title);
}

class _ContentItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  _ContentItem(this.title, this.description, this.icon, this.color);
}
