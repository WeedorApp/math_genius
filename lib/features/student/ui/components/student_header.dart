import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../../core/barrel.dart';
import '../../../../core/theme/design_system.dart';

/// Student Header Component
/// Displays personalized greeting, streak counter, and profile avatar
class StudentHeader extends ConsumerWidget {
  const StudentHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenType = ref.watch(screenTypeProvider);

    return Container(
      width: double.infinity,
      padding: DesignSystem.padding16,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: _buildHeaderContent(themeData, colorScheme, screenType),
    );
  }

  Widget _buildHeaderContent(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
    ScreenType screenType,
  ) {
    switch (screenType) {
      case ScreenType.desktop:
      case ScreenType.largeDesktop:
        return _buildDesktopHeader(themeData, colorScheme);
      case ScreenType.tablet:
        return _buildTabletHeader(themeData, colorScheme);
      case ScreenType.mobile:
        return _buildMobileHeader(themeData, colorScheme);
    }
  }

  Widget _buildDesktopHeader(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - App Logo and Title
        Row(
          children: [
            Icon(
              Icons.school,
              color: colorScheme.primary,
              size: DesignSystem.iconSize32,
            ),
            const SizedBox(width: 12),
            Text(
              'Math Genius',
              style: themeData.typography.headlineMedium.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        // Center - Personalized Greeting
        Expanded(
          child: Center(
            child: Text(
              '👋 Good morning, Student!',
              style: themeData.typography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Right side - Streak and Profile
        Row(
          children: [
            _buildStreakCounter(themeData, colorScheme),
            const SizedBox(width: 16),
            _buildProfileAvatar(colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletHeader(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - App Logo
        Icon(
          Icons.school,
          color: colorScheme.primary,
          size: DesignSystem.iconSize24,
        ),
        // Center - Greeting
        Expanded(
          child: Center(
            child: Text(
              '👋 Good morning, Student!',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Right side - Streak and Profile
        Row(
          children: [
            _buildStreakCounter(themeData, colorScheme),
            const SizedBox(width: 12),
            _buildProfileAvatar(colorScheme),
          ],
        ),
      ],
    );
  }

  Widget _buildMobileHeader(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - App Logo
        Icon(
          Icons.school,
          color: colorScheme.primary,
          size: DesignSystem.iconSize20,
        ),
        // Center - Greeting
        Expanded(
          child: Center(
            child: Text(
              '👋 Good morning!',
              style: themeData.typography.titleSmall.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        // Right side - Streak
        _buildStreakCounter(themeData, colorScheme),
      ],
    );
  }

  Widget _buildStreakCounter(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department,
            color: colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '7-day streak',
            style: themeData.typography.bodySmall.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar(ColorScheme colorScheme) {
    return CircleAvatar(
      radius: 16,
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        size: 20,
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
