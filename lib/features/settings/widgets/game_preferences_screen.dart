import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';

// Core imports
import '../../../core/barrel.dart';

// Game models
import '../../game/models/game_model.dart';

// User management
import '../../user_management/services/user_management_service.dart';
import '../../user_management/models/user_model.dart' as user_models;

// Student analytics
import '../../student/services/student_analytics_service.dart';

/// Advanced Game Preferences Settings Screen
/// Grade-aware, user-aware, and context-aware game mode configuration
class GamePreferencesScreen extends ConsumerStatefulWidget {
  const GamePreferencesScreen({super.key});

  @override
  ConsumerState<GamePreferencesScreen> createState() =>
      _GamePreferencesScreenState();
}

class _GamePreferencesScreenState extends ConsumerState<GamePreferencesScreen>
    with TickerProviderStateMixin {
  UserGamePreferences? _preferences;
  user_models.User? _currentUser;
  StudentAnalytics? _analytics;
  bool _isLoading = true;
  bool _isSaving = false;

  // Animation controllers
  AnimationController? _fadeController;
  Animation<double>? _fadeAnimation;

  // Context awareness
  GradeLevel _userGrade = GradeLevel.grade5;
  Map<GameCategory, double> _topicMastery = {};
  List<GameCategory> _strugglingTopics = [];
  List<GameCategory> _masteredTopics = [];

  // Performance optimization
  bool _analyticsLoaded = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadUserContext();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController!, curve: Curves.easeOut));

    _fadeController!.forward();
  }

  Future<void> _loadUserContext() async {
    try {
      setState(() => _isLoading = true);

      // AGGRESSIVE OPTIMIZATION: Load preferences directly for instant UI
      try {
        final preferencesService = ref.read(userPreferencesServiceProvider);
        final preferences = await preferencesService.getGamePreferences();

        // Show UI immediately with loaded preferences
        setState(() {
          _preferences = preferences;
          _isLoading = false;
        });

        if (kDebugMode) {
          debugPrint('✅ Preferences loaded instantly, UI displayed');
        }

        // Load user and analytics in background (non-blocking)
        _loadUserAndAnalyticsAsync();
      } catch (e) {
        // Fallback: Use default preferences and show UI
        setState(() {
          _preferences = UserGamePreferences(lastPlayed: DateTime.now());
          _isLoading = false;
        });

        debugPrint('Using default preferences due to error: $e');

        // Still try to load user data in background
        _loadUserAndAnalyticsAsync();
      }
    } catch (e) {
      setState(() {
        _preferences = UserGamePreferences(lastPlayed: DateTime.now());
        _isLoading = false;
      });
      debugPrint('Critical error in _loadUserContext: $e');
    }
  }

  /// Load user and analytics data asynchronously (non-blocking)
  Future<void> _loadUserAndAnalyticsAsync() async {
    try {
      // Load user and analytics in parallel for better performance
      final userService = ref.read(userManagementServiceProvider);
      final userFuture = userService.getCurrentUser();

      final user = await userFuture;

      // Load analytics only if user exists (parallel with UI already shown)
      StudentAnalytics? analytics;
      if (user?.id != null) {
        try {
          final analyticsService = ref.read(studentAnalyticsServiceProvider);
          analytics = await analyticsService.getStudentAnalytics(user!.id);
        } catch (e) {
          debugPrint('Could not load analytics: $e');
        }
      }

      // Update UI with user context (non-blocking)
      if (mounted) {
        setState(() {
          _currentUser = user;
          _analytics = analytics;
          _userGrade = user?.gradeLevel ?? GradeLevel.grade5;
          _analyticsLoaded = true;
          _extractTopicMastery();
        });
      }
    } catch (e) {
      debugPrint('Error loading user context: $e');
      // UI already loaded with preferences, so this is non-critical
    }
  }

  void _extractTopicMastery() {
    if (_analytics != null) {
      _topicMastery = _analytics!.topicMastery;
      _masteredTopics = _topicMastery.entries
          .where((entry) => entry.value >= 80.0)
          .map((entry) => entry.key)
          .toList();
      _strugglingTopics = _topicMastery.entries
          .where((entry) => entry.value < 60.0)
          .map((entry) => entry.key)
          .toList();
    }
  }

  Future<void> _savePreferences() async {
    if (_preferences == null || _isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Use the reactive preferences notifier for real-time sync
      final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
      await notifier.updatePreferences(_preferences!);

      if (mounted) {
        AdaptiveUISystem.showAdaptiveSnackBar(
          context: context,
          message: 'Preferences saved and synced to all games!',
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
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game Preferences'),
          backgroundColor: colorScheme.surface,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_preferences == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Game Preferences'),
          backgroundColor: colorScheme.surface,
        ),
        body: const Center(child: Text('Error loading preferences')),
      );
    }

    final navigationItems = [
      const NavigationItem(title: 'Home', icon: Icons.home, route: '/home'),
      const NavigationItem(
        title: 'Games',
        icon: Icons.games,
        route: '/game-modes',
      ),
      const NavigationItem(
        title: 'AI Tutor',
        icon: Icons.smart_toy,
        route: '/ai-tutor',
      ),
      const NavigationItem(
        title: 'Settings',
        icon: Icons.settings,
        route: '/settings',
      ),
      const NavigationItem(
        title: 'Profile',
        icon: Icons.person,
        route: '/profile',
      ),
    ];

    return ResponsiveLayout(
      currentRoute: '/settings/games',
      navigationItems: navigationItems,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false, // Disable default back button
          leading: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // Check if we can go back, otherwise go to settings
                if (context.canPop()) {
                  GoRouter.of(context).pop();
                } else {
                  context.go('/settings');
                }
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.chevron_left,
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 24, // Consistent sizing
                ),
              ),
            ),
          ),
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
        body: _fadeAnimation != null
            ? FadeTransition(
                opacity: _fadeAnimation!,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    textDirection: TextDirection.ltr,
                    children: [
                      // User Context Header
                      _buildUserContextHeader(themeData, colorScheme),

                      const SizedBox(height: 24),

                      // PRIMARY STUDENT CONTROLS - Clear Visual Selection

                      // Topic Selection - Primary Control
                      _buildAdvancedCard(
                        '📚 Choose Your Math Topic',
                        'Select what you want to practice today',
                        Icons.category,
                        Colors.blue,
                        _buildVisualTopicSelector(themeData, colorScheme),
                      ),

                      const SizedBox(height: 20),

                      // Difficulty Selection - Primary Control
                      _buildAdvancedCard(
                        '🎯 Choose Your Challenge Level',
                        'Pick the right difficulty for your grade and skill level',
                        Icons.trending_up,
                        Colors.orange,
                        _buildVisualDifficultySelector(themeData, colorScheme),
                      ),

                      const SizedBox(height: 20),

                      // Time Settings - Primary Control
                      _buildAdvancedCard(
                        '⏰ Set Your Time Preference',
                        'How much time do you want for each question?',
                        Icons.timer,
                        Colors.green,
                        _buildVisualTimeSelector(themeData, colorScheme),
                      ),

                      const SizedBox(height: 24),

                      // Game Mode Configuration
                      _buildGameModeConfiguration(themeData, colorScheme),

                      const SizedBox(height: 24),

                      // Adaptive Learning Settings
                      _buildAdvancedCard(
                        'Smart Learning Features',
                        'AI-powered features to help you learn better',
                        Icons.auto_awesome,
                        Colors.purple,
                        _buildAdaptiveLearningSettings(),
                      ),

                      const SizedBox(height: 24),

                      // Performance-Based Recommendations
                      if (_analytics != null)
                        _buildPerformanceRecommendations(themeData, colorScheme)
                      else if (!_analyticsLoaded)
                        _buildAdvancedCard(
                          'AI-Powered Recommendations',
                          'Loading your personalized recommendations...',
                          Icons.lightbulb,
                          Colors.amber,
                          const Center(
                            child: Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),

                      const SizedBox(height: 20),

                      // Question Count Selection - Enhanced Visual
                      _buildAdvancedCard(
                        '🔢 How Many Questions?',
                        'Choose how many questions you want per game',
                        Icons.quiz,
                        Colors.indigo,
                        _buildVisualQuestionSelector(themeData, colorScheme),
                      ),

                      const SizedBox(height: 20),

                      // Audio & Feedback - Enhanced Visual
                      _buildAdvancedCard(
                        '🔊 Sound & Feedback',
                        'Customize your game experience',
                        Icons.volume_up,
                        Colors.teal,
                        _buildVisualAudioSettings(themeData, colorScheme),
                      ),

                      const SizedBox(height: 24),

                      // Accessibility & Personalization
                      _buildAdvancedCard(
                        '♿ Accessibility & Personalization',
                        'Customize the interface for your needs',
                        Icons.accessibility,
                        Colors.cyan,
                        _buildAccessibilitySettings(themeData, colorScheme),
                      ),

                      const SizedBox(height: 24),

                      // Data Management
                      _buildAdvancedCard(
                        '💾 Data & Backup',
                        'Manage your preferences and data',
                        Icons.cloud_sync,
                        Colors.indigo,
                        _buildDataManagementSettings(themeData, colorScheme),
                      ),

                      const SizedBox(height: 32),

                      // Reset to Defaults
                      ElevatedButton.icon(
                        onPressed: _resetToDefaults,
                        icon: const Icon(Icons.restore),
                        label: const Text('Reset to Defaults'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerHighest,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  textDirection: TextDirection.ltr,
                  children: [
                    // User Context Header
                    _buildUserContextHeader(themeData, colorScheme),

                    const SizedBox(height: 24),

                    // Basic settings while animations load
                    _buildPreferenceCard(
                      'Basic Settings',
                      'Configure your game preferences',
                      Icons.settings,
                      const Text('Loading advanced features...'),
                    ),
                  ],
                ),
              ),
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
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: Theme.of(context).primaryColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              content,
            ],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDifficultySelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: GameDifficulty.values.map((difficulty) {
        final isSelected = _preferences!.preferredDifficulty == difficulty;
        final color = _getDifficultyColor(difficulty);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: FilterChip(
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDifficultyIcon(difficulty),
                  size: 16,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  _getDifficultyDisplayName(difficulty),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : color,
                  ),
                ),
              ],
            ),
            selected: isSelected,
            selectedColor: color,
            backgroundColor: color.withValues(alpha: 0.1),
            side: BorderSide(color: color, width: isSelected ? 2 : 1),
            onSelected: (selected) {
              if (selected) {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    preferredDifficulty: difficulty,
                  );
                });
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Color _getDifficultyColor(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return Colors.green;
      case GameDifficulty.normal:
        return Colors.blue;
      case GameDifficulty.genius:
        return Colors.orange;
      case GameDifficulty.quantum:
        return Colors.red;
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

  String _getDifficultyDisplayName(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 'Easy';
      case GameDifficulty.normal:
        return 'Normal';
      case GameDifficulty.genius:
        return 'Genius';
      case GameDifficulty.quantum:
        return 'Quantum';
    }
  }

  // ignore: unused_element
  Widget _buildTopicMixingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quick Mix Presets
        Text(
          'Quick Mix Options',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildMixPresetChip(
              'Basic Math',
              'Addition, Subtraction, Multiplication, Division',
              Icons.calculate,
              Colors.blue,
              () => _selectBasicOperations(),
            ),
            _buildMixPresetChip(
              'Numbers Focus',
              'Fractions, Decimals, Percentages',
              Icons.pin,
              Colors.orange,
              () => _selectNumbersFocus(),
            ),
            _buildMixPresetChip(
              'Advanced Mix',
              'Algebra, Geometry, Word Problems',
              Icons.functions,
              Colors.green,
              () => _selectAdvancedMix(),
            ),
            _buildMixPresetChip(
              'Everything',
              'All math topics mixed together',
              Icons.shuffle,
              Colors.purple,
              () => _selectEverything(),
            ),
          ],
        ),

        const SizedBox(height: 20),

        const Divider(),

        const SizedBox(height: 16),

        Text(
          'Or Choose Individual Topics',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        // Basic Math Operations
        _buildCategoryGroup('Basic Operations', Icons.calculate, Colors.blue, [
          GameCategory.addition,
          GameCategory.subtraction,
          GameCategory.multiplication,
          GameCategory.division,
        ]),

        const SizedBox(height: 12),

        // Advanced Math
        _buildCategoryGroup('Advanced Math', Icons.functions, Colors.green, [
          GameCategory.algebra,
          GameCategory.geometry,
          GameCategory.calculus,
        ]),

        const SizedBox(height: 12),

        // Numbers & Decimals
        _buildCategoryGroup('Numbers & Decimals', Icons.pin, Colors.orange, [
          GameCategory.fractions,
          GameCategory.decimals,
          GameCategory.percentages,
        ]),

        const SizedBox(height: 12),

        // Applied Math
        _buildCategoryGroup(
          'Applied Math',
          Icons.real_estate_agent,
          Colors.purple,
          [
            GameCategory.wordProblems,
            GameCategory.measurement,
            GameCategory.dataAnalysis,
            GameCategory.patterns,
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryGroup(
    String groupName,
    IconData groupIcon,
    Color groupColor,
    List<GameCategory> categories,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(groupIcon, color: groupColor, size: 20),
            const SizedBox(width: 8),
            Text(
              groupName,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: groupColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: categories.map((category) {
            final isSelected = _preferences!.preferredCategory == category;
            return FilterChip(
              label: Text(_getCategoryDisplayName(category)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      preferredCategory: category,
                    );
                  });
                }
              },
              avatar: Icon(
                _getCategoryIcon(category),
                size: 16,
                color: isSelected ? Colors.white : groupColor,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  String _getCategoryDisplayName(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return 'Addition (+)';
      case GameCategory.subtraction:
        return 'Subtraction (−)';
      case GameCategory.multiplication:
        return 'Multiplication (×)';
      case GameCategory.division:
        return 'Division (÷)';
      case GameCategory.algebra:
        return 'Algebra (x, y)';
      case GameCategory.geometry:
        return 'Geometry (△, ◯)';
      case GameCategory.calculus:
        return 'Calculus (∫, ∂)';
      case GameCategory.fractions:
        return 'Fractions (½, ¾)';
      case GameCategory.decimals:
        return 'Decimals (0.5, 2.75)';
      case GameCategory.percentages:
        return 'Percentages (25%, 50%)';
      case GameCategory.wordProblems:
        return 'Word Problems';
      case GameCategory.measurement:
        return 'Measurement (cm, kg)';
      case GameCategory.dataAnalysis:
        return 'Data & Graphs';
      case GameCategory.patterns:
        return 'Patterns & Sequences';
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
      case GameCategory.algebra:
        return Icons.functions;
      case GameCategory.geometry:
        return Icons.square;
      case GameCategory.calculus:
        return Icons.auto_graph;
      case GameCategory.fractions:
        return Icons.pie_chart;
      case GameCategory.decimals:
        return Icons.more_horiz;
      case GameCategory.percentages:
        return Icons.percent;
      case GameCategory.wordProblems:
        return Icons.article;
      case GameCategory.measurement:
        return Icons.straighten;
      case GameCategory.dataAnalysis:
        return Icons.bar_chart;
      case GameCategory.patterns:
        return Icons.pattern;
    }
  }

  // ignore: unused_element
  Widget _buildTimeSettings() {
    final timeLimits = [
      {'time': 15, 'label': 'Quick', 'desc': 'Fast-paced'},
      {'time': 30, 'label': 'Normal', 'desc': 'Balanced'},
      {'time': 45, 'label': 'Relaxed', 'desc': 'Take your time'},
      {'time': 60, 'label': 'Extended', 'desc': 'Think deeply'},
      {'time': 90, 'label': 'Long', 'desc': 'Complex problems'},
      {'time': 120, 'label': 'Marathon', 'desc': 'No rush'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.timer, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'Current: ${_preferences!.preferredTimeLimit} seconds per question',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: timeLimits.map((timeData) {
            final time = timeData['time'] as int;
            final label = timeData['label'] as String;
            final desc = timeData['desc'] as String;
            final isSelected = _preferences!.preferredTimeLimit == time;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: FilterChip(
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${time}s',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: isSelected ? Colors.white : Colors.blue[700],
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: isSelected ? Colors.white70 : Colors.blue[600],
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: Colors.blue,
                backgroundColor: Colors.blue.withValues(alpha: 0.1),
                side: BorderSide(color: Colors.blue, width: isSelected ? 2 : 1),
                tooltip: desc,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        preferredTimeLimit: time,
                      );
                    });
                  }
                },
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildQuestionSettings() {
    final questionCounts = [5, 10, 15, 20, 25, 30];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Questions per game: ${_preferences!.preferredQuestionCount}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
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
                    _preferences = _preferences!.copyWith(
                      preferredQuestionCount: count,
                    );
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ignore: unused_element
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
              _preferences = _preferences!.copyWith(
                hapticFeedbackEnabled: value,
              );
            });
          },
        ),
        SwitchListTile(
          title: const Text('Auto-Start Next Game'),
          subtitle: const Text(
            'Automatically start a new game after completion',
          ),
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
        content: const Text(
          'This will reset all game preferences to default values. Continue?',
        ),
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

  Widget _buildMixPresetChip(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ActionChip(
      avatar: Icon(icon, color: color, size: 18),
      label: Text(title),
      onPressed: onTap,
      backgroundColor: color.withValues(alpha: 0.1),
      side: BorderSide(color: color),
      tooltip: description,
    );
  }

  // Mix preset selection methods
  void _selectBasicOperations() {
    setState(() {
      _preferences = _preferences!.copyWith(
        preferredCategory: GameCategory.addition,
      );
    });
    _showMixInfo(
      'Basic Math Mix',
      'Games will include Addition, Subtraction, Multiplication, and Division',
    );
  }

  void _selectNumbersFocus() {
    setState(() {
      _preferences = _preferences!.copyWith(
        preferredCategory: GameCategory.fractions,
      );
    });
    _showMixInfo(
      'Numbers Focus Mix',
      'Games will include Fractions, Decimals, and Percentages',
    );
  }

  void _selectAdvancedMix() {
    setState(() {
      _preferences = _preferences!.copyWith(
        preferredCategory: GameCategory.algebra,
      );
    });
    _showMixInfo(
      'Advanced Math Mix',
      'Games will include Algebra, Geometry, and Word Problems',
    );
  }

  void _selectEverything() {
    setState(() {
      _preferences = _preferences!.copyWith(
        preferredCategory: GameCategory.wordProblems,
      );
    });
    _showMixInfo(
      'Everything Mix',
      'Games will randomly include all available math topics',
    );
  }

  void _showMixInfo(String title, String description) {
    AdaptiveUISystem.showAdaptiveSnackBar(
      context: context,
      message: '$title selected! $description',
      isError: false,
    );
  }

  // Advanced method implementations
  Widget _buildUserContextHeader(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withValues(alpha: 0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: colorScheme.primary,
                child: Text(
                  _currentUser?.displayName.substring(0, 1).toUpperCase() ??
                      'S',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.displayName ?? 'Student',
                      style: themeData.typography.titleLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'Grade ${_userGrade.name.replaceAll('grade', '')} • ${_currentUser?.role.name.toUpperCase() ?? 'STUDENT'}',
                      style: themeData.typography.bodyMedium.copyWith(
                        color: colorScheme.onPrimaryContainer.withValues(
                          alpha: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Level ${_analytics?.overallProgress.level ?? 1}',
                  style: TextStyle(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          if (_analytics != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                _buildContextStat(
                  'Accuracy',
                  '${_analytics!.overallProgress.percentage.round()}%',
                  Icons.track_changes,
                  colorScheme,
                ),
                const SizedBox(width: 16),
                _buildContextStat(
                  'XP Points',
                  '${_analytics!.overallProgress.experiencePoints}',
                  Icons.stars,
                  colorScheme,
                ),
                const SizedBox(width: 16),
                _buildContextStat(
                  'Streak',
                  '${_analytics!.studyStreak.currentStreak} days',
                  Icons.local_fire_department,
                  colorScheme,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContextStat(
    String label,
    String value,
    IconData icon,
    ColorScheme colorScheme,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: colorScheme.primary, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
                fontSize: 14,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Missing method implementations
  Widget _buildGameModeConfiguration(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return _buildAdvancedCard(
      'Game Mode Preferences',
      'Configure each game mode for optimal learning',
      Icons.games,
      colorScheme.primary,
      Column(
        children: [
          // Classic Quiz Configuration
          _buildGameModeCard(
            'Classic Quiz',
            'Traditional multiple-choice with grade-aware difficulty',
            Icons.quiz,
            Colors.blue,
            themeData,
            colorScheme,
            _buildClassicQuizEnhanced(),
          ),

          const SizedBox(height: 16),

          // AI-Native Quiz Configuration
          _buildGameModeCard(
            'AI-Native Quiz',
            'Adaptive AI questions based on performance',
            Icons.psychology,
            Colors.green,
            themeData,
            colorScheme,
            _buildAINativeEnhanced(),
          ),

          const SizedBox(height: 16),

          // ChatGPT Enhanced Configuration
          _buildGameModeCard(
            'ChatGPT Enhanced',
            'Real AI tutoring with personalized explanations',
            Icons.auto_awesome,
            Colors.purple,
            themeData,
            colorScheme,
            _buildChatGPTEnhanced(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveLearningSettings() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Auto-Adjust Difficulty'),
          subtitle: const Text(
            'Automatically adjust based on accuracy (target: 75-85%)',
          ),
          value: _preferences?.autoAdjustDifficulty ?? false,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(
                autoAdjustDifficulty: value,
              );
            });
          },
        ),
        SwitchListTile(
          title: const Text('Smart Topic Rotation'),
          subtitle: const Text('Focus on weak areas, review strong areas'),
          value: _preferences?.smartTopicRotation ?? false,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(smartTopicRotation: value);
            });
          },
        ),
        SwitchListTile(
          title: const Text('Spaced Repetition'),
          subtitle: const Text(
            'Review topics at optimal intervals for long-term retention',
          ),
          value: _preferences?.spacedRepetition ?? false,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(spacedRepetition: value);
            });
          },
        ),

        const SizedBox(height: 20),

        // Learning Intensity Slider
        Text(
          'Learning Intensity: ${_getLearningIntensityLabel(_preferences?.learningIntensity ?? 0.5)}',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Slider(
          value: _preferences?.learningIntensity ?? 0.5,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          label: _getLearningIntensityLabel(
            _preferences?.learningIntensity ?? 0.5,
          ),
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(learningIntensity: value);
            });
          },
        ),
        Text(
          _getIntensityDescription(_preferences?.learningIntensity ?? 0.5),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceRecommendations(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return _buildAdvancedCard(
      'AI-Powered Recommendations',
      'Personalized suggestions based on your ${_analytics?.recentActivity.length ?? 0} recent activities',
      Icons.lightbulb,
      Colors.amber,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_strugglingTopics.isNotEmpty) ...[
            _buildRecommendationSection(
              'Focus Areas (Need Practice)',
              'These topics need more attention based on your performance',
              Icons.trending_down,
              Colors.orange,
              _strugglingTopics.map((topic) {
                final mastery = _topicMastery[topic] ?? 0.0;
                return '${_getCategoryDisplayName(topic)} - Current: ${mastery.round()}%';
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (_masteredTopics.isNotEmpty) ...[
            _buildRecommendationSection(
              'Challenge Ready (Mastered)',
              'You\'ve mastered these - try harder difficulty!',
              Icons.emoji_events,
              Colors.green,
              _masteredTopics.map((topic) {
                final mastery = _topicMastery[topic] ?? 0.0;
                return '${_getCategoryDisplayName(topic)} - Mastery: ${mastery.round()}%';
              }).toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Next Session Recommendation
          _buildNextSessionCard(themeData, colorScheme),

          if (_strugglingTopics.isEmpty && _masteredTopics.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Complete more games to unlock AI-powered recommendations and personalized learning paths!',
                      style: TextStyle(color: Colors.blue[700]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvancedCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Widget content,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            content,
          ],
        ),
      ),
    );
  }

  // PRIMARY VISUAL SELECTORS FOR STUDENTS

  Widget _buildVisualTopicSelector(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Current Selection Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.withValues(alpha: 0.1),
                Colors.blue.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getTopicIcon(_preferences!.preferredCategory),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently Selected:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _getTopicDisplayName(_preferences!.preferredCategory),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (_topicMastery[_preferences!.preferredCategory] != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getMasteryColor(
                      _topicMastery[_preferences!.preferredCategory]!,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${_topicMastery[_preferences!.preferredCategory]!.round()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Topic Categories with Visual Groups
        _buildTopicCategoryGroup(
          'Basic Math Operations',
          '➕ ➖ ✖️ ➗',
          Icons.calculate,
          Colors.blue,
          [
            GameCategory.addition,
            GameCategory.subtraction,
            GameCategory.multiplication,
            GameCategory.division,
          ],
          themeData,
          colorScheme,
        ),

        const SizedBox(height: 12),

        _buildTopicCategoryGroup(
          'Numbers & Fractions',
          '½ 0.5 25%',
          Icons.pie_chart,
          Colors.orange,
          [
            GameCategory.fractions,
            GameCategory.decimals,
            GameCategory.percentages,
          ],
          themeData,
          colorScheme,
        ),

        const SizedBox(height: 12),

        _buildTopicCategoryGroup(
          'Advanced Math',
          'x² △ ∫',
          Icons.functions,
          Colors.green,
          [GameCategory.algebra, GameCategory.geometry, GameCategory.calculus],
          themeData,
          colorScheme,
        ),

        const SizedBox(height: 12),

        _buildTopicCategoryGroup(
          'Real World Math',
          '📏 📊 🧩',
          Icons.real_estate_agent,
          Colors.purple,
          [
            GameCategory.measurement,
            GameCategory.dataAnalysis,
            GameCategory.wordProblems,
            GameCategory.patterns,
          ],
          themeData,
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildVisualDifficultySelector(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final gradeRecommendations = _getGradeRecommendedDifficulties();

    return Column(
      children: [
        // Current Selection Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange.withValues(alpha: 0.1),
                Colors.orange.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getDifficultyColor(_preferences!.preferredDifficulty),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getDifficultyIcon(_preferences!.preferredDifficulty),
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Level:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _preferences!.preferredDifficulty.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[700],
                      ),
                    ),
                  ],
                ),
              ),
              if (gradeRecommendations.contains(
                _preferences!.preferredDifficulty,
              ))
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.star, color: Colors.white, size: 12),
                      const SizedBox(width: 4),
                      Text(
                        'Grade ${_userGrade.name.replaceAll('grade', '')}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Visual Difficulty Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: GameDifficulty.values.map((difficulty) {
            final isRecommended = gradeRecommendations.contains(difficulty);
            final isSelected = _preferences!.preferredDifficulty == difficulty;
            final color = _getDifficultyColor(difficulty);

            return GestureDetector(
              onTap: () {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    preferredDifficulty: difficulty,
                  );
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withValues(alpha: 0.2)
                      : color.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected ? color : color.withValues(alpha: 0.3),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Icon(
                              _getDifficultyIcon(difficulty),
                              size: 24,
                              color: color,
                            ),
                            if (isRecommended)
                              Container(
                                padding: const EdgeInsets.all(1),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.star,
                                  size: 8,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                      ),
                      Flexible(
                        child: Text(
                          difficulty.name.toUpperCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: color,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          _getDifficultyDescription(difficulty),
                          style: TextStyle(
                            fontSize: 9,
                            color: color.withValues(alpha: 0.8),
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisualTimeSelector(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final timeOptions = [
      {'time': 15, 'label': 'Quick', 'desc': 'Fast & Fun', 'emoji': '⚡'},
      {'time': 30, 'label': 'Normal', 'desc': 'Just Right', 'emoji': '⏰'},
      {'time': 45, 'label': 'Relaxed', 'desc': 'Take Your Time', 'emoji': '🌸'},
      {'time': 60, 'label': 'Thoughtful', 'desc': 'Think Deep', 'emoji': '🤔'},
    ];

    return Column(
      children: [
        // Current Selection Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.green.withValues(alpha: 0.1),
                Colors.green.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.timer, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Time Setting:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_preferences!.preferredTimeLimit} seconds per question',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Visual Time Option Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.8,
          children: timeOptions.map((timeData) {
            final time = timeData['time'] as int;
            final emoji = timeData['emoji'] as String;
            final isSelected = _preferences!.preferredTimeLimit == time;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    preferredTimeLimit: time,
                  );
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green.withValues(alpha: 0.2)
                      : Colors.green.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.green
                        : Colors.green.withValues(alpha: 0.3),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.green.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '${time}s',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green[700],
                            fontSize: 10,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTopicCategoryGroup(
    String groupName,
    String symbols,
    IconData groupIcon,
    Color groupColor,
    List<GameCategory> categories,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: groupColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: groupColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: groupColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(groupIcon, color: groupColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      groupName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: groupColor,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      symbols,
                      style: TextStyle(
                        fontSize: 16,
                        color: groupColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories.map((category) {
              final isSelected = _preferences!.preferredCategory == category;
              final mastery = _topicMastery[category] ?? 0.0;

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      preferredCategory: category,
                    );
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? groupColor.withValues(alpha: 0.2)
                        : groupColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? groupColor
                          : groupColor.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getTopicIcon(category),
                        size: 16,
                        color: isSelected
                            ? groupColor
                            : groupColor.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _getTopicDisplayName(category),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: isSelected
                              ? groupColor
                              : groupColor.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                      if (mastery > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getMasteryColor(mastery),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${mastery.round()}%',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 8,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Enhanced helper methods
  Widget _buildGameModeCard(
    String title,
    String description,
    IconData icon,
    Color color,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    Widget settings,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        title: Text(
          title,
          style: themeData.typography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          description,
          style: themeData.typography.bodySmall.copyWith(
            color: colorScheme.onSurface.withValues(alpha: 0.7),
          ),
        ),
        children: [Padding(padding: const EdgeInsets.all(16), child: settings)],
      ),
    );
  }

  Widget _buildClassicQuizEnhanced() {
    final gradeRecommendations = _getGradeRecommendedDifficulties();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grade ${_userGrade.name.replaceAll('grade', '')} Recommendations:',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.blue[700],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: GameDifficulty.values.map((difficulty) {
            final isRecommended = gradeRecommendations.contains(difficulty);
            final isSelected = _preferences!.preferredDifficulty == difficulty;

            return FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(difficulty.name.toUpperCase()),
                  if (isRecommended) ...[
                    const SizedBox(width: 4),
                    const Icon(Icons.star, size: 12, color: Colors.amber),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: isRecommended
                  ? Colors.amber.withValues(alpha: 0.3)
                  : Colors.blue.withValues(alpha: 0.3),
              backgroundColor: isRecommended
                  ? Colors.amber.withValues(alpha: 0.1)
                  : Colors.blue.withValues(alpha: 0.1),
              side: BorderSide(
                color: isRecommended ? Colors.amber : Colors.blue,
                width: isSelected ? 2 : 1,
              ),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      preferredDifficulty: difficulty,
                    );
                  });
                }
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAINativeEnhanced() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Adaptation Controls
        Text(
          'AI Learning Adaptation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        // Question Generation Style
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Question Generation Style',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildAIStyleChip(
                    'Adaptive',
                    'Questions adapt to your performance',
                    _preferences!.aiStyle == 'Adaptive',
                  ),
                  _buildAIStyleChip(
                    'Progressive',
                    'Gradually increase difficulty',
                    _preferences!.aiStyle == 'Progressive',
                  ),
                  _buildAIStyleChip(
                    'Mixed',
                    'Random difficulty levels',
                    _preferences!.aiStyle == 'Mixed',
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Performance Tracking Display
        if (_analytics != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.1),
                  Colors.blue.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Performance Analysis',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildPerformanceMetric(
                        'Accuracy',
                        '${_analytics!.overallProgress.percentage.round()}%',
                        Icons.track_changes,
                        _getPerformanceColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildPerformanceMetric(
                        'Learning Rate',
                        '${(_analytics!.learningVelocity * 100).round()}%',
                        Icons.trending_up,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 16),

        // AI Personality Settings
        Text(
          'AI Tutor Personality',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.green[700],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildPersonalityChip(
              'Encouraging',
              '🌟',
              _preferences!.aiPersonality == 'Encouraging',
            ),
            _buildPersonalityChip(
              'Challenging',
              '🎯',
              _preferences!.aiPersonality == 'Challenging',
            ),
            _buildPersonalityChip(
              'Patient',
              '🤗',
              _preferences!.aiPersonality == 'Patient',
            ),
            _buildPersonalityChip(
              'Energetic',
              '⚡',
              _preferences!.aiPersonality == 'Energetic',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChatGPTEnhanced() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ChatGPT Model Selection
        Text(
          'ChatGPT Model Configuration',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.purple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.purple.withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AI Model Selection',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple[700],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _buildModelChip(
                    'GPT-4',
                    'Most Advanced',
                    _preferences!.chatGPTModel == 'GPT-4',
                    Colors.purple,
                  ),
                  _buildModelChip(
                    'GPT-3.5',
                    'Fast & Efficient',
                    _preferences!.chatGPTModel == 'GPT-3.5',
                    Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Tutoring Style
        Text(
          'Tutoring Style',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildTutoringStyleCard(
              'Socratic',
              'Ask questions to guide learning',
              Icons.help_outline,
              Colors.purple,
            ),
            _buildTutoringStyleCard(
              'Direct',
              'Clear explanations and examples',
              Icons.lightbulb,
              Colors.orange,
            ),
            _buildTutoringStyleCard(
              'Visual',
              'Use diagrams and illustrations',
              Icons.image,
              Colors.green,
            ),
            _buildTutoringStyleCard(
              'Step-by-Step',
              'Break down complex problems',
              Icons.list,
              Colors.blue,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Explanation Depth Control
        Text(
          'Explanation Detail Level',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),

        Slider(
          value: _preferences?.learningIntensity ?? 0.5,
          min: 0.1,
          max: 1.0,
          divisions: 9,
          label: _getExplanationDepthLabel(
            _preferences?.learningIntensity ?? 0.5,
          ),
          activeColor: Colors.purple,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(learningIntensity: value);
            });
          },
        ),
        Text(
          _getExplanationDepthDescription(
            _preferences?.learningIntensity ?? 0.5,
          ),
          style: TextStyle(
            fontSize: 12,
            color: Colors.purple.withValues(alpha: 0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildRecommendationSection(
    String title,
    String description,
    IconData icon,
    Color color,
    List<String> recommendations,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...recommendations.map(
            (rec) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.arrow_right, color: color, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      rec,
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface,
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

  Widget _buildNextSessionCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final recommendedTopic = _getRecommendedNextTopic();
    final recommendedDifficulty = _getRecommendedDifficulty();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.withValues(alpha: 0.1),
            Colors.purple.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Text(
                'AI Recommended Next Session',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Topic: ${_getCategoryDisplayName(recommendedTopic)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Difficulty: ${recommendedDifficulty.name.toUpperCase()}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      preferredCategory: recommendedTopic,
                      preferredDifficulty: recommendedDifficulty,
                    );
                  });
                  _savePreferences();
                },
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Apply'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Helper methods for enhanced functionality
  List<GameDifficulty> _getGradeRecommendedDifficulties() {
    switch (_userGrade) {
      case GradeLevel.kindergarten:
      case GradeLevel.grade1:
      case GradeLevel.grade2:
        return [GameDifficulty.easy];
      case GradeLevel.grade3:
      case GradeLevel.grade4:
        return [GameDifficulty.easy, GameDifficulty.normal];
      case GradeLevel.grade5:
      case GradeLevel.grade6:
        return [GameDifficulty.normal, GameDifficulty.genius];
      case GradeLevel.grade7:
      case GradeLevel.grade8:
      case GradeLevel.grade9:
      case GradeLevel.grade10:
      case GradeLevel.grade11:
      case GradeLevel.grade12:
        return [GameDifficulty.genius, GameDifficulty.quantum];
      default:
        return [GameDifficulty.normal];
    }
  }

  String _getLearningIntensityLabel(double intensity) {
    if (intensity <= 0.3) return 'Relaxed';
    if (intensity <= 0.5) return 'Balanced';
    if (intensity <= 0.7) return 'Focused';
    return 'Intensive';
  }

  String _getIntensityDescription(double intensity) {
    if (intensity <= 0.3) {
      return 'Take your time, focus on understanding concepts';
    }
    if (intensity <= 0.5) {
      return 'Balanced learning pace with moderate challenges';
    }
    if (intensity <= 0.7) {
      return 'Focused practice with increased difficulty progression';
    }
    return 'Intensive training with maximum challenge and rapid progression';
  }

  // ignore: unused_element
  String _getPerformanceFeedback() {
    if (_analytics == null) return 'No data yet';
    final accuracy = _analytics!.overallProgress.percentage;
    if (accuracy >= 85) return 'Excellent performance!';
    if (accuracy >= 70) return 'Good progress';
    if (accuracy >= 50) return 'Keep practicing';
    return 'Needs improvement';
  }

  Color _getPerformanceColor() {
    if (_analytics == null) return Colors.grey;
    final accuracy = _analytics!.overallProgress.percentage;
    if (accuracy >= 85) return Colors.green;
    if (accuracy >= 70) return Colors.blue;
    if (accuracy >= 50) return Colors.orange;
    return Colors.red;
  }

  GameCategory _getRecommendedNextTopic() {
    if (_strugglingTopics.isNotEmpty) {
      return _strugglingTopics.first; // Focus on weakest area
    }
    if (_masteredTopics.isNotEmpty) {
      // If all topics are mastered, recommend a new challenge
      final allTopics = GameCategory.values;
      final untriedTopics = allTopics
          .where((topic) => !_masteredTopics.contains(topic))
          .toList();
      if (untriedTopics.isNotEmpty) return untriedTopics.first;
    }
    return _preferences?.preferredCategory ?? GameCategory.addition;
  }

  GameDifficulty _getRecommendedDifficulty() {
    if (_analytics == null) {
      return _preferences?.preferredDifficulty ?? GameDifficulty.normal;
    }

    final accuracy = _analytics!.overallProgress.percentage;
    final gradeRecommendations = _getGradeRecommendedDifficulties();

    // If accuracy is high, suggest harder difficulty within grade range
    if (accuracy >= 85 &&
        gradeRecommendations.contains(GameDifficulty.genius)) {
      return GameDifficulty.genius;
    }
    if (accuracy >= 90 &&
        gradeRecommendations.contains(GameDifficulty.quantum)) {
      return GameDifficulty.quantum;
    }

    // If accuracy is low, suggest easier difficulty
    if (accuracy < 60 && gradeRecommendations.contains(GameDifficulty.easy)) {
      return GameDifficulty.easy;
    }

    // Default to normal if within grade recommendations
    return gradeRecommendations.contains(GameDifficulty.normal)
        ? GameDifficulty.normal
        : gradeRecommendations.first;
  }

  // Helper methods for visual selectors
  IconData _getTopicIcon(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return Icons.add_circle;
      case GameCategory.subtraction:
        return Icons.remove_circle;
      case GameCategory.multiplication:
        return Icons.close;
      case GameCategory.division:
        return Icons.call_split;
      case GameCategory.fractions:
        return Icons.pie_chart;
      case GameCategory.decimals:
        return Icons.looks_one;
      case GameCategory.algebra:
        return Icons.functions;
      case GameCategory.geometry:
        return Icons.change_history;
      case GameCategory.percentages:
        return Icons.percent;
      case GameCategory.wordProblems:
        return Icons.article;
      case GameCategory.measurement:
        return Icons.straighten;
      case GameCategory.dataAnalysis:
        return Icons.bar_chart;
      case GameCategory.patterns:
        return Icons.pattern;
      case GameCategory.calculus:
        return Icons.timeline;
    }
  }

  String _getTopicDisplayName(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return 'Addition';
      case GameCategory.subtraction:
        return 'Subtraction';
      case GameCategory.multiplication:
        return 'Multiplication';
      case GameCategory.division:
        return 'Division';
      case GameCategory.fractions:
        return 'Fractions';
      case GameCategory.decimals:
        return 'Decimals';
      case GameCategory.algebra:
        return 'Algebra';
      case GameCategory.geometry:
        return 'Geometry';
      case GameCategory.percentages:
        return 'Percentages';
      case GameCategory.wordProblems:
        return 'Word Problems';
      case GameCategory.measurement:
        return 'Measurement';
      case GameCategory.dataAnalysis:
        return 'Data Analysis';
      case GameCategory.patterns:
        return 'Patterns';
      case GameCategory.calculus:
        return 'Calculus';
    }
  }

  String _getDifficultyDescription(GameDifficulty difficulty) {
    switch (difficulty) {
      case GameDifficulty.easy:
        return 'Perfect for beginners';
      case GameDifficulty.normal:
        return 'Good challenge level';
      case GameDifficulty.genius:
        return 'For math experts';
      case GameDifficulty.quantum:
        return 'Ultimate challenge';
    }
  }

  Color _getMasteryColor(double mastery) {
    if (mastery >= 80) return Colors.green;
    if (mastery >= 60) return Colors.orange;
    return Colors.red;
  }

  Widget _buildVisualQuestionSelector(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final questionOptions = [
      {'count': 5, 'label': 'Quick', 'desc': 'Short & Sweet', 'emoji': '⚡'},
      {
        'count': 10,
        'label': 'Standard',
        'desc': 'Perfect Balance',
        'emoji': '🎯',
      },
      {
        'count': 15,
        'label': 'Extended',
        'desc': 'More Practice',
        'emoji': '📚',
      },
      {
        'count': 20,
        'label': 'Marathon',
        'desc': 'Deep Learning',
        'emoji': '🏃',
      },
      {
        'count': 50,
        'label': 'Challenge',
        'desc': 'Serious Practice',
        'emoji': '💪',
      },
      {'count': 75, 'label': 'Expert', 'desc': 'Master Level', 'emoji': '🧠'},
      {
        'count': 100,
        'label': 'Ultimate',
        'desc': 'Maximum Challenge',
        'emoji': '🚀',
      },
    ];

    return Column(
      children: [
        // Current Selection Display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.indigo.withValues(alpha: 0.1),
                Colors.indigo.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.quiz, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questions Per Game:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.indigo[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${_preferences!.preferredQuestionCount} questions',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Visual Question Count Cards
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          crossAxisSpacing: 6,
          mainAxisSpacing: 6,
          childAspectRatio: 1.8,
          children: questionOptions.map((option) {
            final count = option['count'] as int;
            final emoji = option['emoji'] as String;
            final isSelected = _preferences!.preferredQuestionCount == count;

            return GestureDetector(
              onTap: () {
                setState(() {
                  _preferences = _preferences!.copyWith(
                    preferredQuestionCount: count,
                  );
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.indigo.withValues(alpha: 0.2)
                      : Colors.indigo.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? Colors.indigo
                        : Colors.indigo.withValues(alpha: 0.3),
                    width: isSelected ? 3 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: Colors.indigo.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          emoji,
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Flexible(
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.indigo[700],
                            fontSize: 9,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisualAudioSettings(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Sound Effects Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _preferences!.soundEnabled
                ? Colors.teal.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _preferences!.soundEnabled
                  ? Colors.teal.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _preferences!.soundEnabled ? Colors.teal : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _preferences!.soundEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sound Effects',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _preferences!.soundEnabled
                            ? Colors.teal[700]
                            : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _preferences!.soundEnabled
                          ? 'Sounds are ON'
                          : 'Sounds are OFF',
                      style: TextStyle(
                        fontSize: 12,
                        color: _preferences!.soundEnabled
                            ? Colors.teal[600]
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _preferences!.soundEnabled,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences!.copyWith(soundEnabled: value);
                  });
                },
                activeColor: Colors.teal,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Haptic Feedback Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _preferences!.hapticFeedbackEnabled
                ? Colors.teal.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _preferences!.hapticFeedbackEnabled
                  ? Colors.teal.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _preferences!.hapticFeedbackEnabled
                      ? Colors.teal
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _preferences!.hapticFeedbackEnabled
                      ? Icons.vibration
                      : Icons.phone_android,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Haptic Feedback',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _preferences!.hapticFeedbackEnabled
                            ? Colors.teal[700]
                            : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _preferences!.hapticFeedbackEnabled
                          ? 'Vibration is ON'
                          : 'Vibration is OFF',
                      style: TextStyle(
                        fontSize: 12,
                        color: _preferences!.hapticFeedbackEnabled
                            ? Colors.teal[600]
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _preferences!.hapticFeedbackEnabled,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      hapticFeedbackEnabled: value,
                    );
                  });
                },
                activeColor: Colors.teal,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Auto-Start Next Game Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _preferences!.autoStartNextGame
                ? Colors.teal.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _preferences!.autoStartNextGame
                  ? Colors.teal.withValues(alpha: 0.3)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _preferences!.autoStartNextGame
                      ? Colors.teal
                      : Colors.grey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _preferences!.autoStartNextGame
                      ? Icons.play_circle
                      : Icons.pause_circle,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Start Next Game',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _preferences!.autoStartNextGame
                            ? Colors.teal[700]
                            : Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _preferences!.autoStartNextGame
                          ? 'Auto-start is ON'
                          : 'Manual start',
                      style: TextStyle(
                        fontSize: 12,
                        color: _preferences!.autoStartNextGame
                            ? Colors.teal[600]
                            : Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _preferences!.autoStartNextGame,
                onChanged: (value) {
                  setState(() {
                    _preferences = _preferences!.copyWith(
                      autoStartNextGame: value,
                    );
                  });
                },
                activeColor: Colors.teal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // MISSING HELPER METHODS - CRITICAL FOR FULL FUNCTIONALITY

  Widget _buildAIStyleChip(String label, String description, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: Colors.green.withValues(alpha: 0.3),
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _preferences = _preferences!.copyWith(aiStyle: label);
          });
        }
      },
      tooltip: description,
    );
  }

  Widget _buildPersonalityChip(String label, String emoji, bool isSelected) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Text(emoji), const SizedBox(width: 4), Text(label)],
      ),
      selected: isSelected,
      selectedColor: Colors.green.withValues(alpha: 0.3),
      backgroundColor: Colors.green.withValues(alpha: 0.1),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _preferences = _preferences!.copyWith(aiPersonality: label);
          });
        }
      },
    );
  }

  Widget _buildPerformanceMetric(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildModelChip(
    String model,
    String description,
    bool isSelected,
    Color color,
  ) {
    return FilterChip(
      label: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(model, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(description, style: const TextStyle(fontSize: 10)),
        ],
      ),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.3),
      backgroundColor: color.withValues(alpha: 0.1),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _preferences = _preferences!.copyWith(chatGPTModel: model);
          });
        }
      },
    );
  }

  Widget _buildTutoringStyleCard(
    String style,
    String description,
    IconData icon,
    Color color,
  ) {
    final isSelected = _preferences!.tutoringStyle == style;

    return GestureDetector(
      onTap: () {
        setState(() {
          _preferences = _preferences!.copyWith(tutoringStyle: style);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 2),
            Text(
              style,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              description,
              style: TextStyle(
                fontSize: 8,
                color: color.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _getExplanationDepthLabel(double intensity) {
    if (intensity <= 0.3) return 'Simple';
    if (intensity <= 0.5) return 'Clear';
    if (intensity <= 0.7) return 'Detailed';
    return 'Comprehensive';
  }

  String _getExplanationDepthDescription(double intensity) {
    if (intensity <= 0.3) {
      return 'Short, simple explanations perfect for quick understanding';
    }
    if (intensity <= 0.5) {
      return 'Clear explanations with examples and basic reasoning';
    }
    if (intensity <= 0.7) {
      return 'Detailed explanations with step-by-step breakdowns';
    }
    return 'Comprehensive explanations with multiple approaches and deep insights';
  }

  Widget _buildAccessibilitySettings(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Font Size Control
        Text(
          'Font Size: ${(_preferences!.fontSize * 100).round()}%',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Slider(
          value: _preferences!.fontSize,
          min: 0.8,
          max: 1.5,
          divisions: 7,
          label: '${(_preferences!.fontSize * 100).round()}%',
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(fontSize: value);
            });
          },
        ),

        const SizedBox(height: 16),

        // Accessibility Toggles
        SwitchListTile(
          title: const Text('High Contrast Mode'),
          subtitle: const Text('Increase contrast for better visibility'),
          value: _preferences!.highContrastMode,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(highContrastMode: value);
            });
          },
        ),

        SwitchListTile(
          title: const Text('Screen Reader Optimized'),
          subtitle: const Text('Optimize for accessibility tools'),
          value: _preferences!.screenReaderOptimized,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(
                screenReaderOptimized: value,
              );
            });
          },
        ),

        SwitchListTile(
          title: const Text('Dyslexia-Friendly Mode'),
          subtitle: const Text('Use dyslexia-friendly fonts and spacing'),
          value: _preferences!.dyslexiaFriendlyMode,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(
                dyslexiaFriendlyMode: value,
              );
            });
          },
        ),

        SwitchListTile(
          title: const Text('Reduced Motion'),
          subtitle: const Text('Minimize animations and transitions'),
          value: _preferences!.reducedMotion,
          onChanged: (value) {
            setState(() {
              _preferences = _preferences!.copyWith(reducedMotion: value);
            });
          },
        ),

        const SizedBox(height: 16),

        // Visual Theme Selection
        Text(
          'Visual Theme',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildThemeChip(
              'Default',
              Icons.palette,
              _preferences!.visualTheme == 'default',
            ),
            _buildThemeChip(
              'Dark',
              Icons.dark_mode,
              _preferences!.visualTheme == 'dark',
            ),
            _buildThemeChip(
              'Colorful',
              Icons.color_lens,
              _preferences!.visualTheme == 'colorful',
            ),
            _buildThemeChip(
              'Minimal',
              Icons.minimize,
              _preferences!.visualTheme == 'minimal',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDataManagementSettings(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      children: [
        // Sync Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.indigo.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.sync, color: Colors.indigo, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Last Sync',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo[700],
                      ),
                    ),
                    Text(
                      _formatSyncTime(
                        _preferences!.lastSyncTime ?? DateTime.now(),
                      ),
                      style: TextStyle(fontSize: 12, color: Colors.indigo[600]),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _syncNow,
                icon: const Icon(Icons.sync, size: 16),
                label: const Text('Sync Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Data Management Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _exportPreferences,
                icon: const Icon(Icons.download),
                label: const Text('Export'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _importPreferences,
                icon: const Icon(Icons.upload),
                label: const Text('Import'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Cloud Backup Toggle
        SwitchListTile(
          title: const Text('Cloud Backup'),
          subtitle: const Text('Automatically backup preferences to cloud'),
          value: _preferences!.cloudBackupSettings['enabled'] ?? false,
          onChanged: (value) {
            setState(() {
              final newCloudSettings = Map<String, dynamic>.from(
                _preferences!.cloudBackupSettings,
              );
              newCloudSettings['enabled'] = value;
              _preferences = _preferences!.copyWith(
                cloudBackupSettings: newCloudSettings,
              );
            });
          },
        ),
      ],
    );
  }

  Widget _buildThemeChip(String theme, IconData icon, bool isSelected) {
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [Icon(icon, size: 16), const SizedBox(width: 4), Text(theme)],
      ),
      selected: isSelected,
      selectedColor: Colors.cyan.withValues(alpha: 0.3),
      backgroundColor: Colors.cyan.withValues(alpha: 0.1),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _preferences = _preferences!.copyWith(
              visualTheme: theme.toLowerCase(),
            );
          });
        }
      },
    );
  }

  String _formatSyncTime(DateTime syncTime) {
    final now = DateTime.now();
    final difference = now.difference(syncTime);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }

  Future<void> _syncNow() async {
    setState(() => _isSaving = true);
    try {
      // Update sync time
      _preferences = _preferences!.copyWith(lastSyncTime: DateTime.now());
      await _savePreferences();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences synced successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Sync failed: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _exportPreferences() async {
    try {
      if (_preferences == null) return;

      // Create export data
      final exportData = {
        'mathGeniusPreferences': _preferences!.toJson(),
        'exportedAt': DateTime.now().toIso8601String(),
        'version': _preferences!.preferenceVersion,
        'userInfo': {
          'displayName': _currentUser?.displayName,
          'gradeLevel': _userGrade.name,
          'role': _currentUser?.role.name,
        },
      };

      // For now, copy to clipboard (file export requires platform-specific implementation)
      final exportJson = JsonEncoder.withIndent('  ').convert(exportData);

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Export Preferences'),
            content: SingleChildScrollView(
              child: SelectableText(
                exportJson,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  // Copy to clipboard functionality would go here
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Preferences exported to dialog!'),
                    ),
                  );
                },
                child: const Text('Copy'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    }
  }

  Future<void> _importPreferences() async {
    try {
      // Show import dialog with text input
      final result = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Import Preferences'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Paste your exported preferences JSON below:'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: 10,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Paste JSON here...',
                    ),
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(controller.text);
                },
                child: const Text('Import'),
              ),
            ],
          );
        },
      );

      if (result != null && result.isNotEmpty) {
        // Parse and validate JSON
        final importData = jsonDecode(result) as Map<String, dynamic>;
        final prefsData =
            importData['mathGeniusPreferences'] as Map<String, dynamic>;

        // Create preferences from imported data
        final importedPrefs = UserGamePreferences.fromJson(prefsData);

        // Update current preferences
        setState(() {
          _preferences = importedPrefs;
        });

        // Save imported preferences
        await _savePreferences();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Preferences imported successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Import failed: Invalid format or data - $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _fadeController?.dispose();
    super.dispose();
  }
}
