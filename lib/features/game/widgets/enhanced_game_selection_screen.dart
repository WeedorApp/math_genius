import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Removed unused import

// Core imports
import '../../../core/barrel.dart';

// Game imports
import '../services/unified_game_factory.dart';

/// Enhanced Game Selection Screen
/// Unified interface for selecting and launching any game type
class EnhancedGameSelectionScreen extends ConsumerStatefulWidget {
  const EnhancedGameSelectionScreen({super.key});

  @override
  ConsumerState<EnhancedGameSelectionScreen> createState() => _EnhancedGameSelectionScreenState();
}

class _EnhancedGameSelectionScreenState extends ConsumerState<EnhancedGameSelectionScreen> 
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  String? _selectedGameType;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadRecommendedGameType();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _fadeController.forward();
  }

  void _loadRecommendedGameType() {
    final recommendedType = ref.read(recommendedGameTypeProvider);
    setState(() {
      _selectedGameType = recommendedType;
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final availableGameTypes = ref.watch(availableGameTypesProvider);
    final themeData = ref.watch(themeDataProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Game'),
        backgroundColor: themeData.toThemeData().primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              themeData.toThemeData().primaryColor.withValues(alpha: 0.1),
              themeData.toThemeData().colorScheme.surface,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Header
                  Text(
                    'Select Your Math Adventure!',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: themeData.toThemeData().primaryColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Each game type offers a unique learning experience',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  
                  // Game type cards
                  Expanded(
                    child: ListView.builder(
                      itemCount: availableGameTypes.length,
                      itemBuilder: (context, index) {
                        final gameType = availableGameTypes[index];
                        final gameInfo = ref.read(gameTypeInfoProvider(gameType));
                        final isRecommended = gameType == _selectedGameType;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: _buildGameTypeCard(gameInfo, gameType, isRecommended),
                        );
                      },
                    ),
                  ),
                  
                  // Quick start button
                  if (_selectedGameType != null) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _launchGame(_selectedGameType!),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Quick Start Recommended'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGameTypeCard(GameTypeInfo gameInfo, String gameType, bool isRecommended) {
    return Card(
      elevation: isRecommended ? 8 : 4,
      child: InkWell(
        onTap: () => _selectGameType(gameType),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isRecommended 
              ? Border.all(color: Colors.green, width: 3)
              : null,
            gradient: isRecommended 
              ? LinearGradient(
                  colors: [
                    Colors.green.withValues(alpha: 0.1),
                    Colors.transparent,
                  ],
                )
              : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: gameInfo.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      gameInfo.icon,
                      size: 32,
                      color: gameInfo.color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              gameInfo.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (isRecommended) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'RECOMMENDED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Text(
                          gameInfo.description,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Features
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: gameInfo.features.map((feature) => 
                  Chip(
                    label: Text(
                      feature,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: gameInfo.color.withValues(alpha: 0.1),
                    side: BorderSide(color: gameInfo.color.withValues(alpha: 0.3)),
                  ),
                ).toList(),
              ),
              
              const SizedBox(height: 16),
              
              // Launch button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _launchGame(gameType),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gameInfo.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text('Play ${gameInfo.name}'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _selectGameType(String gameType) {
    setState(() {
      _selectedGameType = gameType;
    });
  }

  void _launchGame(String gameType) {
    // Navigate to the appropriate game screen
    final gameScreen = UnifiedGameFactory.createGameScreen(
      gameType: gameType,
      ref: ref,
    );
    
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => gameScreen),
    );
  }
}
