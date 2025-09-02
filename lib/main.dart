import 'package:flutter/material.dart' hide ThemeMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'firebase_options.dart';

// Core modules
import 'core/barrel.dart';

import 'core/ai/chatgpt_config.dart';
import 'features/ai_tutor_agent/services/ai_tutor_service.dart';
import 'features/user_management/services/user_management_service.dart';
import 'features/game/services/game_service.dart';
import 'features/rewards/services/reward_service.dart';
import 'features/live_session/services/live_session_service.dart';
import 'features/user_management/services/class_management_service.dart'
    as class_mgmt;
import 'features/game/services/ai_native_game_service.dart' as ai_game;
import 'features/student/services/student_analytics_service.dart';
import 'core/ai/chatgpt_service.dart';
import 'package:http/http.dart' as http;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Enable performance optimizations
  PerformanceConfig.enablePerformanceOptimizations();

  if (kDebugMode) {
    debugPrint('Starting Math Genius app initialization...');
  }

  try {
    if (kDebugMode) {
      debugPrint('Initializing Firebase...');
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

    if (kDebugMode) {
      print('Initializing Hive...');
    }
    // Initialize Hive
    await Hive.initFlutter();
    final hiveBox = await Hive.openBox('math_genius_data');
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

    if (kDebugMode) {
      print('All services initialized successfully');
    }

    // Initialize Firebase Analytics
    await FirebaseService.logEvent(
      name: 'app_start',
      parameters: {'timestamp': DateTime.now().toIso8601String()},
    );

    if (kDebugMode) {
      print('App initialization completed');
    }

    runApp(
      ProviderScope(
        overrides: [
          themeServiceProvider.overrideWithValue(ThemeService(prefs)),
          sharedPreferencesProvider.overrideWithValue(prefs),
          hiveBoxProvider.overrideWithValue(hiveBox),
          aiTutorServiceProvider.overrideWithValue(
            AITutorService(prefs, hiveBox),
          ),
          userPreferencesServiceProvider.overrideWithValue(
            UserPreferencesService(prefs),
          ),
          userManagementServiceProvider.overrideWithValue(
            UserManagementService(prefs, hiveBox),
          ),
          // Add other services that need SharedPreferences
          gameServiceProvider.overrideWithValue(GameService(prefs, hiveBox)),
          rewardServiceProvider.overrideWithValue(
            RewardService(prefs, hiveBox),
          ),
          liveSessionServiceProvider.overrideWithValue(
            LiveSessionService(prefs, hiveBox),
          ),
          class_mgmt.classManagementServiceProvider.overrideWithValue(
            class_mgmt.ClassManagementService(prefs),
          ),
          ai_game.aiNativeGameServiceProvider.overrideWithValue(
            ai_game.AINativeGameService(
              prefs,
              ChatGPTService(
                '', // API key will be loaded from config
                http.Client(),
                ChatGPTConfig(prefs),
              ),
            ),
          ),
          // ChatGPT config will be initialized automatically through its provider
          studentAnalyticsServiceProvider.overrideWithValue(
            StudentAnalyticsService(prefs, hiveBox),
          ),
          nativeFeaturesServiceProvider.overrideWithValue(
            NativeFeaturesService(prefs),
          ),
          accessibilityServiceProvider.overrideWithValue(
            AccessibilityService(),
          ),
          audioServiceProvider.overrideWithValue(
            AudioService(prefs),
          ),
          // Achievement and progress services will be added in future updates
        ],
        child: GlobalPreferencesListener(child: const MathGeniusApp()),
      ),
    );
  } catch (e) {
    if (kDebugMode) {
      print('Error initializing app: $e');
    }

    // Run app with minimal initialization on error
    runApp(ProviderScope(child: const MathGeniusApp()));
  }
}

class MathGeniusApp extends ConsumerWidget {
  const MathGeniusApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeData = ref.watch(themeDataProvider);
    final router = ref.watch(appRouterProvider);

    // Watch accessibility preferences for real-time updates
    final preferences = ref.watch(currentUserGamePreferencesProvider);
    final textScaler = ref.watch(textScalerProvider);

    // Get accessibility-enhanced theme
    ThemeData accessibleTheme = themeData.toThemeData();

    if (preferences != null) {
      // Apply high contrast mode
      if (preferences.highContrastMode) {
        final highContrastScheme =
            AccessibilityService.getHighContrastColorScheme(
              accessibleTheme.colorScheme,
              true,
            );
        accessibleTheme = accessibleTheme.copyWith(
          colorScheme: highContrastScheme,
        );
      }

      // Apply dyslexia-friendly text theme
      if (preferences.dyslexiaFriendlyMode) {
        final dyslexiaTheme = AccessibilityService.getDyslexiaFriendlyTextTheme(
          accessibleTheme.textTheme,
          true,
        );
        accessibleTheme = accessibleTheme.copyWith(textTheme: dyslexiaTheme);
      }

      // Apply visual theme switching
      accessibleTheme = _applyVisualTheme(
        accessibleTheme,
        preferences.visualTheme,
      );
    }

    return MediaQuery(
      // Apply font size scaling app-wide
      data: MediaQuery.of(context).copyWith(textScaler: textScaler),
      child: MaterialApp.router(
        title: 'Math Genius',
        theme: accessibleTheme,
        routerConfig: router,
        debugShowCheckedModeBanner: false,
        // Screen reader support
        builder: (context, child) {
          return AccessibilityWrapper(
            preferences: preferences,
            child: child ?? const SizedBox(),
          );
        },
      ),
    );
  }

  /// Apply visual theme transformations app-wide
  ThemeData _applyVisualTheme(ThemeData baseTheme, String visualTheme) {
    switch (visualTheme) {
      case 'dark':
        return baseTheme.copyWith(
          brightness: Brightness.dark,
          colorScheme: ColorScheme.fromSeed(
            seedColor: baseTheme.colorScheme.primary,
            brightness: Brightness.dark,
          ),
        );

      case 'colorful':
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.purple,
            brightness: Brightness.light,
          ),
          primaryColor: Colors.purple,
        );

      case 'minimal':
        return baseTheme.copyWith(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blueGrey,
            brightness: Brightness.light,
          ),
          primaryColor: Colors.blueGrey,
        );

      default: // 'default'
        return baseTheme;
    }
  }
}

