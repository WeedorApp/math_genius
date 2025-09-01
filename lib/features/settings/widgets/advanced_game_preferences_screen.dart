import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../../../core/barrel.dart';

// Game models
import '../../game/models/game_model.dart';

// User management
import '../../user_management/services/user_management_service.dart';
import '../../user_management/models/user_model.dart' as user_models;

// Student analytics
import '../../student/services/student_analytics_service.dart';

/// Advanced Game Preferences Screen
/// Grade-aware, user-aware, and context-aware game mode configuration
class AdvancedGamePreferencesScreen extends ConsumerStatefulWidget {
  const AdvancedGamePreferencesScreen({super.key});

  @override
  ConsumerState<AdvancedGamePreferencesScreen> createState() =>
      _AdvancedGamePreferencesScreenState();
}

class _AdvancedGamePreferencesScreenState
    extends ConsumerState<AdvancedGamePreferencesScreen>
    with TickerProviderStateMixin {
  // State management
  UserGamePreferences? _preferences;
  user_models.User? _currentUser;
  StudentAnalytics? _analytics;
  bool _isLoading = true;
  bool _isSaving = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Context awareness
  GradeLevel? _userGrade;
  Map<GameCategory, double> _topicMastery = {};
  List<GameCategory> _strugglingTopics = [];
  List<GameCategory> _masteredTopics = [];

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
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOut));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadUserContext() async {
    try {
      setState(() => _isLoading = true);

      // Load user information
      final userService = ref.read(userManagementServiceProvider);
      final user = await userService.getCurrentUser();

      // Load preferences
      final asyncPrefs = ref.read(userGamePreferencesNotifierProvider);

      // Load analytics for context awareness
      StudentAnalytics? analytics;
      if (user?.id != null) {
        try {
          final analyticsService = ref.read(studentAnalyticsServiceProvider);
          analytics = await analyticsService.getStudentAnalytics(user!.id);
        } catch (e) {
          debugPrint('Could not load analytics: $e');
        }
      }

      asyncPrefs.when(
        data: (prefs) {
          setState(() {
            _preferences = prefs;
            _currentUser = user;
            _analytics = analytics;
            _userGrade =
                GradeLevel.grade5; // TODO: Add gradeLevel to User model;
            _extractTopicMastery();
            _isLoading = false;
          });
        },
        loading: () {
          setState(() => _isLoading = true);
        },
        error: (error, stack) {
          setState(() {
            _preferences = UserGamePreferences(lastPlayed: DateTime.now());
            _currentUser = user;
            _userGrade =
                GradeLevel.grade5; // TODO: Add gradeLevel to User model;
            _isLoading = false;
          });
        },
      );
    } catch (e) {
      setState(() {
        _preferences = UserGamePreferences(lastPlayed: DateTime.now());
        _isLoading = false;
      });
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
        backgroundColor: colorScheme.surface,
        appBar: AppBar(
          title: Text(
            'Game Preferences',
            style: themeData.typography.headlineSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: colorScheme.onSurface,
            ),
            onPressed: () => context.go('/settings'),
          ),
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
              TextButton.icon(
                onPressed: _savePreferences,
                icon: const Icon(Icons.save),
                label: const Text('Save'),
              ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Context Header
                  _buildUserContextHeader(themeData, colorScheme),

                  const SizedBox(height: 24),

                  // Grade-Aware Game Mode Configuration
                  _buildGameModeConfiguration(themeData, colorScheme),

                  const SizedBox(height: 24),

                  // Adaptive Learning Settings
                  _buildAdaptiveLearningSettings(themeData, colorScheme),

                  const SizedBox(height: 24),

                  // Performance-Based Recommendations
                  _buildPerformanceRecommendations(themeData, colorScheme),

                  const SizedBox(height: 24),

                  // Personalization Settings
                  _buildPersonalizationSettings(themeData, colorScheme),

                  const SizedBox(height: 24),

                  // Advanced Controls
                  _buildAdvancedControls(themeData, colorScheme),

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(themeData, colorScheme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
                      'Grade ${_userGrade?.name.replaceAll('grade', '') ?? '5'} • ${_currentUser?.role.name.toUpperCase() ?? 'STUDENT'}',
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
            'Traditional multiple-choice questions',
            Icons.quiz,
            Colors.blue,
            themeData,
            colorScheme,
            _buildClassicQuizSettings(),
          ),

          const SizedBox(height: 16),

          // AI-Native Quiz Configuration
          _buildGameModeCard(
            'AI-Native Quiz',
            'Adaptive AI-powered questions',
            Icons.psychology,
            Colors.green,
            themeData,
            colorScheme,
            _buildAINativeSettings(),
          ),

          const SizedBox(height: 16),

          // ChatGPT Enhanced Configuration
          _buildGameModeCard(
            'ChatGPT Enhanced',
            'Real AI tutoring with ChatGPT',
            Icons.auto_awesome,
            Colors.purple,
            themeData,
            colorScheme,
            _buildChatGPTSettings(),
          ),
        ],
      ),
    );
  }

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

  Widget _buildClassicQuizSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grade-aware difficulty
        _buildGradeAwareDifficulty(),
        const SizedBox(height: 16),

        // Topic selection based on mastery
        _buildMasteryBasedTopics(),
        const SizedBox(height: 16),

        // Question count with performance adjustment
        _buildAdaptiveQuestionCount(),
        const SizedBox(height: 16),

        // Time limits based on user performance
        _buildPerformanceBasedTiming(),
      ],
    );
  }

  Widget _buildAINativeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // AI Difficulty Adaptation
        _buildAIAdaptationSettings(),
        const SizedBox(height: 16),

        // Learning Path Configuration
        _buildLearningPathSettings(),
        const SizedBox(height: 16),

        // AI Personality Settings
        _buildAIPersonalitySettings(),
      ],
    );
  }

  Widget _buildChatGPTSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ChatGPT Model Configuration
        _buildChatGPTModelSettings(),
        const SizedBox(height: 16),

        // Tutoring Style
        _buildTutoringStyleSettings(),
        const SizedBox(height: 16),

        // Explanation Depth
        _buildExplanationDepthSettings(),
      ],
    );
  }

  Widget _buildGradeAwareDifficulty() {
    final gradeRecommendations = _getGradeRecommendedDifficulties();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.school, color: Colors.blue, size: 20),
            const SizedBox(width: 8),
            Text(
              'Grade-Aware Difficulty',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        Text(
          'Recommended for Grade ${_userGrade?.name.replaceAll('grade', '')}:',
          style: TextStyle(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.7),
            fontSize: 12,
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
                    Icon(Icons.star, size: 12, color: Colors.amber),
                  ],
                ],
              ),
              selected: isSelected,
              selectedColor: isRecommended
                  ? Colors.amber.withValues(alpha: 0.3)
                  : null,
              backgroundColor: isRecommended
                  ? Colors.amber.withValues(alpha: 0.1)
                  : null,
              side: BorderSide(
                color: isRecommended ? Colors.amber : Colors.grey,
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

  Widget _buildMasteryBasedTopics() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.psychology, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Text(
              'Smart Topic Selection',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (_strugglingTopics.isNotEmpty) ...[
          _buildTopicSection(
            'Focus Areas (Needs Practice)',
            _strugglingTopics,
            Colors.orange,
            Icons.trending_down,
            'These topics need more practice based on your performance',
          ),
          const SizedBox(height: 12),
        ],

        if (_masteredTopics.isNotEmpty) ...[
          _buildTopicSection(
            'Mastered Topics (Challenge Ready)',
            _masteredTopics,
            Colors.green,
            Icons.trending_up,
            'You\'ve mastered these - ready for harder challenges!',
          ),
          const SizedBox(height: 12),
        ],

        _buildTopicSection(
          'All Topics',
          GameCategory.values,
          Colors.blue,
          Icons.category,
          'Select any topics you want to practice',
        ),
      ],
    );
  }

  Widget _buildTopicSection(
    String title,
    List<GameCategory> topics,
    Color color,
    IconData icon,
    String description,
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
              ).colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: topics.map((category) {
              final isSelected = _preferences!.preferredCategory == category;
              final mastery = _topicMastery[category] ?? 0.0;

              return FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getCategoryIcon(category), size: 12),
                    const SizedBox(width: 4),
                    Text(
                      _getCategoryDisplayName(category),
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (mastery > 0) ...[
                      const SizedBox(width: 4),
                      Text(
                        '${mastery.round()}%',
                        style: TextStyle(
                          fontSize: 10,
                          color: _getMasteryColor(mastery),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                selected: isSelected,
                selectedColor: color.withValues(alpha: 0.2),
                backgroundColor: color.withValues(alpha: 0.05),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _preferences = _preferences!.copyWith(
                        preferredCategory: category,
                      );
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAdaptiveLearningSettings(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return _buildAdvancedCard(
      'Adaptive Learning Engine',
      'AI-powered personalization based on your performance',
      Icons.auto_awesome,
      Colors.purple,
      Column(
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
                _preferences = _preferences!.copyWith(
                  smartTopicRotation: value,
                );
              });
            },
          ),

          SwitchListTile(
            title: const Text('Spaced Repetition'),
            subtitle: const Text('Review topics at optimal intervals'),
            value: _preferences?.spacedRepetition ?? false,
            onChanged: (value) {
              setState(() {
                _preferences = _preferences!.copyWith(spacedRepetition: value);
              });
            },
          ),

          const SizedBox(height: 16),

          // Learning Intensity Slider
          Text(
            'Learning Intensity: ${(_preferences?.learningIntensity ?? 0.5).toStringAsFixed(1)}',
            style: themeData.typography.titleSmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
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
        ],
      ),
    );
  }

  Widget _buildPerformanceRecommendations(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    if (_analytics == null) return const SizedBox.shrink();

    return _buildAdvancedCard(
      'AI Recommendations',
      'Personalized suggestions based on your performance',
      Icons.lightbulb,
      Colors.amber,
      Column(
        children: [
          if (_strugglingTopics.isNotEmpty) ...[
            _buildRecommendationSection(
              'Focus Areas',
              'Practice these topics to improve overall performance',
              Icons.track_changes,
              Colors.orange,
              _strugglingTopics
                  .map(
                    (topic) =>
                        'Practice ${_getCategoryDisplayName(topic)} - Current: ${_topicMastery[topic]?.round() ?? 0}%',
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          if (_masteredTopics.isNotEmpty) ...[
            _buildRecommendationSection(
              'Challenge Opportunities',
              'You\'ve mastered these - try harder difficulty!',
              Icons.emoji_events,
              Colors.green,
              _masteredTopics
                  .map(
                    (topic) =>
                        'Increase ${_getCategoryDisplayName(topic)} difficulty - Mastery: ${_topicMastery[topic]?.round() ?? 0}%',
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],

          // Next recommended session
          _buildNextSessionRecommendation(themeData, colorScheme),
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
                          color: Theme.of(context).colorScheme.onSurface,
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

  // Helper methods for context awareness
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

  String _getCategoryDisplayName(GameCategory category) {
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

  IconData _getCategoryIcon(GameCategory category) {
    switch (category) {
      case GameCategory.addition:
        return Icons.add;
      case GameCategory.subtraction:
        return Icons.remove;
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

  Color _getMasteryColor(double mastery) {
    if (mastery >= 80) return Colors.green;
    if (mastery >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getLearningIntensityLabel(double intensity) {
    if (intensity <= 0.3) return 'Relaxed';
    if (intensity <= 0.5) return 'Balanced';
    if (intensity <= 0.7) return 'Focused';
    return 'Intensive';
  }

  // Placeholder methods for advanced features
  Widget _buildAdaptiveQuestionCount() =>
      const Text('Adaptive Question Count - Coming Soon');
  Widget _buildPerformanceBasedTiming() =>
      const Text('Performance-Based Timing - Coming Soon');
  Widget _buildAIAdaptationSettings() =>
      const Text('AI Adaptation Settings - Coming Soon');
  Widget _buildLearningPathSettings() =>
      const Text('Learning Path Settings - Coming Soon');
  Widget _buildAIPersonalitySettings() =>
      const Text('AI Personality Settings - Coming Soon');
  Widget _buildChatGPTModelSettings() =>
      const Text('ChatGPT Model Settings - Coming Soon');
  Widget _buildTutoringStyleSettings() =>
      const Text('Tutoring Style Settings - Coming Soon');
  Widget _buildExplanationDepthSettings() =>
      const Text('Explanation Depth Settings - Coming Soon');
  Widget _buildPersonalizationSettings(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) => const Text('Personalization Settings - Coming Soon');
  Widget _buildAdvancedControls(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) => const Text('Advanced Controls - Coming Soon');
  Widget _buildRecommendationSection(
    String title,
    String description,
    IconData icon,
    Color color,
    List<String> items,
  ) => const Text('Recommendations - Coming Soon');
  Widget _buildNextSessionRecommendation(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) => const Text('Next Session - Coming Soon');
  Widget _buildActionButtons(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) => const Text('Action Buttons - Coming Soon');

  Future<void> _savePreferences() async {
    setState(() => _isSaving = true);
    try {
      final notifier = ref.read(userGamePreferencesNotifierProvider.notifier);
      await notifier.updatePreferences(_preferences!);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Preferences saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving preferences: $e')));
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }
}
