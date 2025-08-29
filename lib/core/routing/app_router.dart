import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core imports
import '../barrel.dart';
import 'app_routes.dart';

// Feature imports
import '../../features/user_management/barrel.dart' as user_management;
import '../../features/game/barrel.dart' as game;
import '../../features/home/barrel.dart' as home;
import '../../features/student/barrel.dart' as student;
import '../../features/ai_tutor_agent/barrel.dart' as ai_tutor;
import '../../features/settings/barrel.dart' as settings;
import '../../features/rewards/barrel.dart' as rewards;
import '../../features/live_session/barrel.dart' as live_session;
import '../../features/family_system/barrel.dart' as family;

/// Enhanced router provider with comprehensive routing
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.welcome,
    debugLogDiagnostics: true,
    routes: [
      // Authentication & Onboarding Routes
      GoRoute(
        path: AppRoutes.welcome,
        name: 'welcome',
        pageBuilder: (context, state) =>
            _buildPage(state, const user_management.WelcomeScreen()),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        pageBuilder: (context, state) =>
            _buildPage(state, const user_management.AuthScreen()),
      ),
      GoRoute(
        path: AppRoutes.classSelection,
        name: 'class-selection',
        pageBuilder: (context, state) {
          final extra = RouteParams.getExtra<Map<String, dynamic>>(state);
          if (extra != null) {
            return _buildPage(
              state,
              user_management.ClassSelectionScreen(
                userRole: extra['userRole'] as user_management.UserRole,
                email: extra['email'] as String,
                password: extra['password'] as String,
                displayName: extra['displayName'] as String,
              ),
            );
          }
          return _buildPage(state, const user_management.WelcomeScreen());
        },
      ),

      // Main Dashboard Routes
      GoRoute(
        path: AppRoutes.home,
        name: 'home',
        pageBuilder: (context, state) =>
            _buildPage(state, const home.ResponsiveHomeScreen()),
      ),

      // Game Routes with Enhanced Navigation
      GoRoute(
        path: AppRoutes.gameSelection,
        name: 'game-selection',
        pageBuilder: (context, state) =>
            _buildPage(state, const game.GameSelectionScreen()),
        routes: [
          GoRoute(
            path: 'classic',
            name: 'classic-quiz',
            pageBuilder: (context, state) =>
                _buildPage(state, const game.ClassicQuizScreen()),
          ),
          GoRoute(
            path: 'ai-native',
            name: 'ai-native-quiz',
            pageBuilder: (context, state) =>
                _buildPage(state, const game.AINativeGameScreen()),
          ),
          GoRoute(
            path: 'chatgpt',
            name: 'chatgpt-quiz',
            pageBuilder: (context, state) =>
                _buildPage(state, const game.ChatGPTEnhancedGameScreen()),
          ),
          GoRoute(
            path: 'results',
            name: 'game-results',
            pageBuilder: (context, state) {
              final sessionId = RouteParams.getParam(state, 'sessionId');
              return _buildPage(
                state,
                GameResultsScreen(sessionId: sessionId ?? ''),
              );
            },
          ),
          GoRoute(
            path: 'history',
            name: 'game-history',
            pageBuilder: (context, state) =>
                _buildPage(state, const GameHistoryScreen()),
          ),
        ],
      ),

      // AI Tutor Routes
      GoRoute(
        path: AppRoutes.aiTutor,
        name: 'ai-tutor',
        pageBuilder: (context, state) =>
            _buildPage(state, const AITutorDashboardScreen()),
        routes: [
          GoRoute(
            path: 'session',
            name: 'tutor-session',
            pageBuilder: (context, state) {
              final sessionId =
                  RouteParams.getParam(state, 'sessionId') ?? 'new';
              return _buildPage(
                state,
                ai_tutor.TutorChatWidget(
                  sessionId: sessionId,
                  studentId: 'current-student', // TODO: Get from auth
                  grade: 5, // TODO: Get from user profile
                ),
              );
            },
          ),
        ],
      ),

      // Student Dashboard Routes
      GoRoute(
        path: AppRoutes.studentDashboard,
        name: 'student-dashboard',
        pageBuilder: (context, state) =>
            _buildPage(state, const student.StudentHomeScreen()),
        routes: [
          GoRoute(
            path: 'profile',
            name: 'student-profile',
            pageBuilder: (context, state) =>
                _buildPage(state, const student.StudentProfileScreen()),
          ),
          GoRoute(
            path: 'games',
            name: 'student-games',
            pageBuilder: (context, state) =>
                _buildPage(state, const student.StudentGamesScreen()),
          ),
          GoRoute(
            path: 'progress',
            name: 'student-progress',
            pageBuilder: (context, state) =>
                _buildPage(state, const StudentProgressScreen()),
          ),
          GoRoute(
            path: 'achievements',
            name: 'student-achievements',
            pageBuilder: (context, state) =>
                _buildPage(state, const StudentAchievementsScreen()),
          ),
        ],
      ),

      // Live Session Routes
      GoRoute(
        path: AppRoutes.liveSessions,
        name: 'live-sessions',
        pageBuilder: (context, state) => _buildPage(
          state,
          const live_session.LiveSessionHostingWidget(
            hostId: 'current-user',
            hostName: 'Current User',
          ),
        ),
        routes: [
          GoRoute(
            path: 'room',
            name: 'session-room',
            pageBuilder: (context, state) {
              // Note: roomId could be used for room-specific configuration
              // final roomId = RouteParams.getParam(state, 'roomId') ?? 'default';
              return _buildPage(
                state,
                const live_session.LiveSessionHostingWidget(
                  hostId: 'current-user',
                  hostName: 'Current User',
                ),
              );
            },
          ),
        ],
      ),

      // Rewards & Gamification Routes
      GoRoute(
        path: AppRoutes.rewards,
        name: 'rewards',
        pageBuilder: (context, state) => _buildPage(
          state,
          const rewards.RewardShelfWidget(userId: 'current-user'),
        ),
      ),

      // Settings Routes
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        pageBuilder: (context, state) =>
            _buildPage(state, const SettingsDashboardScreen()),
        routes: [
          GoRoute(
            path: 'chatgpt',
            name: 'chatgpt-settings',
            pageBuilder: (context, state) =>
                _buildPage(state, const settings.ChatGPTSettingsScreen()),
          ),
          GoRoute(
            path: 'profile',
            name: 'profile-settings',
            pageBuilder: (context, state) =>
                _buildPage(state, const ProfileSettingsScreen()),
          ),
          GoRoute(
            path: 'notifications',
            name: 'notification-settings',
            pageBuilder: (context, state) =>
                _buildPage(state, const NotificationSettingsScreen()),
          ),
          GoRoute(
            path: 'privacy',
            name: 'privacy-settings',
            pageBuilder: (context, state) =>
                _buildPage(state, const PrivacySettingsScreen()),
          ),
        ],
      ),

      // Family & Class Management Routes
      GoRoute(
        path: AppRoutes.classManagement,
        name: 'class-management',
        pageBuilder: (context, state) =>
            _buildPage(state, const family.FamilyManagementScreen()),
      ),

      // Help & Support Routes
      GoRoute(
        path: AppRoutes.help,
        name: 'help',
        pageBuilder: (context, state) =>
            _buildPage(state, const HelpCenterScreen()),
        routes: [
          GoRoute(
            path: 'tutorials',
            name: 'tutorials',
            pageBuilder: (context, state) =>
                _buildPage(state, const TutorialsScreen()),
          ),
          GoRoute(
            path: 'faq',
            name: 'faq',
            pageBuilder: (context, state) =>
                _buildPage(state, const FAQScreen()),
          ),
        ],
      ),
    ],
    // Global error handling
    errorPageBuilder: (context, state) =>
        _buildPage(state, ErrorScreen(error: state.error.toString())),
    // Route redirection logic
    redirect: (context, state) {
      // TODO: Implement authentication-based redirects
      return null; // No redirect needed
    },
  );
});

/// Helper function to build pages with consistent transitions
Page<dynamic> _buildPage(GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.02, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}

// Placeholder screens for routes that don't have implementations yet
class GameResultsScreen extends StatelessWidget {
  final String sessionId;

  const GameResultsScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game Results')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.emoji_events, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            Text(
              'Game Results for Session: $sessionId',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => AppRoutes.goToGameSelection(context),
              child: const Text('Play Again'),
            ),
          ],
        ),
      ),
    );
  }
}

class GameHistoryScreen extends StatelessWidget {
  const GameHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game History')),
      body: const Center(child: Text('Game History - Coming Soon!')),
    );
  }
}

class AITutorDashboardScreen extends StatelessWidget {
  const AITutorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI Tutor')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.psychology, size: 64, color: Colors.blue),
            const SizedBox(height: 16),
            const Text('AI Tutor Dashboard'),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => AppRoutes.goToTutorSession(context, 'new'),
              child: const Text('Start New Session'),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentProgressScreen extends StatelessWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Progress')),
      body: const Center(child: Text('Student Progress - Coming Soon!')),
    );
  }
}

class StudentAchievementsScreen extends StatelessWidget {
  const StudentAchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Achievements')),
      body: const Center(child: Text('Student Achievements - Coming Soon!')),
    );
  }
}

class SettingsDashboardScreen extends StatelessWidget {
  const SettingsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.smart_toy),
            title: const Text('ChatGPT Settings'),
            subtitle: const Text('Configure AI assistant'),
            onTap: () => context.push(AppRoutes.chatgptSettings),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile Settings'),
            subtitle: const Text('Manage your profile'),
            onTap: () => context.push(AppRoutes.profileSettings),
          ),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text('Notifications'),
            subtitle: const Text('Notification preferences'),
            onTap: () => context.push(AppRoutes.notificationSettings),
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy'),
            subtitle: const Text('Privacy and security'),
            onTap: () => context.push(AppRoutes.privacySettings),
          ),
        ],
      ),
    );
  }
}

class ProfileSettingsScreen extends StatelessWidget {
  const ProfileSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profile Settings')),
      body: const Center(child: Text('Profile Settings - Coming Soon!')),
    );
  }
}

class NotificationSettingsScreen extends StatelessWidget {
  const NotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: const Center(child: Text('Notification Settings - Coming Soon!')),
    );
  }
}

class PrivacySettingsScreen extends StatelessWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: const Center(child: Text('Privacy Settings - Coming Soon!')),
    );
  }
}

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: const Center(child: Text('Help Center - Coming Soon!')),
    );
  }
}

class TutorialsScreen extends StatelessWidget {
  const TutorialsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tutorials')),
      body: const Center(child: Text('Tutorials - Coming Soon!')),
    );
  }
}

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FAQ')),
      body: const Center(child: Text('FAQ - Coming Soon!')),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('Oops! Something went wrong.'),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => AppRoutes.goToHome(context),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
