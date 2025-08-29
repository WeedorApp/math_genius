import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../core/barrel.dart';

// Game models
import '../../game/models/game_model.dart';

/// Game Preferences Settings Screen
/// Allows users to configure default game settings once
class GamePreferencesScreen extends ConsumerStatefulWidget {
  const GamePreferencesScreen({super.key});

  @override
  ConsumerState<GamePreferencesScreen> createState() => _GamePreferencesScreenState();
}

class _GamePreferencesScreenState extends ConsumerState<GamePreferencesScreen> {
  UserGamePreferences? _preferences;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final service = ref.read(userPreferencesServiceProvider);
      final prefs = await service.getGamePreferences();
      setState(() {
        _preferences = prefs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _preferences = UserGamePreferences(lastPlayed: DateTime.now());
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null || _isSaving) return;
    
    setState(() => _isSaving = true);
    
    try {
      final service = ref.read(userPreferencesServiceProvider);
      await service.saveGamePreferences(_preferences!);
      
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Game preferences saved!',
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Error saving preferences: $e',
          isError: true,
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game Preferences')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_preferences == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Game Preferences')),
        body: const Center(child: Text('Error loading preferences')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Game Preferences'),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _savePreferences,
              child: const Text('Save'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Default Difficulty
          _buildPreferenceCard(
            'Default Difficulty',
            'Set your preferred difficulty level for all games',
            Icons.trending_up,
            _buildDifficultySelector(),
          ),
          
          const SizedBox(height: 16),
          
          // Default Category
          _buildPreferenceCard(
            'Default Category',
            'Choose your favorite math topic',
            Icons.category,
            _buildCategorySelector(),
          ),
          
          const SizedBox(height: 16),
          
          // Time Settings
          _buildPreferenceCard(
            'Time Settings',
            'Configure time limits for questions',
            Icons.timer,
            _buildTimeSettings(),
          ),
          
          const SizedBox(height: 16),
          
          // Question Settings
          _buildPreferenceCard(
            'Question Settings',
            'Set how many questions per game',
            Icons.quiz,
            _buildQuestionSettings(),
          ),
          
          const SizedBox(height: 16),
          
          // Audio & Feedback
          _buildPreferenceCard(
            'Audio & Feedback',
            'Configure sound and haptic feedback',
            Icons.volume_up,
            _buildAudioSettings(),
          ),
          
          const SizedBox(height: 32),
          
          // Reset to Defaults
          ElevatedButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore),
            label: const Text('Reset to Defaults'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferenceCard(
    String title,
    String subtitle,
    IconData icon,
    Widget content,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultySelector() {
    return Wrap(
      spacing: 8,
      children: GameDifficulty.values.map((difficulty) {
        final isSelected = _preferences!.preferredDifficulty == difficulty;
        return FilterChip(
          label: Text(difficulty.name.toUpperCase()),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _preferences = _preferences!.copyWith(preferredDifficulty: difficulty);
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildCategorySelector() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: GameCategory.values.take(8).map((category) { // Show first 8 categories
        final isSelected = _preferences!.preferredCategory == category;
        return FilterChip(
          label: Text(category.name.toUpperCase()),
          selected: isSelected,
          onSelected: (selected) {
            if (selected) {
              setState(() {
                _preferences = _preferences!.copyWith(preferredCategory: category);
              });
            }
          },
        );
      }).toList(),
    );
  }

  Widget _buildTimeSettings() {
    final timeLimits = [15, 30, 45, 60, 90, 120];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time per question: ${_preferences!.preferredTimeLimit} seconds',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: timeLimits.map((time) {
            final isSelected = _preferences!.preferredTimeLimit == time;
            return FilterChip(
              label: Text('${time}s'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _preferences = _preferences!.copyWith(preferredTimeLimit: time);
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildQuestionSettings() {
    final questionCounts = [5, 10, 15, 20, 25, 30];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions per game: ${_preferences!.preferredQuestionCount}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: questionCounts.map((count) {
            final isSelected = _preferences!.preferredQuestionCount == count;
            return FilterChip(
              label: Text('$count'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _preferences = _preferences!.copyWith(preferredQuestionCount: count);
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAudioSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Sound Effects'),
          subtitle: const Text('Play sounds during games'),
          value: _preferences!.soundEnabled,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(soundEnabled: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Haptic Feedback'),
          subtitle: const Text('Vibration for correct/incorrect answers'),
          value: _preferences!.hapticFeedbackEnabled,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(hapticFeedbackEnabled: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Auto-Start Next Game'),
          subtitle: const Text('Automatically start a new game after completion'),
          value: _preferences!.autoStartNextGame,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(autoStartNextGame: value);
            });
          },
        ),
      ],
    );
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text('This will reset all game preferences to default values. Continue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _preferences = UserGamePreferences(lastPlayed: DateTime.now());
      });
      await _savePreferences();
    }
  }
}
