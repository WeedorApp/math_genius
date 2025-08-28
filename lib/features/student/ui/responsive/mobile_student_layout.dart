import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import '../../../../core/barrel.dart';

// Student UI components
import '../components/student_header.dart';
import '../components/student_dashboard.dart';

/// Mobile Student Layout
/// Bottom navigation with touch-optimized interface
class MobileStudentLayout extends ConsumerStatefulWidget {
  final Widget child;

  const MobileStudentLayout({super.key, required this.child});

  @override
  ConsumerState<MobileStudentLayout> createState() =>
      _MobileStudentLayoutState();
}

class _MobileStudentLayoutState extends ConsumerState<MobileStudentLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: _buildMainContent(colorScheme),
      bottomNavigationBar: _buildBottomNavigation(colorScheme),
    );
  }

  Widget _buildMainContent(ColorScheme colorScheme) {
    return Column(
      children: [
        // Header
        const StudentHeader(),
        // Dashboard Content
        Expanded(child: _buildCurrentPage(colorScheme)),
      ],
    );
  }

  Widget _buildCurrentPage(ColorScheme colorScheme) {
    switch (_currentIndex) {
      case 0:
        return const StudentDashboard();
      case 1:
        return _buildGamesPage(colorScheme);
      case 2:
        return _buildAITutorPage(colorScheme);
      case 3:
        return _buildProgressPage(colorScheme);
      case 4:
        return _buildProfilePage(colorScheme);
      default:
        return const StudentDashboard();
    }
  }

  Widget _buildGamesPage(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.games, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Games',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose your math challenge',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildAITutorPage(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.smart_toy, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'AI Tutor',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get personalized help',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPage(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Progress',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Track your learning journey',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 64, color: colorScheme.primary),
          const SizedBox(height: 16),
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your account',
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(ColorScheme colorScheme) {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: colorScheme.surface,
      selectedItemColor: colorScheme.primary,
      unselectedItemColor: colorScheme.onSurfaceVariant,
      selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
      unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal),
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.games), label: 'Games'),
        BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI Tutor'),
        BottomNavigationBarItem(
          icon: Icon(Icons.trending_up),
          label: 'Progress',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}
