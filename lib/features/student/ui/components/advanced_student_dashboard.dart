import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math' as math;

import '../../../../core/barrel.dart';
import '../../services/student_analytics_service.dart';
import '../../../game/models/game_model.dart';

/// Advanced Student Dashboard with real-time analytics
class AdvancedStudentDashboard extends ConsumerStatefulWidget {
  final String studentId;

  const AdvancedStudentDashboard({super.key, required this.studentId});

  @override
  ConsumerState<AdvancedStudentDashboard> createState() =>
      _AdvancedStudentDashboardState();
}

class _AdvancedStudentDashboardState
    extends ConsumerState<AdvancedStudentDashboard>
    with TickerProviderStateMixin, NativeIntegrationMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _cardAnimation;

  StudentAnalytics? _analytics;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadStudentAnalytics();
    initializeNativeFeatures(); // Initialize native platform features
  }

  void _initializeAnimations() {
    // Use platform-optimized animation durations
    _progressAnimationController = AnimationController(
      duration: getPlatformAnimationDuration(AnimationSpeed.slow),
      vsync: this,
    );

    _cardAnimationController = AnimationController(
      duration: getPlatformAnimationDuration(AnimationSpeed.normal),
      vsync: this,
    );

    // Use platform-specific animation curves
    _progressAnimation = CurvedAnimation(
      parent: _progressAnimationController,
      curve: getPlatformCurve(),
    );

    _cardAnimation = CurvedAnimation(
      parent: _cardAnimationController,
      curve: getPlatformCurve(),
    );
  }

  Future<void> _loadStudentAnalytics() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final analyticsService = ref.read(studentAnalyticsServiceProvider);
      final analytics = await analyticsService.getStudentAnalytics(
        widget.studentId,
      );

      if (mounted) {
        setState(() {
          _analytics = analytics;
          _isLoading = false;
        });

        // Start animations safely with native optimization
        if (mounted) {
          // Optimize animations for current platform
          await optimizeForCurrentPlatform();

          _progressAnimationController.forward();
          _cardAnimationController.forward();

          // Trigger light haptic feedback when dashboard loads
          await triggerLightHaptic();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading analytics: $e';
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    if (_isLoading) {
      return _buildLoadingState(colorScheme);
    }

    if (_errorMessage != null) {
      return _buildErrorState(colorScheme);
    }

    if (_analytics == null) {
      return _buildEmptyState(colorScheme);
    }

    return _buildDashboardContent(themeData, colorScheme);
  }

  Widget _buildLoadingState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use platform-appropriate loading indicator
          getPlatformLoadingIndicator(colorScheme),
          const SizedBox(height: 16),
          Text(
            'Loading your learning analytics...',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Unable to load analytics',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _errorMessage ?? 'Unknown error',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await triggerSelectionHaptic(); // Haptic feedback on button press
              _loadStudentAnalytics();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.school, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Welcome to Math Genius!',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start playing games to see your progress here',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 16),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await triggerSuccessHaptic(); // Success haptic for starting learning
              if (mounted) {
                context.push('/game-selection');
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Start Learning'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        await triggerLightHaptic(); // Haptic feedback on pull-to-refresh
        await _loadStudentAnalytics();
      },
      child: SingleChildScrollView(
        padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Professional Welcome Header with greeting, icon, and streak
            _buildProfessionalHeader(themeData, colorScheme),

            SizedBox(height: context.adaptiveLayout.sectionSpacing),

            // Progress Overview Cards
            _buildProgressOverview(themeData, colorScheme),

            SizedBox(height: context.adaptiveLayout.sectionSpacing),

            // Topic Mastery Visualization
            _buildTopicMasterySection(themeData, colorScheme),

            SizedBox(height: context.adaptiveLayout.sectionSpacing),

            // Recent Activity Timeline
            _buildRecentActivitySection(themeData, colorScheme),

            SizedBox(height: context.adaptiveLayout.sectionSpacing),

            // Study Time Analytics
            _buildStudyTimeSection(themeData, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildProfessionalHeader(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final progress = _analytics!.overallProgress;
    final streak = _analytics!.studyStreak.currentStreak;

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * _cardAnimation.value.clamp(0.0, 1.0)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isCompact = constraints.maxWidth < 400;
              final isMobile = constraints.maxWidth < 600;

              return Container(
                constraints: BoxConstraints(
                  minHeight: isCompact ? 140 : 160,
                  maxHeight: isCompact ? 180 : 200,
                ),
                padding: EdgeInsets.all(
                  isCompact ? 16 : context.adaptiveLayout.contentPadding + 4,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.primaryContainer.withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      blurRadius: isCompact ? 15 : 20,
                      offset: Offset(0, isCompact ? 6 : 8),
                    ),
                  ],
                ),
                child: isMobile && !isCompact
                    ? _buildMobileHeaderLayout(
                        themeData,
                        colorScheme,
                        progress,
                        streak,
                      )
                    : _buildCompactOrDesktopLayout(
                        themeData,
                        colorScheme,
                        progress,
                        streak,
                        isCompact,
                      ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildStudentAvatar(
    ColorScheme colorScheme,
    OverallProgress progress,
    bool isCompact,
  ) {
    final avatarSize = isCompact ? 60.0 : 70.0;
    final iconSize = isCompact ? 30.0 : 35.0;

    return Container(
      width: avatarSize,
      height: avatarSize,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: isCompact ? 10 : 15,
            offset: Offset(0, isCompact ? 3 : 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Icon(
              Icons.person,
              size: iconSize,
              color: colorScheme.onPrimary,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 4 : 6,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: colorScheme.secondary,
                borderRadius: BorderRadius.circular(isCompact ? 8 : 10),
                border: Border.all(color: colorScheme.surface, width: 2),
              ),
              child: Text(
                'L${progress.level}',
                style: TextStyle(
                  color: colorScheme.onSecondary,
                  fontSize: isCompact ? 8 : 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakBadge(
    ColorScheme colorScheme,
    int streak,
    bool isCompact,
  ) {
    return GestureDetector(
      onTap: () async {
        // Haptic feedback when tapping streak badge
        await triggerSuccessHaptic();

        // Show platform-appropriate streak details dialog
        if (mounted) {
          await showPlatformDialog(
            context: context,
            title: 'Learning Streak',
            content:
                'Amazing! You\'ve been learning for $streak consecutive days. Keep up the excellent work!',
            confirmText: 'Thanks!',
          );
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 8 : 12,
          vertical: isCompact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.orange.withValues(alpha: 0.9),
              Colors.deepOrange.withValues(alpha: 0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(isCompact ? 16 : 20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.4),
              blurRadius: isCompact ? 6 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_fire_department,
              size: isCompact ? 16 : 18,
              color: Colors.white,
            ),
            SizedBox(width: isCompact ? 4 : 6),
            Text(
              '${streak}d',
              style: TextStyle(
                color: Colors.white,
                fontSize: isCompact ? 12 : 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextLevelProgress(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    OverallProgress progress,
    bool isCompact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Next Level Progress',
                style: TextStyle(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                  fontSize: isCompact ? 11 : 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${(progress.nextLevelProgress * 100).round()}%',
              style: TextStyle(
                color: colorScheme.onPrimaryContainer,
                fontSize: isCompact ? 11 : 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: isCompact ? 6 : 8),
        AnimatedBuilder(
          animation: _progressAnimation,
          builder: (context, child) {
            return Container(
              height: isCompact ? 6 : 8,
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(isCompact ? 3 : 4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(isCompact ? 3 : 4),
                child: LinearProgressIndicator(
                  value:
                      progress.nextLevelProgress *
                      _progressAnimation.value.clamp(0.0, 1.0),
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    colorScheme.secondary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildProgressOverview(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Progress',
          style: themeData.typography.headlineMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: context.adaptiveLayout.cardSpacing),
        _buildProgressCards(themeData, colorScheme),
      ],
    );
  }

  Widget _buildProgressCards(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;

        if (isWide) {
          return Row(
            children: [
              Expanded(
                child: _buildOverallProgressCard(themeData, colorScheme),
              ),
              SizedBox(width: context.adaptiveLayout.cardSpacing),
              Expanded(child: _buildAccuracyCard(themeData, colorScheme)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildOverallProgressCard(themeData, colorScheme),
              SizedBox(height: context.adaptiveLayout.cardSpacing),
              _buildAccuracyCard(themeData, colorScheme),
            ],
          );
        }
      },
    );
  }

  Widget _buildOverallProgressCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final progress = _analytics!.overallProgress;

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimation.value.clamp(0.0, 1.0))),
          child: Opacity(
            opacity: _cardAnimation.value.clamp(0.0, 1.0),
            child: Container(
              padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.trending_up,
                        color: colorScheme.primary,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Overall Progress',
                        style: themeData.typography.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Circular Progress Indicator
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: CircularProgressPainter(
                            progress:
                                (progress.percentage / 100) *
                                _progressAnimation.value.clamp(0.0, 1.0),
                            backgroundColor:
                                colorScheme.surfaceContainerHighest,
                            progressColor: colorScheme.primary,
                            strokeWidth: 8,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${(progress.percentage * _progressAnimation.value.clamp(0.0, 1.0)).round()}%',
                                  style: themeData.typography.headlineMedium
                                      .copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Mastery',
                                  style: themeData.typography.bodySmall
                                      .copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    '${progress.experiencePoints} XP earned',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAccuracyCard(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final accuracy = _analytics!.overallProgress.percentage;

    return AnimatedBuilder(
      animation: _cardAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _cardAnimation.value.clamp(0.0, 1.0))),
          child: Opacity(
            opacity: _cardAnimation.value.clamp(0.0, 1.0),
            child: Container(
              padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.gps_fixed, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Accuracy',
                        style: themeData.typography.titleMedium.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 1500),
                    tween: Tween(begin: 0.0, end: accuracy),
                    builder: (context, value, child) {
                      return Text(
                        '${value.round()}%',
                        style: themeData.typography.displayMedium.copyWith(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),

                  Text(
                    'Correct Answers',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopicMasterySection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final topicMastery = _analytics!.topicMastery;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Topic Mastery',
          style: themeData.typography.headlineMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: context.adaptiveLayout.cardSpacing),

        Container(
          padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: topicMastery.entries.map((entry) {
              return _buildTopicMasteryBar(
                entry.key,
                entry.value,
                themeData,
                colorScheme,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildTopicMasteryBar(
    GameCategory category,
    double mastery,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _getCategoryDisplayName(category),
                style: themeData.typography.bodyMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${mastery.round()}%',
                style: themeData.typography.bodySmall.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Container(
                height: 8,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value:
                        (mastery / 100) *
                        _progressAnimation.value.clamp(0.0, 1.0),
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      _getMasteryColor(mastery),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitySection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final activities = _analytics!.recentActivity;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: themeData.typography.headlineMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () async {
                await triggerSelectionHaptic(); // Haptic feedback on navigation
                if (mounted) {
                  context.push('/student/progress');
                }
              },
              child: Text(
                'View All',
                style: TextStyle(color: colorScheme.primary),
              ),
            ),
          ],
        ),

        SizedBox(height: context.adaptiveLayout.cardSpacing),

        Container(
          padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: activities.take(5).map((activity) {
              return _buildActivityItem(activity, themeData, colorScheme);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem(
    ActivityItem activity,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: activity.isPositive
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              activity.isPositive ? Icons.check_circle : Icons.school,
              color: activity.isPositive ? Colors.green : Colors.orange,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: themeData.typography.bodyMedium.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  activity.description,
                  style: themeData.typography.bodySmall.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          Text(
            _formatTimeAgo(activity.timestamp),
            style: themeData.typography.bodySmall.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudyTimeSection(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    final timeAnalytics = _analytics!.timeAnalytics;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Study Time',
          style: themeData.typography.headlineMedium.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),

        SizedBox(height: context.adaptiveLayout.cardSpacing),

        Row(
          children: [
            Expanded(
              child: _buildStudyTimeCard(
                'Today',
                timeAnalytics.todayStudyTime,
                Icons.today,
                Colors.blue,
                themeData,
                colorScheme,
              ),
            ),
            SizedBox(width: context.adaptiveLayout.cardSpacing),
            Expanded(
              child: _buildStudyTimeCard(
                'This Week',
                timeAnalytics.weeklyStudyTime,
                Icons.calendar_view_week,
                Colors.purple,
                themeData,
                colorScheme,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStudyTimeCard(
    String title,
    Duration duration,
    IconData icon,
    Color color,
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: EdgeInsets.all(context.adaptiveLayout.contentPadding),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: themeData.typography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 1500),
            tween: IntTween(begin: 0, end: duration.inMinutes),
            builder: (context, value, child) {
              return Text(
                '$value min',
                style: themeData.typography.headlineSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeaderLayout(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    OverallProgress progress,
    int streak,
  ) {
    return Column(
      children: [
        // Top row with greeting and streak
        Row(
          children: [
            Icon(
              _getGreetingIcon(),
              size: 26,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getGreetingMessage(),
                style: themeData.typography.headlineSmall.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStreakBadge(colorScheme, streak, false),
          ],
        ),

        const SizedBox(height: 16),

        // Bottom row with avatar and level info
        Row(
          children: [
            _buildStudentAvatar(colorScheme, progress, false),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level ${progress.level}',
                    style: themeData.typography.titleLarge.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${progress.experiencePoints} XP',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _buildNextLevelProgress(themeData, colorScheme, progress, false),
      ],
    );
  }

  Widget _buildCompactOrDesktopLayout(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    OverallProgress progress,
    int streak,
    bool isCompact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row with greeting, icon, and streak
        Row(
          children: [
            Icon(
              _getGreetingIcon(),
              size: isCompact ? 24 : 28,
              color: colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _getGreetingMessage(),
                style:
                    (isCompact
                            ? themeData.typography.titleLarge
                            : themeData.typography.headlineMedium)
                        .copyWith(
                          color: colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _buildStreakBadge(colorScheme, streak, isCompact),
          ],
        ),

        SizedBox(height: isCompact ? 12 : 16),

        // Student info and progress
        Row(
          children: [
            _buildStudentAvatar(colorScheme, progress, isCompact),
            SizedBox(width: isCompact ? 12 : 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Level ${progress.level}',
                    style:
                        (isCompact
                                ? themeData.typography.titleMedium
                                : themeData.typography.titleLarge)
                            .copyWith(
                              color: colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
                            ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${progress.experiencePoints} XP',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),

        SizedBox(height: isCompact ? 12 : 16),
        _buildNextLevelProgress(themeData, colorScheme, progress, isCompact),
      ],
    );
  }

  // Helper methods
  String _getGreetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning hhhh!';
    } else if (hour < 17) {
      return 'Good afternoon!';
    } else {
      return 'Good evening!';
    }
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return Icons.wb_sunny; // Morning sun
    } else if (hour < 17) {
      return Icons.wb_sunny_outlined; // Afternoon sun
    } else {
      return Icons.nightlight_round; // Evening moon
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
      default:
        return category.name;
    }
  }

  Color _getMasteryColor(double mastery) {
    if (mastery >= 90) return Colors.green;
    if (mastery >= 70) return Colors.blue;
    if (mastery >= 50) return Colors.orange;
    return Colors.red;
  }

  String _formatTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

/// Custom painter for circular progress indicator
class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background circle
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Progress amount
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
