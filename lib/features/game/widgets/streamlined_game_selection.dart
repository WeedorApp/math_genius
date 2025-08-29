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
import 'game_selection_screen.dart'; // For GameSelectionMode enum

/// Streamlined Game Selection with Smart Defaults and Quick Start
class StreamlinedGameSelection extends ConsumerStatefulWidget {
  const StreamlinedGameSelection({super.key});

  @override
  ConsumerState<StreamlinedGameSelection> createState() => _StreamlinedGameSelectionState();
}

class _StreamlinedGameSelectionState extends ConsumerState<StreamlinedGameSelection> {
  bool _isStarting = false;
  GameSelectionMode? _selectedGame;

  @override
  Widget build(BuildContext context) {
    final quickStartConfig = ref.watch(quickStartConfigProvider);
    final recentGames = ref.watch(recentGamesProvider);

    // If a game is selected, render it inline
    if (_selectedGame != null) {
      return _buildSelectedGame();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Math Games'),
        actions: [
          IconButton(
            onPressed: () => context.push('/settings/chatgpt'),
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Header
              _buildWelcomeHeader(),
              
              const SizedBox(height: 24),
              
              // Quick Start Section
              quickStartConfig.when(
                data: (config) => _buildQuickStartSection(config),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 24),
              
              // Recent Games
              recentGames.when(
                data: (games) => games.isNotEmpty 
                    ? _buildRecentGamesSection(games) 
                    : const SizedBox.shrink(),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              
              const SizedBox(height: 24),
              
              const Divider(),
              
              const SizedBox(height: 16),
              
              // Game Mode Selection
              _buildGameModeSelection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      children: [
        Icon(
          Icons.school,
          size: 48,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          'Ready to Play Math?',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          'Jump right in or customize your experience',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickStartSection(Map<String, dynamic> config) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.rocket_launch, color: Colors.green),
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
                        'Start instantly with your saved preferences',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Quick Start Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isStarting ? null : () => _quickStart(config),
                    icon: const Icon(Icons.play_arrow),
                    label: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Continue'),
                        Text(
                          '${config['gameMode']} • ${config['difficulty']}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isStarting ? null : _randomGame,
                    icon: const Icon(Icons.shuffle),
                    label: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Surprise Me'),
                        Text('Random game', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentGamesSection(List<Map<String, dynamic>> games) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Games',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildRecentGameCard(game);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentGameCard(Map<String, dynamic> game) {
    final accuracy = (game['score'] as int) / (game['totalQuestions'] as int) * 100;
    
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: InkWell(
          onTap: () => _repeatGame(game),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  game['gameMode'].toString().toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${game['category']} • ${game['difficulty']}',
                  style: const TextStyle(fontSize: 10),
                ),
                const Spacer(),
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 14,
                      color: accuracy >= 80 ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${accuracy.toInt()}%',
                      style: TextStyle(
                        fontSize: 12,
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

  Widget _buildGameModeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Choose Game Mode',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Game Mode Cards
        _buildGameModeCard(
          'Classic Quiz',
          'Traditional math questions with instant feedback',
          Icons.quiz,
          Colors.blue,
          GameSelectionMode.classic,
        ),
        const SizedBox(height: 12),
        _buildGameModeCard(
          'AI-Powered',
          'Adaptive questions that learn from your performance',
          Icons.psychology,
          Colors.green,
          GameSelectionMode.aiNative,
        ),
        const SizedBox(height: 12),
        _buildGameModeCard(
          'ChatGPT Enhanced',
          'Advanced AI tutor with explanations and hints',
          Icons.auto_awesome,
          Colors.purple,
          GameSelectionMode.chatgpt,
        ),
      ],
    );
  }

  Widget _buildGameModeCard(
    String title,
    String description,
    IconData icon,
    Color color,
    GameSelectionMode mode,
  ) {
    return Card(
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(description),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () => setState(() => _selectedGame = mode),
      ),
    );
  }

  Widget _buildSelectedGame() {
    late final Widget gameWidget;
    switch (_selectedGame!) {
      case GameSelectionMode.classic:
        gameWidget = const ClassicQuizScreen();
        break;
      case GameSelectionMode.aiNative:
        gameWidget = const AINativeGameScreen();
        break;
      case GameSelectionMode.chatgpt:
        gameWidget = const ChatGPTEnhancedGameScreen();
        break;
    }

    return Scaffold(
      body: gameWidget,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _selectedGame = null),
        icon: const Icon(Icons.arrow_back),
        label: const Text('Back to Games'),
      ),
    );
  }

  // Action methods
  Future<void> _quickStart(Map<String, dynamic> config) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final gameMode = config['gameMode'] as String;
      
      // Convert string to enum
      GameSelectionMode mode;
      switch (gameMode) {
        case 'aiNative':
          mode = GameSelectionMode.aiNative;
          break;
        case 'chatgpt':
          mode = GameSelectionMode.chatgpt;
          break;
        default:
          mode = GameSelectionMode.classic;
      }
      
      setState(() => _selectedGame = mode);
    } finally {
      setState(() => _isStarting = false);
    }
  }

  Future<void> _randomGame() async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final modes = GameSelectionMode.values;
      final randomMode = modes[DateTime.now().millisecond % modes.length];
      setState(() => _selectedGame = randomMode);
    } finally {
      setState(() => _isStarting = false);
    }
  }

  Future<void> _repeatGame(Map<String, dynamic> game) async {
    if (_isStarting) return;
    setState(() => _isStarting = true);

    try {
      final gameMode = game['gameMode'] as String;
      GameSelectionMode mode;
      switch (gameMode) {
        case 'aiNative':
          mode = GameSelectionMode.aiNative;
          break;
        case 'chatgpt':
          mode = GameSelectionMode.chatgpt;
          break;
        default:
          mode = GameSelectionMode.classic;
      }
      
      setState(() => _selectedGame = mode);
    } finally {
      setState(() => _isStarting = false);
    }
  }
}
