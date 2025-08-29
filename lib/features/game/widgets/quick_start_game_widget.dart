import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../../../core/barrel.dart';

// Game imports
import '../models/game_model.dart';
import 'classic_quiz_screen.dart';
import 'ai_native_game_screen.dart';
import 'chatgpt_enhanced_game_screen.dart';

/// Quick Start Game Widget - One-click game launch with smart defaults
class QuickStartGameWidget extends ConsumerStatefulWidget {
  const QuickStartGameWidget({super.key});

  @override
  ConsumerState<QuickStartGameWidget> createState() => _QuickStartGameWidgetState();
}

class _QuickStartGameWidgetState extends ConsumerState<QuickStartGameWidget> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    final layout = context.adaptiveLayout;
    final quickStartConfig = ref.watch(quickStartConfigProvider);
    final recentGames = ref.watch(recentGamesProvider);

    return quickStartConfig.when(
      data: (config) => _buildQuickStartContent(context, layout, config, recentGames),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => _buildErrorState(context, layout),
    );
  }

  Widget _buildQuickStartContent(
    BuildContext context,
    AdaptiveLayoutConstants layout,
    Map<String, dynamic> config,
    AsyncValue<List<Map<String, dynamic>>> recentGames,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Quick Start Section
        _buildQuickStartSection(context, layout, config),
        
        SizedBox(height: layout.large),
        
        // Recent Games Section
        recentGames.when(
          data: (games) => games.isNotEmpty 
              ? _buildRecentGamesSection(context, layout, games)
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        
        SizedBox(height: layout.large),
        
        // Quick Settings
        _buildQuickSettingsSection(context, layout, config),
      ],
    );
  }

  Widget _buildQuickStartSection(
    BuildContext context,
    AdaptiveLayoutConstants layout,
    Map<String, dynamic> config,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(layout.large),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: Theme.of(context).primaryColor,
                  size: 28,
                ),
                SizedBox(width: layout.medium),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Start',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Jump right into your favorite game mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: layout.large),
            
            // Quick Start Buttons
            Row(
              children: [
                Expanded(
                  child: _buildQuickStartButton(
                    context,
                    layout,
                    'Continue Last Game',
                    '${config['gameMode']} • ${config['difficulty']}',
                    Icons.play_circle_fill,
                    Colors.green,
                    () => _startQuickGame(config),
                  ),
                ),
                SizedBox(width: layout.medium),
                Expanded(
                  child: _buildQuickStartButton(
                    context,
                    layout,
                    'Random Challenge',
                    'Surprise me!',
                    Icons.casino,
                    Colors.purple,
                    () => _startRandomGame(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStartButton(
    BuildContext context,
    AdaptiveLayoutConstants layout,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton(
      onPressed: _isStarting ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.1),
        foregroundColor: color,
        padding: EdgeInsets.all(layout.large),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(layout.medium),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 32),
          SizedBox(height: layout.small),
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: layout.small),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentGamesSection(
    BuildContext context,
    AdaptiveLayoutConstants layout,
    List<Map<String, dynamic>> recentGames,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Games',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: layout.medium),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: recentGames.length,
            itemBuilder: (context, index) {
              final game = recentGames[index];
              return _buildRecentGameCard(context, layout, game, index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentGameCard(
    BuildContext context,
    AdaptiveLayoutConstants layout,
    Map<String, dynamic> game,
    int index,
  ) {
    final accuracy = (game['score'] as int) / (game['totalQuestions'] as int) * 100;
    
    return Container(
      width: 160,
      margin: EdgeInsets.only(right: layout.medium),
      child: Card(
        child: InkWell(
          onTap: () => _repeatGame(game),
          borderRadius: BorderRadius.circular(layout.medium),
          child: Padding(
            padding: EdgeInsets.all(layout.medium),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getGameModeIcon(game['gameMode']),
                      size: 20,
                      color: Theme.of(context).primaryColor,
                    ),
                    SizedBox(width: layout.small),
                    Expanded(
                      child: Text(
                        game['gameMode'].toString().toUpperCase(),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: layout.small),
                Text(
                  '${game['category']} • ${game['difficulty']}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.stars,
                      size: 16,
                      color: accuracy >= 80 ? Colors.gold : Colors.grey,
                    ),
                    SizedBox(width: layout.small),
                    Text(
                      '${accuracy.toInt()}%',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accuracy >= 80 ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuickSettingsSection(
    BuildContext context,
    AdaptiveLayoutConstants layout,
    Map<String, dynamic> config,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(layout.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Settings',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: layout.medium),
            
            // Settings Grid
            Wrap(
              spacing: layout.medium,
              runSpacing: layout.medium,
              children: [
                _buildQuickSetting(
                  context,
                  layout,
                  'Difficulty',
                  config['difficulty'].toString(),
                  Icons.trending_up,
                  () => _showDifficultyPicker(context, config),
                ),
                _buildQuickSetting(
                  context,
                  layout,
                  'Category',
                  config['category'].toString(),
                  Icons.category,
                  () => _showCategoryPicker(context, config),
                ),
                _buildQuickSetting(
                  context,
                  layout,
                  'Time',
                  '${config['timeLimit']}s',
                  Icons.timer,
                  () => _showTimePicker(context, config),
                ),
                _buildQuickSetting(
                  context,
                  layout,
                  'Questions',
                  '${config['questionCount']}',
                  Icons.quiz,
                  () => _showQuestionCountPicker(context, config),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickSetting(
    BuildContext context,
    AdaptiveLayoutConstants layout,
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(layout.small),
      child: Container(
        padding: EdgeInsets.all(layout.medium),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(layout.small),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20),
            SizedBox(height: layout.small),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall,
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, AdaptiveLayoutConstants layout) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(layout.large),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: layout.medium),
            Text(
              'Unable to load preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: layout.medium),
            ElevatedButton(
              onPressed: () => _startDefaultGame(),
              child: const Text('Start Default Game'),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  Future<void> _startQuickGame(Map<String, dynamic> config) async {
    if (_isStarting) return;
    
    setState(() => _isStarting = true);
    
    try {
      final gameMode = config['gameMode'] as String;
      await _launchGame(
        gameMode: gameMode,
        difficulty: config['difficulty'] as GameDifficulty,
        category: config['category'] as GameCategory,
        timeLimit: config['timeLimit'] as int,
        questionCount: config['questionCount'] as int,
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _startRandomGame() async {
    if (_isStarting) return;
    
    setState(() => _isStarting = true);
    
    try {
      // Generate random game configuration
      final gameModes = ['classic', 'aiNative', 'chatgpt'];
      final difficulties = GameDifficulty.values;
      final categories = GameCategory.values;
      
      await _launchGame(
        gameMode: gameModes[DateTime.now().millisecond % gameModes.length],
        difficulty: difficulties[DateTime.now().millisecond % difficulties.length],
        category: categories[DateTime.now().millisecond % categories.length],
        timeLimit: 30,
        questionCount: 10,
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _repeatGame(Map<String, dynamic> game) async {
    if (_isStarting) return;
    
    setState(() => _isStarting = true);
    
    try {
      await _launchGame(
        gameMode: game['gameMode'],
        difficulty: GameDifficulty.values.byName(game['difficulty']),
        category: GameCategory.values.byName(game['category']),
        timeLimit: 30, // Default time
        questionCount: game['totalQuestions'] ?? 10,
      );
    } finally {
      if (mounted) {
        setState(() => _isStarting = false);
      }
    }
  }

  Future<void> _startDefaultGame() async {
    await _launchGame(
      gameMode: 'classic',
      difficulty: GameDifficulty.normal,
      category: GameCategory.addition,
      timeLimit: 30,
      questionCount: 10,
    );
  }

  Future<void> _launchGame({
    required String gameMode,
    required GameDifficulty difficulty,
    required GameCategory category,
    required int timeLimit,
    required int questionCount,
  }) async {
    try {
      // Update user preferences for next time
      final prefsService = ref.read(userPreferencesServiceProvider);
      await prefsService.updatePreferencesFromGame(
        difficulty: difficulty,
        category: category,
        timeLimit: timeLimit,
        questionCount: questionCount,
        gameMode: gameMode,
      );

      // Launch appropriate game screen directly (inline)
      Widget gameWidget;
      switch (gameMode) {
        case 'aiNative':
          gameWidget = const AINativeGameScreen();
          break;
        case 'chatgpt':
          gameWidget = const ChatGPTEnhancedGameScreen();
          break;
        default:
          gameWidget = const ClassicQuizScreen();
      }

      // Show game in modal or navigate
      if (mounted) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => gameWidget,
            fullscreenDialog: true,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error starting game: $e',
          isError: true,
        );
      }
    }
  }

  // Settings pickers
  Future<void> _showDifficultyPicker(BuildContext context, Map<String, dynamic> config) async {
    final selected = await showDialog<GameDifficulty>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Difficulty'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: GameDifficulty.values.map((difficulty) {
            return ListTile(
              title: Text(difficulty.name.toUpperCase()),
              leading: Icon(_getDifficultyIcon(difficulty)),
              onTap: () => Navigator.of(context).pop(difficulty),
            );
          }).toList(),
        ),
      ),
    );
    
    if (selected != null) {
      await _updateQuickSetting('difficulty', selected);
    }
  }

  Future<void> _showCategoryPicker(BuildContext context, Map<String, dynamic> config) async {
    final selected = await showDialog<GameCategory>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Category'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: GameCategory.values.map((category) {
              return ListTile(
                title: Text(category.name.toUpperCase()),
                leading: Icon(_getCategoryIcon(category)),
                onTap: () => Navigator.of(context).pop(category),
              );
            }).toList(),
          ),
        ),
      ),
    );
    
    if (selected != null) {
      await _updateQuickSetting('category', selected);
    }
  }

  Future<void> _showTimePicker(BuildContext context, Map<String, dynamic> config) async {
    final times = [15, 30, 45, 60, 90, 120];
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Time Limit'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: times.map((time) {
            return ListTile(
              title: Text('${time} seconds'),
              leading: const Icon(Icons.timer),
              onTap: () => Navigator.of(context).pop(time),
            );
          }).toList(),
        ),
      ),
    );
    
    if (selected != null) {
      await _updateQuickSetting('timeLimit', selected);
    }
  }

  Future<void> _showQuestionCountPicker(BuildContext context, Map<String, dynamic> config) async {
    final counts = [5, 10, 15, 20, 25, 30];
    final selected = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Question Count'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: counts.map((count) {
            return ListTile(
              title: Text('$count questions'),
              leading: const Icon(Icons.quiz),
              onTap: () => Navigator.of(context).pop(count),
            );
          }).toList(),
        ),
      ),
    );
    
    if (selected != null) {
      await _updateQuickSetting('questionCount', selected);
    }
  }

  Future<void> _updateQuickSetting(String key, dynamic value) async {
    try {
      final prefsService = ref.read(userPreferencesServiceProvider);
      final currentPrefs = await prefsService.getGamePreferences();
      
      UserGamePreferences updatedPrefs;
      switch (key) {
        case 'difficulty':
          updatedPrefs = currentPrefs.copyWith(preferredDifficulty: value);
          break;
        case 'category':
          updatedPrefs = currentPrefs.copyWith(preferredCategory: value);
          break;
        case 'timeLimit':
          updatedPrefs = currentPrefs.copyWith(preferredTimeLimit: value);
          break;
        case 'questionCount':
          updatedPrefs = currentPrefs.copyWith(preferredQuestionCount: value);
          break;
        default:
          return;
      }
      
      await prefsService.saveGamePreferences(updatedPrefs);
      
      // Refresh providers
      ref.invalidate(quickStartConfigProvider);
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error updating setting: $e',
          isError: true,
        );
      }
    }
  }

  IconData _getGameModeIcon(String gameMode) {
    switch (gameMode) {
      case 'aiNative':
        return Icons.psychology;
      case 'chatgpt':
        return Icons.auto_awesome;
      default:
        return Icons.quiz;
    }
  }

  IconData _getDifficultyIcon(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Icons.sentiment_satisfied;
      case GameDifficulty.normal:
        return Icons.trending_up;
      case GameDifficulty.genius:
        return Icons.emoji_events;
      case GameDifficulty.quantum:
        return Icons.rocket_launch;
    }
  }

  IconData _getCategoryIcon(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return Icons.add;
      case GameCategory.subtraction:
        return Icons.remove;
      case GameCategory.multiplication:
        return Icons.close;
      case GameCategory.division:
        return Icons.percent;
      case GameCategory.fractions:
        return Icons.pie_chart;
      case GameCategory.geometry:
        return Icons.square;
      default:
        return Icons.calculate;
    }
  }
}
