import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/barrel.dart';

/// Responsive game selection screen
class ResponsiveGameSelectionScreen extends ConsumerWidget {
  const ResponsiveGameSelectionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenType = ref.watch(screenTypeProvider);
    final layoutService = ref.watch(responsiveLayoutServiceProvider);
    final isSidebarCollapsed = ref.watch(sidebarCollapsedProvider);

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
      child: _buildGameSelectionContent(
        context,
        ref,
        screenType,
        layoutService,
        isSidebarCollapsed,
      ),
    );
  }

  Widget _buildGameSelectionContent(
    BuildContext context,
    WidgetRef ref,
    ScreenType screenType,
    ResponsiveLayoutService layoutService,
    bool isSidebarCollapsed,
  ) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final cardElevation = layoutService.getCardElevation(screenType);
    final borderRadius = layoutService.getBorderRadius(screenType);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(
            context,
            ref,
            colorScheme,
            themeData,
            borderRadius,
            isSidebarCollapsed,
          ),
          SizedBox(
            height: layoutService.getNavigationItemSpacing(screenType) * 2,
          ),

          // Game options
          _buildGameOptions(
            context,
            ref,
            colorScheme,
            themeData,
            cardElevation,
            borderRadius,
            isSidebarCollapsed,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
    double borderRadius,
    bool isSidebarCollapsed,
  ) {
    return Card(
      elevation: 0,
      color: colorScheme.primaryContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
              child: Icon(Icons.games, color: colorScheme.onPrimary, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Choose Your Game',
                    style: themeData.typography.headlineSmall.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Select a game mode to start learning',
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onPrimaryContainer.withValues(
                        alpha: 0.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!isSidebarCollapsed) ...[
              const SizedBox(width: 16),
              IconButton(
                icon: Icon(
                  Icons.info_outline,
                  color: colorScheme.onPrimaryContainer,
                ),
                onPressed: () {
                  // Show game info
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGameOptions(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
    double cardElevation,
    double borderRadius,
    bool isSidebarCollapsed,
  ) {
    final games = [
      {
        'title': 'Classic Quiz',
        'description': 'Traditional multiple choice questions',
        'icon': Icons.quiz,
        'color': colorScheme.primary,
        'route': '/classic-quiz',
      },
      {
        'title': 'AI Native Quiz',
        'description': 'AI-powered adaptive questions',
        'icon': Icons.smart_toy,
        'color': colorScheme.secondary,
        'route': '/ai-native-quiz',
      },
      {
        'title': 'ChatGPT Enhanced',
        'description': 'Advanced AI with detailed explanations',
        'icon': Icons.psychology,
        'color': colorScheme.tertiary,
        'route': '/chatgpt-enhanced-quiz',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Available Games',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        if (isSidebarCollapsed) ...[
          // Compact grid for collapsed sidebar
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildCompactGameCard(
                context,
                game,
                colorScheme,
                themeData,
                cardElevation,
                borderRadius,
              );
            },
          ),
        ] else ...[
          // Full list for expanded sidebar
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: games.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              final game = games[index];
              return _buildFullGameCard(
                context,
                game,
                colorScheme,
                themeData,
                cardElevation,
                borderRadius,
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildCompactGameCard(
    BuildContext context,
    Map<String, dynamic> game,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
    double cardElevation,
    double borderRadius,
  ) {
    return Card(
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: () => context.go(game['route'] as String),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (game['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Icon(
                  game['icon'] as IconData,
                  color: game['color'] as Color,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                game['title'] as String,
                style: themeData.typography.titleSmall.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFullGameCard(
    BuildContext context,
    Map<String, dynamic> game,
    ColorScheme colorScheme,
    MathGeniusThemeData themeData,
    double cardElevation,
    double borderRadius,
  ) {
    return Card(
      elevation: cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: InkWell(
        onTap: () => context.go(game['route'] as String),
        borderRadius: BorderRadius.circular(borderRadius),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (game['color'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
                child: Icon(
                  game['icon'] as IconData,
                  color: game['color'] as Color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game['title'] as String,
                      style: themeData.typography.titleLarge.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game['description'] as String,
                      style: themeData.typography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
