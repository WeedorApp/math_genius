import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'firebase_options.dart';
import 'package:http/http.dart' as http;

// Core modules
import 'core/barrel.dart';
import 'core/theme/design_system.dart';

// Feature imports
import 'features/user_management/barrel.dart' as user_management;
import 'features/game/barrel.dart' as game;
import 'features/home/barrel.dart' as home;
import 'features/student/barrel.dart' as student;

import 'features/ai_tutor_agent/barrel.dart';

// ChatGPT Configuration
import 'core/ai/chatgpt_config.dart';
import 'core/ai/chatgpt_service.dart';

// Settings - using barrel import
import 'features/settings/barrel.dart';

// Router configuration
final _routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const user_management.WelcomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const user_management.AuthScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),

      GoRoute(
        path: '/class-selection',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          Widget child;
          if (extra != null) {
            child = user_management.ClassSelectionScreen(
              userRole: extra['userRole'] as user_management.UserRole,
              email: extra['email'] as String,
              password: extra['password'] as String,
              displayName: extra['displayName'] as String,
            );
          } else {
            child = const user_management.AuthScreen();
          }

          return CustomTransitionPage(
            key: state.pageKey,
            child: child,
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0.02, 0.0),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: animation,
                              curve: Curves.easeInOut,
                            ),
                          ),
                      child: child,
                    ),
                  );
                },
            transitionDuration: const Duration(milliseconds: 300),
          );
        },
      ),
      GoRoute(
        path: '/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const home.ResponsiveHomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/game-selection',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const game.ResponsiveGameSelectionScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/classic-quiz',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const game.ClassicQuizScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/ai-native-quiz',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const game.AINativeGameScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),

      GoRoute(
        path: '/chatgpt-enhanced-quiz',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const game.ChatGPTEnhancedGameScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/chatgpt-settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const ChatGPTSettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/ai-tutor',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlaceholderScreen('AI Tutor'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/family',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlaceholderScreen('Family System'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/live-session',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlaceholderScreen('Live Sessions'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/rewards',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PlaceholderScreen('Rewards'),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      // Student UI Routes
      GoRoute(
        path: '/student/home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const student.StudentHomeScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: '/student/games',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const student.StudentGamesScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),

      GoRoute(
        path: '/student/profile',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const student.StudentProfileScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position:
                    Tween<Offset>(
                      begin: const Offset(0.02, 0.0),
                      end: Offset.zero,
                    ).animate(
                      CurvedAnimation(
                        parent: animation,
                        curve: Curves.easeInOut,
                      ),
                    ),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
    ],
  );
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    print('Starting Math Genius app initialization...');
  }

  try {
    if (kDebugMode) {
      print('Initializing Firebase...');
    }
    // Initialize Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    if (kDebugMode) {
      print('Firebase initialized successfully');
    }

    if (kDebugMode) {
      print('Initializing Firebase Service...');
    }
    await FirebaseService.initialize();
    if (kDebugMode) {
      print('Firebase Service initialized successfully');
    }

    // Log Firebase service type for debugging
    if (kDebugMode) {
      print('Firebase Service: FirebaseService class available');
    }

    // Log Firestore service availability
    if (kDebugMode) {
      print('Firestore Service: FirestoreService class available');
    }

    if (kDebugMode) {
      print('Initializing Hive...');
    }
    // Initialize Hive
    await Hive.initFlutter();
    if (kDebugMode) {
      print('Hive initialized successfully');
    }

    if (kDebugMode) {
      print('Initializing SharedPreferences...');
    }
    // Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    if (kDebugMode) {
      print('SharedPreferences initialized successfully');
    }

    // Initialize DeviceInfoPlugin
    final deviceInfo = DeviceInfoPlugin();

    // Initialize Hive box for privacy service with error handling
    Box? hiveBox;
    try {
      hiveBox = await Hive.openBox('privacy_data');
    } catch (e) {
      // If Hive box is locked, try to close and reopen
      try {
        await Hive.close();
        hiveBox = await Hive.openBox('privacy_data');
      } catch (e2) {
        // If still fails, create a new box with a unique name
        hiveBox = await Hive.openBox(
          'privacy_data_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
    }

    // Initialize AI Service (commented out for web compatibility)
    // await AIService.instance.initialize();

    // Log AI service availability
    if (kDebugMode) {
      print('AI Service: AIService class available');
    }

    if (kDebugMode) {
      print('All services initialized successfully');
    }

    runApp(
      ProviderScope(
        overrides: [
          // Override core service providers with initialized instances
          contextServiceProvider.overrideWithValue(
            ContextService(prefs, deviceInfo),
          ),
          platformServiceProvider.overrideWithValue(PlatformService()),
          responsiveLayoutServiceProvider.overrideWithValue(
            ResponsiveLayoutService(),
          ),
          themeServiceProvider.overrideWithValue(ThemeService(prefs)),
          languageServiceProvider.overrideWithValue(LanguageService(prefs)),
          privacyServiceProvider.overrideWithValue(
            PrivacyService(prefs, hiveBox),
          ),
          user_management.userManagementServiceProvider.overrideWithValue(
            user_management.UserManagementService(prefs, hiveBox),
          ),
          deviceLockServiceProvider.overrideWithValue(DeviceLockService(prefs)),
          analyticsServiceProvider.overrideWithValue(AnalyticsService(prefs)),
          sharingServiceProvider.overrideWithValue(SharingService(prefs)),
          notificationsServiceProvider.overrideWithValue(
            NotificationsService(prefs),
          ),
          reportExportServiceProvider.overrideWithValue(
            ReportExportService(prefs),
          ),
          // Feature service providers
          aiTutorServiceProvider.overrideWithValue(
            AITutorService(prefs, hiveBox),
          ),
          // Game service provider
          game.gameServiceProvider.overrideWithValue(
            game.GameService(prefs, hiveBox),
          ),
          // AI Native Game service provider
          game.aiNativeGameServiceProvider.overrideWithValue(
            game.AINativeGameService(
              prefs,
              ChatGPTService('demo_key', http.Client(), ChatGPTConfig(prefs)),
            ),
          ),
          // Class Management service provider
          user_management.classManagementServiceProvider.overrideWithValue(
            user_management.ClassManagementService(prefs),
          ),
          // Override SharedPreferences provider
          sharedPreferencesProvider.overrideWithValue(prefs),

          // Override ChatGPT configuration provider
          chatGPTConfigProvider.overrideWithValue(ChatGPTConfig(prefs)),
        ],
        child: const MathGeniusApp(),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing app: $e');
    }
    // Run app with error handling
    runApp(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to initialize app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Error: $e',
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MathGeniusApp extends ConsumerStatefulWidget {
  const MathGeniusApp({super.key});

  @override
  ConsumerState<MathGeniusApp> createState() => _MathGeniusAppState();
}

class _MathGeniusAppState extends ConsumerState<MathGeniusApp> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize context service
      final contextService = ref.read(contextServiceProvider);
      await contextService.initialize();

      // Log app start
      await FirebaseService.logEvent(
        name: 'app_start',
        parameters: {'timestamp': DateTime.now().toIso8601String()},
      );

      if (kDebugMode) {
        print('App initialization completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during app initialization: $e');
      }
      // Log error to console
      if (kDebugMode) {
        print('App initialization error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final router = ref.watch(_routerProvider);

    return MaterialApp.router(
      title: 'Math Genius',
      theme: ThemeData(colorScheme: colorScheme, useMaterial3: true),
      routerConfig: router,
    );
  }
}

// Splash Screen
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      if (kDebugMode) {
        print('SplashScreen: Checking authentication status...');
      }

      // Check if user is authenticated
      final userService = ref.read(
        user_management.userManagementServiceProvider,
      );
      final currentUser = await userService.getCurrentUser();

      if (kDebugMode) {
        print(
          'SplashScreen: Current user: ${currentUser?.displayName ?? 'None'}',
        );
      }

      // Add a small delay for splash screen effect
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        if (currentUser != null) {
          if (kDebugMode) {
            print('SplashScreen: User authenticated, navigating to home');
          }
          context.go('/home');
        } else {
          if (kDebugMode) {
            print('SplashScreen: No user found, navigating to auth');
          }
          context.go('/auth');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('SplashScreen: Error checking auth: $e');
      }
      if (mounted) {
        context.go('/auth');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.school, size: 120, color: colorScheme.primary),
            const SizedBox(height: 32),
            Text(
              'Math Genius',
              style: themeData.typography.headlineLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Quantum Learning System',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 48),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}

// Home Screen
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Math Genius',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.onSurface),
            onPressed: () => context.go('/settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: DesignSystem.padding16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            Card(
              color: colorScheme.surface,
              elevation: 4,
              child: Padding(
                padding: DesignSystem.padding20,
                child: Column(
                  children: [
                    Icon(Icons.school, size: 64, color: colorScheme.primary),
                    const SizedBox(height: 16),
                    Text(
                      'Welcome to Math Genius',
                      style: themeData.typography.headlineSmall.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Your quantum learning journey starts here',
                      style: themeData.typography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Features Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildFeatureCard(
                  context,
                  ref,
                  'Game',
                  Icons.games,
                  colorScheme.primary,
                  () => context.go('/game'),
                ),
                _buildFeatureCard(
                  context,
                  ref,
                  'AI Tutor',
                  Icons.smart_toy,
                  colorScheme.secondary,
                  () => context.go('/ai-tutor'),
                ),
                _buildFeatureCard(
                  context,
                  ref,
                  'Family',
                  Icons.family_restroom,
                  colorScheme.tertiary,
                  () => context.go('/family'),
                ),
                _buildFeatureCard(
                  context,
                  ref,
                  'Live Sessions',
                  Icons.video_call,
                  colorScheme.error,
                  () => context.go('/live-session'),
                ),
                _buildFeatureCard(
                  context,
                  ref,
                  'Rewards',
                  Icons.star,
                  colorScheme.primary,
                  () => context.go('/rewards'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    WidgetRef ref,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Card(
      color: colorScheme.surface,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: DesignSystem.padding16,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: themeData.typography.titleMedium.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Settings Screen
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final currentLocale = ref.watch(currentLocaleProvider);
    final privacySettings = ref.watch(privacySettingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: SingleChildScrollView(
        padding: DesignSystem.padding16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Theme Settings
            _buildSectionTitle(context, ref, 'Appearance'),
            const SizedBox(height: 16),
            _buildThemeSettings(context, ref),
            const SizedBox(height: 24),

            // Language Settings
            _buildSectionTitle(context, ref, 'Language'),
            const SizedBox(height: 16),
            _buildLanguageSettings(context, ref, currentLocale),
            const SizedBox(height: 24),

            // Privacy Settings
            _buildSectionTitle(context, ref, 'Privacy & Data'),
            const SizedBox(height: 16),
            _buildPrivacySettings(context, ref, privacySettings),
            const SizedBox(height: 24),

            // Notification Settings
            _buildSectionTitle(context, ref, 'Notifications'),
            const SizedBox(height: 16),
            _buildNotificationSettings(context, ref),
            const SizedBox(height: 24),

            // Analytics Settings
            _buildSectionTitle(context, ref, 'Analytics'),
            const SizedBox(height: 16),
            _buildAnalyticsSettings(context, ref),
            const SizedBox(height: 24),

            // Support
            _buildSectionTitle(context, ref, 'Support'),
            const SizedBox(height: 16),
            _buildSupportSettings(context, ref),
            const SizedBox(height: 24),

            // Account Actions
            _buildSectionTitle(context, ref, 'Account Actions'),
            const SizedBox(height: 16),
            _buildAccountActions(context, ref),
            const SizedBox(height: 24),

            // App Info
            _buildAppInfo(context, ref),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, WidgetRef ref, String title) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Text(
      title,
      style: themeData.typography.titleLarge.copyWith(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildThemeSettings(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();
    final currentTheme = ref.watch(themeModeProvider);

    return Card(
      color: colorScheme.surface,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.palette, color: colorScheme.primary),
            title: Text(
              'Theme',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Choose your preferred theme',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: DropdownButton<ThemeMode>(
              value: currentTheme,
              onChanged: (ThemeMode? newTheme) {
                if (newTheme != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(newTheme);
                }
              },
              items: ThemeMode.values.map((ThemeMode theme) {
                return DropdownMenuItem<ThemeMode>(
                  value: theme,
                  child: Text(
                    _getThemeDisplayName(theme),
                    style: themeData.typography.bodyMedium.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  String _getThemeDisplayName(ThemeMode theme) {
    switch (theme) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.childFriendly:
        return 'Fun Kid';
      case ThemeMode.girlMode:
        return 'Girl Magic';
      case ThemeMode.proMode:
        return 'Genius Pro';
    }
  }

  Widget _buildLanguageSettings(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    final languages = [
      {'code': 'en', 'name': 'English', 'flag': '🇺🇸'},
      {'code': 'fr', 'name': 'Français', 'flag': '🇫🇷'},
      {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
      {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    ];

    return Card(
      color: colorScheme.surface,
      child: Column(
        children: languages.map((language) {
          final isSelected = currentLocale.languageCode == language['code'];
          return ListTile(
            leading: Text(
              language['flag']!,
              style: const TextStyle(fontSize: 24),
            ),
            title: Text(
              language['name']!,
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            trailing: isSelected
                ? Icon(Icons.check, color: colorScheme.primary)
                : null,
            onTap: () {
              ref
                  .read(currentLocaleProvider.notifier)
                  .setLocale(Locale(language['code']!));
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPrivacySettings(
    BuildContext context,
    WidgetRef ref,
    PrivacySettings privacySettings,
  ) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Card(
      color: colorScheme.surface,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.analytics, color: colorScheme.primary),
            title: Text(
              'Analytics',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Allow analytics collection',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: privacySettings.allowAnalytics,
            onChanged: (bool value) {
              ref
                  .read(privacySettingsProvider.notifier)
                  .updateSettings(
                    privacySettings.copyWith(allowAnalytics: value),
                  );
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.share, color: colorScheme.primary),
            title: Text(
              'Data Sharing',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Allow data sharing for research',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: privacySettings.allowDataSharing,
            onChanged: (bool value) {
              ref
                  .read(privacySettingsProvider.notifier)
                  .updateSettings(
                    privacySettings.copyWith(allowDataSharing: value),
                  );
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.wifi_off, color: colorScheme.primary),
            title: Text(
              'Offline Mode',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Use app without internet',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: privacySettings.isOfflineMode,
            onChanged: (bool value) {
              ref.read(privacySettingsProvider.notifier).setOfflineMode(value);
            },
          ),
          ListTile(
            leading: Icon(Icons.security, color: colorScheme.primary),
            title: Text(
              'Privacy Policy',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'View privacy policy',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // TODO: Navigate to privacy policy
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Card(
      color: colorScheme.surface,
      child: Column(
        children: [
          SwitchListTile(
            secondary: Icon(Icons.notifications, color: colorScheme.primary),
            title: Text(
              'Push Notifications',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Receive push notifications',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: true, // TODO: Get from notification service
            onChanged: (bool value) {
              // TODO: Update notification settings
            },
          ),
          SwitchListTile(
            secondary: Icon(Icons.email, color: colorScheme.primary),
            title: Text(
              'Email Notifications',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Receive email notifications',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            value: false, // TODO: Get from user settings
            onChanged: (bool value) {
              // TODO: Update email notification settings
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsSettings(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Card(
      color: colorScheme.surface,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.analytics, color: colorScheme.primary),
            title: Text(
              'Learning Analytics',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'View your learning progress',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // TODO: Navigate to analytics dashboard
            },
          ),
          ListTile(
            leading: Icon(Icons.download, color: colorScheme.primary),
            title: Text(
              'Export Data',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Export your learning data',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () async {
              try {
                final currentUser = await ref
                    .read(user_management.userManagementServiceProvider)
                    .getCurrentUser();
                if (currentUser != null) {
                  await ref
                      .read(reportExportServiceProvider)
                      .exportUserDataAsJSON(
                        userId: currentUser.id,
                        userData: {'user': currentUser.toJson()},
                      );
                  if (context.mounted) {
                    AdaptiveUISystem.showAdaptiveSnackBar(
                      context: context,
                      message: 'Data exported successfully',
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  AdaptiveUISystem.showAdaptiveSnackBar(
                    context: context,
                    message: 'Failed to export data: $e',
                    isError: true,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSettings(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Card(
      color: colorScheme.surface,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.help, color: colorScheme.primary),
            title: Text(
              'Help & Support',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Get help and support',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              // TODO: Navigate to help screen
            },
          ),
          ListTile(
            leading: Icon(Icons.feedback, color: colorScheme.primary),
            title: Text(
              'Send Feedback',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'Share your feedback with us',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () async {
              try {
                await ref
                    .read(sharingServiceProvider)
                    .createCustomShare(
                      title: 'Math Genius Feedback',
                      description: 'User feedback for Math Genius app',
                      data: {'feedback': 'User feedback'},
                    );
              } catch (e) {
                if (context.mounted) {
                  AdaptiveUISystem.showAdaptiveSnackBar(
                    context: context,
                    message: 'Failed to open feedback: $e',
                    isError: true,
                  );
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.info, color: colorScheme.primary),
            title: Text(
              'About',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            subtitle: Text(
              'App information and version',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: colorScheme.onSurfaceVariant,
            ),
            onTap: () {
              _showAboutDialog(context, ref);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccountActions(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Card(
      color: colorScheme.surface,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.logout, color: colorScheme.error),
            title: Text(
              'Sign Out',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.error,
              ),
            ),
            subtitle: Text(
              'Sign out of your account',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () async {
              final confirmed = await _showConfirmDialog(
                context,
                ref,
                'Sign Out',
                'Are you sure you want to sign out?',
              );
              if (confirmed && context.mounted) {
                try {
                  await FirebaseService.signOut();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AdaptiveUISystem.showAdaptiveSnackBar(
                      context: context,
                      message: 'Failed to sign out: $e',
                      isError: true,
                    );
                  }
                }
              }
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_forever, color: colorScheme.error),
            title: Text(
              'Delete Account',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.error,
              ),
            ),
            subtitle: Text(
              'Permanently delete your account',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            onTap: () async {
              final confirmed = await _showConfirmDialog(
                context,
                ref,
                'Delete Account',
                'Are you sure you want to permanently delete your account? This action cannot be undone.',
              );
              if (confirmed && context.mounted) {
                try {
                  await FirebaseService.deleteAccount();
                  if (context.mounted) {
                    context.go('/auth');
                  }
                } catch (e) {
                  if (context.mounted) {
                    AdaptiveUISystem.showAdaptiveSnackBar(
                      context: context,
                      message: 'Failed to delete account: $e',
                      isError: true,
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppInfo(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Card(
      color: colorScheme.surface,
      child: Padding(
        padding: DesignSystem.padding16,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Info',
              style: themeData.typography.titleMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Math Genius Quantum Learning System',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version 1.0.0',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'SSOT v1.0.0 Compliant',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _showConfirmDialog(
    BuildContext context,
    WidgetRef ref,
    String title,
    String message,
  ) async {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                  ),
                  child: Text('Confirm'),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  void _showAboutDialog(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    AdaptiveUISystem.showAdaptiveDialog(
      context: context,
      child: AlertDialog(
        title: Text('About Math Genius'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Math Genius Quantum Learning System',
              style: themeData.typography.titleMedium.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text('Version 1.0.0'),
            const SizedBox(height: 4),
            Text('SSOT v1.0.0 Compliant'),
            const SizedBox(height: 8),
            Text(
              'A comprehensive math learning system designed for PreK-12 students, parents, and educators with AI-powered tutoring, gamified learning, and multi-platform support.',
              style: themeData.typography.bodySmall.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

// Placeholder Screen for features not yet implemented
class PlaceholderScreen extends ConsumerWidget {
  final String title;

  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final colorScheme = themeData.colorScheme.toColorScheme();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          title,
          style: themeData.typography.headlineSmall.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction, size: 80, color: colorScheme.primary),
            const SizedBox(height: 24),
            Text(
              '$title Coming Soon!',
              style: themeData.typography.headlineMedium.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'This feature is under development.',
              style: themeData.typography.bodyMedium.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Go Back',
                style: themeData.typography.labelLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
