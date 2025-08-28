import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../../core/barrel.dart';
import '../../../../core/theme/design_system.dart';

/// Student Dashboard Component
/// Main dashboard with welcome, stats, activities, and achievements
class StudentDashboard extends ConsumerWidget {
  const StudentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenType = ref.watch(screenTypeProvider);

    return _buildDashboardLayout(themeData, colorScheme, screenType, context);
  }

  Widget _buildDashboardLayout(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    ScreenType screenType,
    BuildContext context,
  ) {
    switch (screenType) {
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return _buildDesktopDashboard(themeData, colorScheme, context);
      case ScreenType.tablet:
        return _buildTabletDashboard(themeData, colorScheme, context);
      case ScreenType.mobile:
        return _buildMobileDashboard(themeData, colorScheme, context);
    }
  }

  Widget _buildDesktopDashboard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: DesignSystem.padding24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row - Welcome and Quick Stats
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: _buildWelcomeSection(context, themeData, colorScheme),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildQuickStatsSection(context, themeData, colorScheme),
              ),
            ],
          ),
          DesignSystem.gap24,
          // Middle Row - Learning Activities and Recent Achievements
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 1,
                child: _buildLearningActivitiesSection(
                  themeData,
                  colorScheme,
                  context,
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 1,
                child: _buildRecentAchievementsSection(
                  context,
                  themeData,
                  colorScheme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletDashboard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: DesignSystem.padding20,
      child: Column(
        children: [
          _buildWelcomeSection(context, themeData, colorScheme),
          DesignSystem.gap16,
          _buildQuickStatsSection(context, themeData, colorScheme),
          DesignSystem.gap16,
          _buildLearningActivitiesSection(themeData, colorScheme, context),
          DesignSystem.gap16,
          _buildRecentAchievementsSection(context, themeData, colorScheme),
        ],
      ),
    );
  }

  Widget _buildMobileDashboard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return SingleChildScrollView(
      padding: DesignSystem.padding16,
      child: Column(
        children: [
          _buildWelcomeSection(context, themeData, colorScheme),
          DesignSystem.gap12,
          _buildQuickStatsSection(context, themeData, colorScheme),
          DesignSystem.gap12,
          _buildLearningActivitiesSection(themeData, colorScheme, context),
          DesignSystem.gap12,
          _buildRecentAchievementsSection(context, themeData, colorScheme),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection(
    BuildContext context,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return AdaptiveUISystem.adaptiveCard(
      context: context,
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: colorScheme.primary,
                size: DesignSystem.iconSize24,
              ),
              const SizedBox(width: 8),
              Text(
                '🎯 Today\'s Learning Goal',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          DesignSystem.gap16,
          Text(
            'Complete 10 addition problems with 90% accuracy',
            style: themeData.typography.bodyLarge.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          DesignSystem.gap16,
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '80%',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: 0.8,
                backgroundColor: colorScheme.outline.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ],
          ),
          DesignSystem.gap16,
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Continue learning action
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Continue Learning'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Start new topic action
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Start New Topic'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.primary,
                    side: BorderSide(color: colorScheme.primary),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsSection(
    BuildContext context,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return AdaptiveUISystem.adaptiveCard(
      context: context,
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics,
                color: colorScheme.primary,
                size: DesignSystem.iconSize24,
              ),
              const SizedBox(width: 8),
              Text(
                '📈 Your Progress',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          DesignSystem.gap16,
          // Stats Grid
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Questions',
                  '156',
                  'Answered',
                  colorScheme.primary,
                  themeData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Accuracy',
                  '87%',
                  'Overall',
                  colorScheme.secondary,
                  themeData,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Streak',
                  '7',
                  'Days',
                  colorScheme.tertiary,
                  themeData,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    String subtitle,
    Color color,
    MathGeniusThemeData themeData,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: themeData.typography.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: themeData.typography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            subtitle,
            style: themeData.typography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLearningActivitiesSection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    BuildContext context,
  ) {
    return AdaptiveUISystem.adaptiveCard(
      context: context,
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.games,
                color: colorScheme.primary,
                size: DesignSystem.iconSize24,
              ),
              const SizedBox(width: 8),
              Text(
                '🎮 Quick Practice',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          DesignSystem.gap16,
          // Activities Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: [
              _buildActivityCard(
                '➕ Addition',
                '5 min',
                Icons.add,
                colorScheme.primary,
                themeData,
                colorScheme,
              ),
              _buildActivityCard(
                '➖ Subtraction',
                '5 min',
                Icons.remove,
                colorScheme.secondary,
                themeData,
                colorScheme,
              ),
              _buildActivityCard(
                '✖️ Multiplication',
                '5 min',
                Icons.close,
                colorScheme.tertiary,
                themeData,
                colorScheme,
              ),
              _buildActivityCard(
                '➗ Division',
                '5 min',
                Icons.call_split,
                colorScheme.outline,
                themeData,
                colorScheme,
              ),
            ],
          ),
          DesignSystem.gap16,
          Center(
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed('/student/games');
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Play Math Games'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(
    String title,
    String duration,
    IconData icon,
    Color color,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            title,
            style: themeData.typography.bodySmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            duration,
            style: themeData.typography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAchievementsSection(
    BuildContext context,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return AdaptiveUISystem.adaptiveCard(
      context: context,
      colorScheme: colorScheme,
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: colorScheme.primary,
                size: DesignSystem.iconSize24,
              ),
              const SizedBox(width: 8),
              Text(
                '🏆 Recent Achievements',
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          DesignSystem.gap16,
          // Achievements List
          Column(
            children: [
              _buildAchievementItem(
                '🥇 Perfect Score - Addition (10/10)',
                'Just earned',
                Colors.amber,
                themeData,
                colorScheme,
              ),
              _buildAchievementItem(
                '🎯 5-Day Streak - Daily Practice',
                '2 days ago',
                colorScheme.primary,
                themeData,
                colorScheme,
              ),
              _buildAchievementItem(
                '🚀 Speed Master - 20 questions in 5 minutes',
                '1 week ago',
                colorScheme.secondary,
                themeData,
                colorScheme,
              ),
            ],
          ),
          DesignSystem.gap16,
          Center(
            child: TextButton.icon(
              onPressed: () {
                // View all achievements action
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('View All Achievements'),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementItem(
    String title,
    String timeAgo,
    Color color,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: themeData.typography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  timeAgo,
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
}
