import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../../core/barrel.dart';
import '../../../../core/theme/design_system.dart';

/// Student Header Component
///
/// A responsive header component that displays:
/// - App logo and branding
/// - Personalized time-aware greeting
/// - Learning streak counter with fire icon
/// - Student profile avatar
///
/// Features:
/// - Responsive design that adapts to mobile, tablet, and desktop
/// - Professional typography and spacing
/// - Consistent branding across all screen sizes
/// - Motivational streak display to encourage daily learning
///
/// Usage:
/// ```dart
/// const StudentHeader()
/// ```
class StudentHeader extends ConsumerWidget {
  const StudentHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch theme and screen type providers for responsive design
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final screenType = ref.watch(screenTypeProvider);

    return Container(
      width: double.infinity,
      padding: DesignSystem.padding16,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        // Subtle bottom border for visual separation
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

  /// Builds responsive header content based on screen type
  ///
  /// Selects the appropriate layout for the current screen size:
  /// - Desktop: Full layout with logo, title, greeting, streak, and avatar
  /// - Tablet: Balanced layout with logo, greeting, streak, and avatar
  /// - Mobile: Compact layout with logo, greeting, and streak only
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

  /// Builds desktop header layout (> 1024px)
  ///
  /// Features:
  /// - Full app logo with "Math Genius" title
  /// - Centered personalized greeting
  /// - Prominent streak counter
  /// - Student profile avatar
  /// - Spacious layout optimized for large screens
  Widget _buildDesktopHeader(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - App Logo and Title
        // Provides brand recognition and app identity
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
              textAlign: TextAlign.center,
              style: themeData.typography.headlineMedium.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 40,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        // Center - Personalized Greeting
        // Creates personal connection with time-aware messaging
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
        // Motivational elements and user identification
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

  /// Builds tablet header layout (768px - 1024px)
  ///
  /// Features:
  /// - App logo without title text (space optimization)
  /// - Centered personalized greeting
  /// - Streak counter for motivation
  /// - Profile avatar for user identification
  /// - Balanced layout for medium screens
  Widget _buildTabletHeader(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - App Logo
        // Compact branding for medium screens
        Icon(
          Icons.school,
          color: colorScheme.primary,
          size: DesignSystem.iconSize24,
        ),

        // Center - Greeting
        // Personalized welcome message
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
        // Essential user elements for tablet interface
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

  /// Builds clean mobile header layout (< 768px)
  ///
  /// Features:
  /// - Simple app branding
  /// - Essential streak counter
  /// - Clean, minimal design
  /// - Optimized for mobile screens
  Widget _buildMobileHeader(
    MathGeniusThemeData themeData,

    ColorScheme colorScheme,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side - App Logo
        Icon(Icons.school, color: colorScheme.primary, size: 28),

        // Center - App Name
        Expanded(
          flex: 4,
          child: Center(
            child: Text(
              'Math Genius',
              textAlign: TextAlign.center,

              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),

        // Right side - Streak Counter
        _buildStreakCounter(themeData, colorScheme),
      ],
    );
  }

  /// Builds the learning streak counter component
  ///
  /// Features:
  /// - Fire icon for visual motivation
  /// - "7-day streak" text display
  /// - Primary color scheme for prominence
  /// - Rounde                                                                                                                                                                                                 container with subtle border
  /// - Consistent padding and typography
  ///
  /// Purpose:
  /// - Motivates students to maintain daily learning habits
  /// - Provides immediate visual feedback on consistency
  /// - Encourages long-term engagement with the app
  Widget _buildStreakCounter(
    MathGeniusThemeData themeData,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        // Primary container background for emphasis
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        // Subtle border for definition
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fire icon for visual motivation
          Icon(
            Icons.local_fire_department,
            color: colorScheme.primary,
            size: 16,
          ),
          const SizedBox(width: 4),
          // Streak text display
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

  /// Builds the student profile avatar component
  ///
  /// Features:
  /// - Circular avatar with consistent sizing
  /// - Primary container background color
  /// - Person icon placeholder (can be replaced with actual photo)
  /// - Proper contrast with onPrimaryContainer color
  ///
  /// Purpose:
  /// - Provides visual user identification
  /// - Creates personal connection with the interface
  /// - Maintains consistent visual hierarchy
  /// - Future-ready for profile photo integration
  Widget _buildProfileAvatar(ColorScheme colorScheme) {
    return CircleAvatar(
      radius: 16,
      // Primary container background for consistency
      backgroundColor: colorScheme.primaryContainer,
      child: Icon(
        Icons.person,
        size: 20,
        // Proper contrast color for accessibility
        color: colorScheme.onPrimaryContainer,
      ),
    );
  }
}
