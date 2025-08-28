import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/barrel.dart';

/// Mobile-optimized home screen with touch-friendly interface
class MobileHomeScreen extends ConsumerStatefulWidget {
  const MobileHomeScreen({super.key});

  @override
  ConsumerState<MobileHomeScreen> createState() => _MobileHomeScreenState();
}

class _MobileHomeScreenState extends ConsumerState<MobileHomeScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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
    final platformService = ref.watch(platformServiceProvider);
    final platform = platformService.platformType;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: MobileUIEnhancements.mobileAppBar(
        title: 'Math Genius',
        themeData: themeData,
        colorScheme: colorScheme,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications_outlined),
            onPressed: () => _showNotifications(context, platform),
            tooltip: 'Notifications',
          ),
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: colorScheme.primaryContainer,
              child: Icon(
                Icons.person,
                size: 18,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            onPressed: () => context.go('/profile'),
            tooltip: 'Profile',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: _buildMobileContent(context, themeData, colorScheme, platform),
        ),
      ),
      floatingActionButton: MobileUIEnhancements.mobileFAB(
        onPressed: () => _startQuickGame(context, platform),
        colorScheme: colorScheme,
        isExtended: true,
        label: 'Quick Game',
        child: Icon(Icons.play_arrow),
      ),
    );
  }

  Widget _buildMobileContent(
    BuildContext context,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    PlatformType platform,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        // Refresh data
        await Future.delayed(const Duration(seconds: 1));
        MobileUIEnhancements.triggerHaptic(platform, isSuccess: true);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          left: context.adaptiveLayout.contentPadding,
          right: context.adaptiveLayout.contentPadding,
          top: context.adaptiveLayout.contentPadding,
          bottom: context.adaptiveLayout.contentPadding + 80, // FAB space
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(themeData, colorScheme, platform),
            SizedBox(height: context.adaptiveLayout.sectionSpacing),
            _buildProgressSection(themeData, colorScheme, platform),
            SizedBox(height: context.adaptiveLayout.sectionSpacing),
            _buildQuickActionsGrid(themeData, colorScheme, platform),
            SizedBox(height: context.adaptiveLayout.sectionSpacing),
            _buildRecentActivity(themeData, colorScheme, platform),
            SizedBox(height: context.adaptiveLayout.sectionSpacing),
            _buildAchievements(themeData, colorScheme, platform),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    PlatformType platform,
  ) {
    return MobileUIEnhancements.mobileCard(
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
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
                      style: themeData.typography.headlineSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready for today\'s math adventure?',
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
          Container(
            width: double.infinity,
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
            child: Column(
              children: [
                Text(
                  '7',
                  style: themeData.typography.displaySmall.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Day Streak',
                  style: themeData.typography.titleMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
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
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    PlatformType platform,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: themeData.typography.titleLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        MobileUIEnhancements.mobileCard(
          colorScheme: colorScheme,
          padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
          child: Column(
            children: [
              _buildProgressItem(
                'Addition',
                85,
                Colors.green,
                themeData,
                colorScheme,
              ),
              const SizedBox(height: 16),
              _buildProgressItem(
                'Subtraction',
                72,
                Colors.blue,
                themeData,
                colorScheme,
              ),
              const SizedBox(height: 16),
              _buildProgressItem(
                'Multiplication',
                68,
                Colors.orange,
                themeData,
                colorScheme,
              ),
              const SizedBox(height: 16),
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
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '$progress%',
              style: themeData.typography.titleMedium.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
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

  Widget _buildQuickActionsGrid(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    PlatformType platform,
  ) {
    final actions = [
      _ActionItem(
        title: 'Practice',
        icon: Icons.fitness_center,
        color: Colors.blue,
        onTap: () => context.go('/practice'),
      ),
      _ActionItem(
        title: 'AI Tutor',
        icon: Icons.smart_toy,
        color: Colors.purple,
        onTap: () => context.go('/ai-tutor'),
      ),
      _ActionItem(
        title: 'Games',
        icon: Icons.games,
        color: Colors.green,
        onTap: () => context.go('/games'),
      ),
      _ActionItem(
        title: 'Challenges',
        icon: Icons.emoji_events,
        color: Colors.orange,
        onTap: () => context.go('/challenges'),
      ),
    ];

    return Column(
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
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: context.adaptiveLayout.cardSpacing,
            mainAxisSpacing: context.adaptiveLayout.cardSpacing,
            childAspectRatio: 1.2,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return MobileUIEnhancements.mobileCard(
              colorScheme: colorScheme,
              padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
              onTap: () {
                MobileUIEnhancements.triggerHaptic(platform);
                action.onTap();
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: action.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(action.icon, color: action.color, size: 32),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    action.title,
                    style: themeData.typography.titleMedium.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildRecentActivity(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    PlatformType platform,
  ) {
    final activities = [
      'Completed Addition Quiz - 95% score',
      'Earned "Quick Learner" badge',
      'Practiced multiplication tables',
      'Helped friend with homework',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: themeData.typography.titleLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        MobileUIEnhancements.mobileCard(
          colorScheme: colorScheme,
          padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
          child: Column(
            children: activities.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              return Column(
                children: [
                  MobileUIEnhancements.mobileListTile(
                    title: Text(
                      activity,
                      style: themeData.typography.bodyLarge.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.primaryContainer,
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    trailing: Text(
                      '${index + 1}h ago',
                      style: themeData.typography.bodySmall.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    colorScheme: colorScheme,
                  ),
                  if (index < activities.length - 1)
                    Divider(
                      color: colorScheme.outline.withValues(alpha: 0.2),
                      height: 1,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    PlatformType platform,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Achievements',
              style: themeData.typography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.go('/achievements'),
              child: Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: 5,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final isUnlocked = index < 3;
              return Container(
                width: 100,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isUnlocked
                      ? colorScheme.primaryContainer
                      : colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isUnlocked
                        ? colorScheme.primary.withValues(alpha: 0.3)
                        : colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isUnlocked ? Icons.emoji_events : Icons.lock_outline,
                      color: isUnlocked
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isUnlocked ? 'Math Star' : 'Locked',
                      style: themeData.typography.bodySmall.copyWith(
                        color: isUnlocked
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showNotifications(BuildContext context, PlatformType platform) {
    MobileUIEnhancements.triggerHaptic(platform);
    MobileUIEnhancements.showMobileBottomSheet(
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

  void _startQuickGame(BuildContext context, PlatformType platform) {
    MobileUIEnhancements.triggerHaptic(platform, isSuccess: true);
    context.go('/game-selection');
  }
}

class _ActionItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  _ActionItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
