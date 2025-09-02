import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';

/// Global providers for shared dependencies
/// This eliminates duplicate provider definitions across the codebase

/// Global SharedPreferences provider
/// Used by all services that need persistent storage
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'SharedPreferences must be initialized in main.dart with actual instance',
  );
});

/// Global Hive box provider
/// Used by services that need local NoSQL storage
final hiveBoxProvider = Provider<Box?>((ref) {
  throw UnimplementedError(
    'Hive box must be initialized in main.dart with actual instance',
  );
});

/// Global app initialization state provider
/// Tracks whether all core services have been initialized
final appInitializationProvider = StateProvider<bool>((ref) => false);

/// Global error state provider
/// Tracks application-level errors for centralized handling
final globalErrorProvider = StateProvider<String?>((ref) => null);

/// Global loading state provider
/// Tracks application-level loading states
final globalLoadingProvider = StateProvider<bool>((ref) => false);
