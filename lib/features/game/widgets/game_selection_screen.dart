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
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
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
                child: Container(),
              ),
            ),
          ],
        ),
      );
    }

    final navigationItems = [
      const NavigationItem(title: 'Home', icon: Icons.home, route: '/home'),
      const NavigationItem(
        title: 'Games',
        icon: Icons.games,
        route: '/game-selection',
      ),
      const NavigationItem(
        title: 'AI Tutor',
        icon: Icons.smart_toy,
        route: '/ai-tutor',
      ),
      const NavigationItem(
        title: 'Family',
        icon: Icons.family_restroom,
        route: '/family',
      ),
      const NavigationItem(
        title: 'Live',
        icon: Icons.video_call,
        route: '/live-session',
      ),
      const NavigationItem(
        title: 'Rewards',
        icon: Icons.star,
        route: '/rewards',
      ),
    ];

    return ResponsiveLayout(
      currentRoute: '/game-selection',
      navigationItems: navigationItems,
      child: Scaffold(
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
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go('/home');
              }
            },
            tooltip: 'Back to previous screen',
          ),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Ready to Play Math? 🎯',
                  style: themeData.typography.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your preferred game mode to start learning!',
                  style: themeData.typography.bodyMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                // Game Options
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.9,
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
                  const SizedBox(height: 20),
                  _buildChatGPTStatusCard(
                    context,
                    themeData,
                    colorScheme,
                    chatGPTStatus,
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 24),
                  Text(_errorMessage!, style: TextStyle(color: Colors.red)),
                ],
              ],
            ),
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
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEnabled
                ? colorScheme.outline.withValues(alpha: 0.2)
                : colorScheme.outline.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.1),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? color.withValues(alpha: 0.1)
                      : color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: isEnabled ? color : color.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: themeData.typography.titleMedium.copyWith(
                  color: isEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
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
      padding: const EdgeInsets.all(16),
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
              const SizedBox(width: 8),
              Text(
                'ChatGPT Status',
                style: themeData.typography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
              const SizedBox(width: 8),
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
