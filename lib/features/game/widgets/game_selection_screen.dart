import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../../../core/barrel.dart';

// Game screens
import 'classic_quiz_screen.dart';
import 'ai_native_game_screen.dart';
import 'chatgpt_enhanced_game_screen.dart';
// Quick start functionality integrated inline

// Settings
import '../../settings/widgets/chatgpt_settings_screen.dart';

// ChatGPT Configuration
import '../../../core/ai/chatgpt_config.dart';

/// Game Selection Screen
/// Allows users to choose between different game modes
enum GameSelectionMode { classic, aiNative, chatgpt }

class GameSelectionScreen extends ConsumerStatefulWidget {
  const GameSelectionScreen({super.key});

  @override
  ConsumerState<GameSelectionScreen> createState() =>
      _GameSelectionScreenState();
}

class _GameSelectionScreenState extends ConsumerState<GameSelectionScreen> {
  GameSelectionMode? _selectedGame;
  UserGamePreferences? _currentPreferences;

  @override
  void initState() {
    super.initState();
    _loadCurrentPreferences();
  }

  Future<void> _loadCurrentPreferences() async {
    try {
      final prefsService = ref.read(userPreferencesServiceProvider);
      final preferences = await prefsService.getGamePreferences();
      setState(() {
        _currentPreferences = preferences;
      });
    } catch (e) {
      // Continue without preferences
    }
  }

  String _getPreferencesSummary() {
    if (_currentPreferences == null) return '';

    final difficulty = _currentPreferences!.preferredDifficulty.name
        .toUpperCase();
    final category = _currentPreferences!.preferredCategory.name;
    final questions = _currentPreferences!.preferredQuestionCount;
    final time = _currentPreferences!.preferredTimeLimit;

    return '$difficulty • $category • $questions questions • ${time}s per question';
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final chatGPTStatus = ref.watch(chatGPTStatusProvider);

    // If a game is selected, render it inline without routing
    if (_selectedGame != null) {
      late final Widget selectedChild;
      switch (_selectedGame!) {
        case GameSelectionMode.classic:
          selectedChild = const ClassicQuizScreen();
          break;
        case GameSelectionMode.aiNative:
          selectedChild = const AINativeGameScreen();
          break;
        case GameSelectionMode.chatgpt:
          selectedChild = const ChatGPTEnhancedGameScreen();
          break;
      }

      return Scaffold(
        backgroundColor: colorScheme.surface,
        body: Stack(
          children: [
            Positioned.fill(child: selectedChild),
            SafeArea(
              child: Padding(
                padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: AdaptiveUISystem.adaptiveButton(
                    context: context,
                    onPressed: () => setState(() => _selectedGame = null),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.arrow_back),
                        SizedBox(width: context.adaptiveLayout.cardSpacing / 2),
                        const Text('Back'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Choose Game Mode',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => context.push('/settings/games'),
            icon: const Icon(Icons.tune),
            tooltip: 'Game Settings',
          ),
          IconButton(
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings),
            tooltip: 'All Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Quick Start
              Text(
                'Ready to Play Math? 🎯',
                style: themeData.typography.headlineMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.adaptiveLayout.cardSpacing / 2),
              Text(
                'Jump right in or choose your adventure',
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: context.adaptiveLayout.cardSpacing),

              // Quick Start Button
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.rocket_launch,
                            color: Colors.green,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Quick Start',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  _currentPreferences != null
                                      ? 'Using your saved preferences: ${_getPreferencesSummary()}'
                                      : 'Start playing instantly with smart defaults',
                                  style: TextStyle(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(
                                () => _selectedGame = GameSelectionMode.classic,
                              ),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Start Classic'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () => setState(
                                () =>
                                    _selectedGame = GameSelectionMode.aiNative,
                              ),
                              icon: const Icon(Icons.psychology),
                              label: const Text('AI Game'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: context.adaptiveLayout.sectionSpacing),

              const Divider(),

              SizedBox(height: context.adaptiveLayout.cardSpacing),

              Text(
                'More Game Options',
                style: themeData.typography.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: context.adaptiveLayout.cardSpacing),

              // Game Options
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: context.adaptiveLayout.cardSpacing,
                mainAxisSpacing: context.adaptiveLayout.cardSpacing,
                childAspectRatio: 0.9, // Increased from 0.85
                children: [
                  _buildGameOption(
                    context,
                    'Classic Quiz',
                    'Traditional math quiz with basic questions',
                    Icons.quiz,
                    Colors.blue,
                    () => setState(
                      () => _selectedGame = GameSelectionMode.classic,
                    ),
                    themeData,
                    colorScheme,
                  ),
                  _buildGameOption(
                    context,
                    'AI-Native Quiz',
                    'Advanced AI-powered questions with local generation',
                    Icons.psychology,
                    Colors.green,
                    () => setState(
                      () => _selectedGame = GameSelectionMode.aiNative,
                    ),
                    themeData,
                    colorScheme,
                  ),
                  _buildGameOption(
                    context,
                    'ChatGPT Enhanced',
                    'Real AI-powered questions with ChatGPT',
                    Icons.auto_awesome,
                    Colors.purple,
                    () {
                      if (chatGPTStatus['hasApiKey'] == true &&
                          chatGPTStatus['isEnabled'] == true) {
                        setState(
                          () => _selectedGame = GameSelectionMode.chatgpt,
                        );
                      } else {
                        _showChatGPTSetupDialog(
                          context,
                          ref,
                          themeData,
                          colorScheme,
                        );
                      }
                    },
                    themeData,
                    colorScheme,
                    isEnabled:
                        chatGPTStatus['hasApiKey'] == true &&
                        chatGPTStatus['isEnabled'] == true,
                  ),
                  _buildGameOption(
                    context,
                    'Settings',
                    'Configure ChatGPT and other settings',
                    Icons.settings,
                    Colors.orange,
                    () => context.push('/settings/chatgpt'),
                    themeData,
                    colorScheme,
                  ),
                ],
              ),

              // ChatGPT Status
              if (chatGPTStatus['hasApiKey'] == true) ...[
                const SizedBox(height: 20), // Reduced from 24
                _buildChatGPTStatusCard(
                  context,
                  themeData,
                  colorScheme,
                  chatGPTStatus,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme, {
    bool isEnabled = true,
  }) {
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: Container(
        decoration: BoxDecoration(
          color: isEnabled
              ? colorScheme.surface
              : colorScheme.surface.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12), // Reduced from 16
          border: Border.all(
            color: isEnabled
                ? colorScheme.outline.withValues(alpha: 0.2)
                : colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 6, // Reduced from 8
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(
                  context.adaptiveLayout.contentPadding / 2,
                ),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? color.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8), // Reduced from 12
                ),
                child: Icon(
                  icon,
                  size: 24, // Reduced from 32
                  color: isEnabled ? color : color.withValues(alpha: 0.5),
                ),
              ),
              SizedBox(height: context.adaptiveLayout.cardSpacing / 2),
              Text(
                title,
                style: themeData.typography.titleMedium.copyWith(
                  // Changed from titleLarge
                  color: isEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: context.adaptiveLayout.cardSpacing / 4),
              Text(
                subtitle,
                style: themeData.typography.bodySmall.copyWith(
                  color: isEnabled
                      ? colorScheme.onSurface.withValues(alpha: 0.7)
                      : colorScheme.onSurface.withValues(alpha: 0.3),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (!isEnabled) ...[
                SizedBox(height: context.adaptiveLayout.cardSpacing / 3),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.adaptiveLayout.cardSpacing / 2.5,
                    vertical: context.adaptiveLayout.cardSpacing / 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6), // Reduced from 8
                  ),
                  child: Text(
                    'Setup Required',
                    style: themeData.typography.labelSmall.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatGPTStatusCard(
    BuildContext context,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Map<String, dynamic> status,
  ) {
    final isEnabled = status['isEnabled'] as bool;
    final model = status['model'] as String;

    return Container(
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.psychology, color: colorScheme.primary, size: 20),
              SizedBox(width: context.adaptiveLayout.cardSpacing / 2),
              Text(
                'ChatGPT Status',
                style: themeData.typography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: context.adaptiveLayout.cardSpacing / 2),
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isEnabled ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: context.adaptiveLayout.cardSpacing / 2),
              Text(
                isEnabled ? 'Enabled' : 'Disabled',
                style: themeData.typography.bodySmall.copyWith(
                  color: isEnabled ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              Text(
                'Model: $model',
                style: themeData.typography.bodySmall.copyWith(
                  color: colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showChatGPTSetupDialog(
    BuildContext context,
    WidgetRef ref,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'ChatGPT Setup Required',
          style: themeData.typography.titleLarge.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'To use ChatGPT Enhanced mode, you need to configure your OpenAI API key in the settings.',
          style: themeData.typography.bodyMedium.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: themeData.typography.labelLarge.copyWith(
                color: colorScheme.primary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatGPTSettingsScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
            ),
            child: Text(
              'Open Settings',
              style: themeData.typography.labelLarge.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
