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
          aiTutorServiceProvider.overrideWithValue(AITutorService(prefs, hiveBox)),
        ],
        child: const MathGeniusApp(),
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

    return MaterialApp.router(
      title: 'Math Genius',
      theme: themeData.toThemeData(),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
