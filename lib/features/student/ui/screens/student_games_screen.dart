import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../../../../core/barrel.dart' hide MathProblem;
import '../../../../core/theme/design_system.dart';

/// Student Games Screen
/// Games selection and management for students
class StudentGamesScreen extends ConsumerStatefulWidget {
  const StudentGamesScreen({super.key});

  @override
  ConsumerState<StudentGamesScreen> createState() => _StudentGamesScreenState();
}

class _StudentGamesScreenState extends ConsumerState<StudentGamesScreen> {
  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenType = ref.watch(screenTypeProvider);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: _buildGamesLayout(themeData, colorScheme, screenType),
      ),
    );
  }

  Widget _buildGamesLayout(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    ScreenType screenType,
  ) {
    switch (screenType) {
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return _buildDesktopGamesLayout(themeData, colorScheme);
      case ScreenType.tablet:
        return _buildTabletGamesLayout(themeData, colorScheme);
      case ScreenType.mobile:
        return _buildMobileGamesLayout(themeData, colorScheme);
    }
  }

  Widget _buildDesktopGamesLayout(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Row(
      children: [
        // Games area
        Expanded(flex: 2, child: _buildGamesArea(themeData, colorScheme)),
        // Stats panel
        Expanded(child: _buildStatsPanel(themeData, colorScheme)),
      ],
    );
  }

  Widget _buildTabletGamesLayout(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Stats panel
        _buildStatsPanel(themeData, colorScheme),
        // Games area
        Expanded(child: _buildGamesArea(themeData, colorScheme)),
      ],
    );
  }

  Widget _buildMobileGamesLayout(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Stats panel
        _buildStatsPanel(themeData, colorScheme),
        // Games area
        Expanded(child: _buildGamesArea(themeData, colorScheme)),
      ],
    );
  }

  Widget _buildGamesArea(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: DesignSystem.padding24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            'Math Games',
            style: themeData.typography.headlineLarge.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          DesignSystem.gap16,
          Text(
            'Choose a game to practice your math skills!',
            style: themeData.typography.bodyLarge.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          DesignSystem.gap32,
          // Games Grid
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 1.2,
              children: [
                _buildGameCard(
                  themeData,
                  colorScheme,
                  'Math Challenge',
                  'Test your skills with mixed problems',
                  Icons.quiz,
                  Colors.blue,
                  () => _startMathChallenge(context),
                ),
                _buildGameCard(
                  themeData,
                  colorScheme,
                  'Addition Practice',
                  'Focus on addition skills',
                  Icons.add,
                  Colors.green,
                  () => _startAdditionGame(context),
                ),
                _buildGameCard(
                  themeData,
                  colorScheme,
                  'Subtraction Practice',
                  'Master subtraction techniques',
                  Icons.remove,
                  Colors.orange,
                  () => _startSubtractionGame(context),
                ),
                _buildGameCard(
                  themeData,
                  colorScheme,
                  'Multiplication Practice',
                  'Learn multiplication tables',
                  Icons.close,
                  Colors.purple,
                  () => _startMultiplicationGame(context),
                ),
                _buildGameCard(
                  themeData,
                  colorScheme,
                  'Division Practice',
                  'Practice division skills',
                  Icons.call_split,
                  Colors.red,
                  () => _startDivisionGame(context),
                ),
                _buildGameCard(
                  themeData,
                  colorScheme,
                  'Speed Math',
                  'Quick mental math challenges',
                  Icons.timer,
                  Colors.teal,
                  () => _startSpeedMath(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return AdaptiveUISystem.adaptiveCard(
      context: context,
      colorScheme: colorScheme,
      onTap: onTap,
      isClickable: true,
      child: Padding(
        padding: DesignSystem.padding20,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              DesignSystem.gap16,
              Text(
                title,
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              DesignSystem.gap8,
              Text(
                description,
                style: themeData.typography.bodySmall.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsPanel(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    // Mock data since service was removed
    final stats = {'currentScore': 0, 'totalGamesPlayed': 0, 'accuracy': 0};
    final levelInfo = {'currentLevel': 1, 'maxLevel': 10, 'progress': 0};
    final achievements = <Map<String, dynamic>>[];

    return Container(
      padding: DesignSystem.padding20,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        border: Border(
          left: BorderSide(color: colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Game Stats',
            style: themeData.typography.headlineSmall.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          DesignSystem.gap16,
          _buildStatItem(
            themeData,
            colorScheme,
            'Current Level',
            '${levelInfo['currentLevel']} / ${levelInfo['maxLevel']}',
            Icons.trending_up,
          ),
          _buildStatItem(
            themeData,
            colorScheme,
            'Total Score',
            stats['currentScore'].toString(),
            Icons.stars,
          ),
          _buildStatItem(
            themeData,
            colorScheme,
            'Games Played',
            stats['totalGamesPlayed'].toString(),
            Icons.games,
          ),
          _buildStatItem(
            themeData,
            colorScheme,
            'Accuracy',
            '${stats['accuracy']}%',
            Icons.check_circle,
            color: Colors.green,
          ),
          DesignSystem.gap16,
          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Level Progress',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  Text(
                    '${levelInfo['progress']}%',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              DesignSystem.gap8,
              LinearProgressIndicator(
                value: (levelInfo['progress'] as int) / 100,
                backgroundColor: colorScheme.surface,
                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
              ),
            ],
          ),
          DesignSystem.gap24,
          // Recent achievements
          Text(
            'Recent Achievements',
            style: themeData.typography.titleMedium.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          DesignSystem.gap12,
          if (achievements.isEmpty)
            Text(
              'No achievements yet. Keep playing to earn badges!',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            )
          else
            ...achievements
                .take(3)
                .map(
                  (achievement) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(
                          achievement['icon'],
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            achievement['title'],
                            style: themeData.typography.bodySmall.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? colorScheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: themeData.typography.bodyMedium.copyWith(
              color: color ?? colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _startMathChallenge(BuildContext context) {
    context.push('/game-selection');
  }

  void _startAdditionGame(BuildContext context) {
    // For now, start the same game but could be customized
    context.push('/game-selection');
  }

  void _startSubtractionGame(BuildContext context) {
    context.push('/game-selection');
  }

  void _startMultiplicationGame(BuildContext context) {
    context.push('/game-selection');
  }

  void _startDivisionGame(BuildContext context) {
    context.push('/game-selection');
  }

  void _startSpeedMath(BuildContext context) {
    context.push('/game-selection');
  }
}
