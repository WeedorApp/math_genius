import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Centralized route definitions for the Math Genius app
/// Provides type-safe navigation with parameters
class AppRoutes {
  // Private constructor to prevent instantiation
  AppRoutes._();

  /// Root routes
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String auth = '/auth';
  static const String classSelection = '/class-selection';
  static const String home = '/home';

  /// Game routes
  static const String gameSelection = '/game-selection';
  static const String gameModes = '/game-modes';
  static const String classicQuiz = '/classic-quiz';
  static const String aiNativeQuiz = '/ai-native-quiz';
  static const String chatgptQuiz = '/chatgpt-quiz';
  static const String gameResults = '/game-results';
  static const String gameHistory = '/game-history';
  static const String gameCustomization = '/game-customization';

  /// Learning routes
  static const String aiTutor = '/ai-tutor';
  static const String tutorSession = '/ai-tutor/session';
  static const String learningPath = '/learning-path';
  static const String practiceMode = '/practice-mode';
  static const String lessonPlan = '/lesson-plan';

  /// Student routes
  static const String studentDashboard = '/student';
  static const String studentProfile = '/student/profile';
  static const String studentGames = '/student/games';
  static const String studentProgress = '/student/progress';
  static const String studentAchievements = '/student/achievements';
  static const String studentReports = '/student/reports';

  /// Teacher/Parent routes
  static const String teacherDashboard = '/teacher';
  static const String parentDashboard = '/parent';
  static const String classManagement = '/class-management';
  static const String studentManagement = '/student-management';
  static const String progressReports = '/progress-reports';
  static const String assignments = '/assignments';

  /// Social features
  static const String liveSessions = '/live-sessions';
  static const String sessionRoom = '/live-sessions/room';
  static const String multiplayer = '/multiplayer';
  static const String leaderboard = '/leaderboard';
  static const String challenges = '/challenges';

  /// Rewards & Gamification
  static const String rewards = '/rewards';
  static const String achievements = '/achievements';
  static const String badges = '/badges';
  static const String streaks = '/streaks';
  static const String shop = '/shop';

  /// Settings & Configuration
  static const String settings = '/settings';
  static const String chatgptSettings = '/settings/chatgpt';
  static const String profileSettings = '/settings/profile';
  static const String notificationSettings = '/settings/notifications';
  static const String privacySettings = '/settings/privacy';
  static const String parentalControls = '/settings/parental-controls';
  static const String subscriptionSettings = '/settings/subscription';

  /// Help & Support
  static const String help = '/help';
  static const String tutorials = '/tutorials';
  static const String faq = '/faq';
  static const String feedback = '/feedback';
  static const String support = '/support';

  /// Admin routes (for school administrators)
  static const String adminDashboard = '/admin';
  static const String schoolManagement = '/admin/school';
  static const String userManagement = '/admin/users';
  static const String analyticsReports = '/admin/analytics';
  static const String contentManagement = '/admin/content';

  /// Navigation helpers
  static void goToHome(BuildContext context) => context.go(home);
  static void goToGameSelection(BuildContext context) =>
      context.go(gameSelection);
  static void goToGameModes(BuildContext context) => context.go(gameModes);
  static void goToAITutor(BuildContext context) => context.go(aiTutor);
  static void goToStudentDashboard(BuildContext context) =>
      context.go(studentDashboard);
  static void goToSettings(BuildContext context) => context.go(settings);

  /// Navigation with parameters
  static void goToTutorSession(BuildContext context, String sessionId) {
    context.go('$tutorSession?sessionId=$sessionId');
  }

  static void goToGameResults(BuildContext context, String sessionId) {
    context.go('$gameResults?sessionId=$sessionId');
  }

  static void goToSessionRoom(BuildContext context, String roomId) {
    context.go('$sessionRoom?roomId=$roomId');
  }

  /// Back navigation helpers
  static void goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(home);
    }
  }

  /// Replace navigation (for auth flows)
  static void replaceWithHome(BuildContext context) =>
      context.pushReplacement(home);
  static void replaceWithAuth(BuildContext context) =>
      context.pushReplacement(auth);
}

/// Route parameters helper class
class RouteParams {
  // Private constructor
  RouteParams._();

  /// Extract route parameters safely
  static String? getParam(GoRouterState state, String key) {
    return state.uri.queryParameters[key];
  }

  static Map<String, String> getAllParams(GoRouterState state) {
    return state.uri.queryParameters;
  }

  /// Path parameters
  static String? getPathParam(GoRouterState state, String key) {
    return state.pathParameters[key];
  }

  /// Extra data (for complex objects)
  static T? getExtra<T>(GoRouterState state) {
    return state.extra as T?;
  }
}

/// Route guards for authentication and authorization
class RouteGuards {
  // Private constructor
  RouteGuards._();

  /// Check if user is authenticated
  static bool isAuthenticated() {
    // TODO: Implement actual authentication check
    return true; // Placeholder
  }

  /// Check if user has required role
  static bool hasRole(String requiredRole) {
    // TODO: Implement role-based access control
    return true; // Placeholder
  }

  /// Check if user can access admin features
  static bool isAdmin() {
    return hasRole('admin');
  }

  /// Check if user is a teacher
  static bool isTeacher() {
    return hasRole('teacher');
  }

  /// Check if user is a parent
  static bool isParent() {
    return hasRole('parent');
  }

  /// Check if user is a student
  static bool isStudent() {
    return hasRole('student');
  }
}
