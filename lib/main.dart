import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'firebase_options.dart';

// Core modules
import 'core/barrel.dart';

// Feature imports
import 'features/user_management/barrel.dart' as user_management;
import 'features/user_management/widgets/auth_screen.dart';

import 'features/game/barrel.dart';
import 'features/ai_tutor_agent/barrel.dart';

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
          gameServiceProvider.overrideWithValue(GameService(prefs, hiveBox)),
          aiTutorServiceProvider.overrideWithValue(
            AITutorService(prefs, hiveBox),
          ),
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
    final currentLocale = ref.watch(currentLocaleProvider);

    return MaterialApp.router(
      title: 'Math Genius',
      debugShowCheckedModeBanner: false,
      theme: themeData.toThemeData(),
      locale: currentLocale,
      supportedLocales: const [
        Locale('en'),
        Locale('fr'),
        Locale('es'),
        Locale('ar'),
      ],
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/auth',
            builder: (context, state) => const AuthScreen(),
          ),
          GoRoute(
            path: '/settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          // Game routes
          GoRoute(
            path: '/game',
            builder: (context, state) => const GameScreen(),
          ),
          // AI Tutor routes
          GoRoute(
            path: '/ai-tutor',
            builder: (context, state) => const PlaceholderScreen('AI Tutor'),
          ),
          // Family System routes
          GoRoute(
            path: '/family',
            builder: (context, state) =>
                const PlaceholderScreen('Family Management'),
          ),
          // Live Session routes
          GoRoute(
            path: '/live-session',
            builder: (context, state) =>
                const PlaceholderScreen('Live Sessions'),
          ),
          // Rewards routes
          GoRoute(
            path: '/rewards',
            builder: (context, state) => const PlaceholderScreen('Rewards'),
          ),
        ],
      ),
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
      // Check if user is authenticated
      final currentUser = await ref
          .read(user_management.userManagementServiceProvider)
          .getCurrentUser();

      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        if (currentUser != null) {
          context.go('/home');
        } else {
          context.go('/auth');
        }
      }
    } catch (e) {
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            Card(
              color: colorScheme.surface,
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
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
          padding: const EdgeInsets.all(16),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // General Settings
            Text(
              'General Settings',
              style: themeData.typography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: colorScheme.surface,
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.notifications,
                      color: colorScheme.primary,
                    ),
                    title: Text(
                      'Notifications',
                      style: themeData.typography.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'Manage notification preferences',
                      style: themeData.typography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: Icon(Icons.analytics, color: colorScheme.primary),
                    title: Text(
                      'Analytics',
                      style: themeData.typography.titleMedium.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    subtitle: Text(
                      'View learning analytics',
                      style: themeData.typography.bodyMedium.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support
            Text(
              'Support',
              style: themeData.typography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
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
                    onTap: () {},
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
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Actions
            Text(
              'Account Actions',
              style: themeData.typography.titleLarge.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
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
                    onTap: () => context.go('/login'),
                  ),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever,
                      color: colorScheme.error,
                    ),
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
                    onTap: () {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // App Info
            Card(
              color: colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
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
                  ],
                ),
              ),
            ),
          ],
        ),
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
