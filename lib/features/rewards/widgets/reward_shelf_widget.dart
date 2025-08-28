import 'package:flutter/material.dart' hide Badge;
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../core/barrel.dart';

// Rewards imports
import '../barrel.dart';

/// Reward Shelf Widget - Real-time reward display
class RewardShelfWidget extends ConsumerStatefulWidget {
  final String userId;
  final bool showAnimations;

  const RewardShelfWidget({
    super.key,
    required this.userId,
    this.showAnimations = true,
  });

  @override
  ConsumerState<RewardShelfWidget> createState() => _RewardShelfWidgetState();
}

class _RewardShelfWidgetState extends ConsumerState<RewardShelfWidget>
    with TickerProviderStateMixin {
  late AnimationController _starController;
  late AnimationController _badgeController;
  late AnimationController _messageController;
  late Animation<double> _starAnimation;
  late Animation<double> _badgeAnimation;
  late Animation<double> _messageAnimation;

  @override
  void initState() {
    super.initState();

    _starController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _badgeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _messageController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _starAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _starController, curve: Curves.elasticOut),
    );
    _badgeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.bounceOut),
    );
    _messageAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _messageController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _starController.dispose();
    _badgeController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Card(
      color: colorScheme.surface,
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your Rewards',
              style: themeData.typography.headlineSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Progress Overview
            Consumer(
              builder: (context, ref, child) {
                return FutureBuilder<UserRewardProgress>(
                  future: ref
                      .read(rewardServiceProvider)
                      .getUserProgress(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final progress =
                        snapshot.data ??
                        UserRewardProgress(
                          userId: widget.userId,
                          lastUpdated: DateTime.now(),
                        );

                    return Row(
                      children: [
                        Expanded(
                          child: _buildProgressCard(
                            'Points',
                            progress.totalPoints.toString(),
                            Icons.stars,
                            colorScheme.primary,
                            themeData,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressCard(
                            'Stars',
                            progress.totalStars.toString(),
                            Icons.star,
                            colorScheme.secondary,
                            themeData,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildProgressCard(
                            'Badges',
                            progress.totalBadges.toString(),
                            Icons.emoji_events,
                            colorScheme.tertiary,
                            themeData,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Stars
            Text(
              'Recent Stars',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Consumer(
              builder: (context, ref, child) {
                return FutureBuilder<List<Star>>(
                  future: ref
                      .read(rewardServiceProvider)
                      .getUserStars(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 60,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final stars = snapshot.data ?? [];
                    final recentStars = stars.take(5).toList();

                    if (recentStars.isEmpty) {
                      return Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'No stars yet. Keep learning!',
                            style: themeData.typography.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 60,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentStars.length,
                        itemBuilder: (context, index) {
                          final star = recentStars[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _buildStarWidget(
                              star,
                              colorScheme,
                              themeData,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Badges
            Text(
              'Recent Badges',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Consumer(
              builder: (context, ref, child) {
                return FutureBuilder<List<Badge>>(
                  future: ref
                      .read(rewardServiceProvider)
                      .getUserBadges(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 80,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final badges = snapshot.data ?? [];
                    final recentBadges = badges.take(3).toList();

                    if (recentBadges.isEmpty) {
                      return Container(
                        height: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'No badges yet. Keep earning points!',
                            style: themeData.typography.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }

                    return SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: recentBadges.length,
                        itemBuilder: (context, index) {
                          final badge = recentBadges[index];
                          return Padding(
                            padding: const EdgeInsets.only(right: 12),
                            child: _buildBadgeWidget(
                              badge,
                              colorScheme,
                              themeData,
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 24),

            // Recent Messages
            Text(
              'Recent Messages',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            Consumer(
              builder: (context, ref, child) {
                return FutureBuilder<List<RewardMessage>>(
                  future: ref
                      .read(rewardServiceProvider)
                      .getUserMessages(widget.userId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 100,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final messages = snapshot.data ?? [];
                    final recentMessages = messages.take(3).toList();

                    if (recentMessages.isEmpty) {
                      return Container(
                        height: 100,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            'No messages yet.',
                            style: themeData.typography.bodyMedium.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: recentMessages.map((message) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildMessageWidget(
                            message,
                            colorScheme,
                            themeData,
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard(
    String title,
    String value,
    IconData icon,
    Color color,
    MathGeniusThemeData themeData,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: themeData.typography.titleLarge.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            title,
            style: themeData.typography.bodySmall.copyWith(
              color: color.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarWidget(
    Star star,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return AnimatedBuilder(
      animation: _starAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _starAnimation.value,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: _getStarColor(star.type),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: _getStarColor(star.type).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(Icons.star, color: Colors.white, size: 24),
          ),
        );
      },
    );
  }

  Widget _buildBadgeWidget(
    Badge badge,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return AnimatedBuilder(
      animation: _badgeAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _badgeAnimation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _getBadgeColor(badge.level),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: _getBadgeColor(badge.level).withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(badge.icon ?? '🏆', style: const TextStyle(fontSize: 20)),
                Text(
                  badge.name,
                  style: themeData.typography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageWidget(
    RewardMessage message,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
  ) {
    return AnimatedBuilder(
      animation: _messageAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _messageAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: message.isRead
                    ? colorScheme.outline.withValues(alpha: 0.3)
                    : colorScheme.primary,
                width: message.isRead ? 1 : 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _parseColor(message.color) ?? colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      message.icon ?? '💬',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        message.title,
                        style: themeData.typography.labelLarge.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        message.message,
                        style: themeData.typography.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!message.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStarColor(StarType type) {
    switch (type) {
      case StarType.one:
        return Colors.amber;
      case StarType.two:
        return Colors.orange;
      case StarType.three:
        return Colors.deepOrange;
      case StarType.four:
        return Colors.red;
      case StarType.five:
        return Colors.purple;
    }
  }

  Color _getBadgeColor(AchievementLevel level) {
    switch (level) {
      case AchievementLevel.bronze:
        return const Color(0xFFCD7F32);
      case AchievementLevel.silver:
        return const Color(0xFFC0C0C0);
      case AchievementLevel.gold:
        return const Color(0xFFFFD700);
      case AchievementLevel.platinum:
        return const Color(0xFFE5E4E2);
      case AchievementLevel.diamond:
        return const Color(0xFFB9F2FF);
    }
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    }
    return null;
  }
}

/// Reward Display Widget - For showing individual rewards
class RewardDisplayWidget extends ConsumerStatefulWidget {
  final String userId;
  final bool showAnimations;

  const RewardDisplayWidget({
    super.key,
    required this.userId,
    this.showAnimations = true,
  });

  @override
  ConsumerState<RewardDisplayWidget> createState() =>
      _RewardDisplayWidgetState();
}

class _RewardDisplayWidgetState extends ConsumerState<RewardDisplayWidget>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void showReward(String title, String message, String? icon, String? color) {
    if (widget.showAnimations) {
      _controller.reset();
      _controller.forward();
    }

    AdaptiveUISystem.showAdaptiveDialog(
      context: context,
      child: _RewardDialog(
        title: title,
        message: message,
        icon: icon,
        color: color,
        animationController: _controller,
        scaleAnimation: _scaleAnimation,
        rotationAnimation: _rotationAnimation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink(); // This widget is primarily for showing rewards
  }
}

/// Reward Dialog Widget
class _RewardDialog extends StatelessWidget {
  final String title;
  final String message;
  final String? icon;
  final String? color;
  final AnimationController animationController;
  final Animation<double> scaleAnimation;
  final Animation<double> rotationAnimation;

  const _RewardDialog({
    required this.title,
    required this.message,
    this.icon,
    this.color,
    required this.animationController,
    required this.scaleAnimation,
    required this.rotationAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final colorScheme = themeData.colorScheme;

    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: scaleAnimation.value,
          child: Transform.rotate(
            angle: rotationAnimation.value * 0.1,
            child: AlertDialog(
              backgroundColor: colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _parseColor(color) ?? colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (_parseColor(color) ?? colorScheme.primary)
                              .withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        icon ?? '🎉',
                        style: const TextStyle(fontSize: 32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: themeData.textTheme.headlineSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    style: themeData.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Awesome!'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;
    if (colorString.startsWith('#')) {
      return Color(int.parse(colorString.replaceAll('#', '0xFF')));
    }
    return null;
  }
}
