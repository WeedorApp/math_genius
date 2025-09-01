import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../../../core/barrel.dart';

// ChatGPT Configuration
import '../../../core/ai/chatgpt_config.dart';

/// Simple Game Mode Selector
/// Direct access to game modes without stats page
class GameModeSelector extends ConsumerWidget {
  const GameModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final chatGPTApiKey = ref.watch(chatGPTApiKeyProvider);
    final chatGPTEnabled = ref.watch(chatGPTEnabledProvider);
    final hasApiKey = chatGPTApiKey.isNotEmpty;
    final isChatGPTReady = hasApiKey && chatGPTEnabled;

    final navigationItems = [
      const NavigationItem(title: 'Home', icon: Icons.home, route: '/home'),
      const NavigationItem(
        title: 'Games',
        icon: Icons.games,
        route: '/student/games',
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
      currentRoute: '/game-modes',
      navigationItems: navigationItems,
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Choose Your Game Mode',
            style: themeData.typography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
            onPressed: () => context.go('/home'),
          ),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  '🎯 Ready to Play Math?',
                  style: themeData.typography.headlineMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16 / 2),
                Text(
                  'Choose your favorite game mode and start learning!',
                  style: themeData.typography.bodyMedium.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 24),

                // Game Mode Cards
                Expanded(
                  child: GridView.count(
                    crossAxisCount: MediaQuery.of(context).size.width > 800
                        ? 3
                        : 1,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: MediaQuery.of(context).size.width > 800
                        ? 1.2
                        : 1.8,
                    children: [
                      _buildGameModeCard(
                        context,
                        title: 'Classic Quiz',
                        description:
                            'Traditional math quiz with multiple choice questions',
                        icon: Icons.quiz,
                        color: Colors.blue,
                        onTap: () => context.go('/game-selection/classic'),
                        themeData: themeData,
                        colorScheme: colorScheme,
                      ),
                      _buildGameModeCard(
                        context,
                        title: 'AI-Native Quiz',
                        description:
                            'Advanced AI-powered questions with local generation',
                        icon: Icons.psychology,
                        color: Colors.green,
                        onTap: () => context.go('/game-selection/ai-native'),
                        themeData: themeData,
                        colorScheme: colorScheme,
                      ),
                      _buildGameModeCard(
                        context,
                        title: 'ChatGPT Enhanced',
                        description:
                            'Real AI-powered questions with ChatGPT integration',
                        icon: Icons.auto_awesome,
                        color: Colors.purple,
                        onTap: () {
                          if (isChatGPTReady) {
                            context.go('/game-selection/chatgpt');
                          } else {
                            _showChatGPTSetupDialog(
                              context,
                              ref,
                              themeData,
                              colorScheme,
                            );
                          }
                        },
                        themeData: themeData,
                        colorScheme: colorScheme,
                        isEnabled: isChatGPTReady,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameModeCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    required MathGeniusThemeData themeData,
    required ColorScheme colorScheme,
    bool isEnabled = true,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isEnabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: isEnabled
                ? LinearGradient(
                    colors: [
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? color.withValues(alpha: 0.2)
                      : colorScheme.onSurface.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isEnabled
                      ? color
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),

              SizedBox(height: 16),

              // Title
              Text(
                title,
                style: themeData.typography.titleLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isEnabled
                      ? colorScheme.onSurface
                      : colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 16 / 2),

              // Description
              Text(
                description,
                style: themeData.typography.bodyMedium.copyWith(
                  color: isEnabled
                      ? colorScheme.onSurface.withValues(alpha: 0.7)
                      : colorScheme.onSurface.withValues(alpha: 0.4),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (!isEnabled) ...[
                SizedBox(height: 16 / 2),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Setup Required',
                    style: themeData.typography.bodySmall.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.w500,
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

  void _showChatGPTSetupDialog(
    BuildContext context,
    WidgetRef ref,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple),
            const SizedBox(width: 8),
            const Text('ChatGPT Setup Required'),
          ],
        ),
        content: const Text(
          'To use ChatGPT Enhanced mode, you need to configure your API key in settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.push('/settings/chatgpt');
            },
            child: const Text('Setup ChatGPT'),
          ),
        ],
      ),
    );
  }
}
