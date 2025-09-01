import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/barrel.dart';
import '../user_management/services/user_management_service.dart';
import '../user_management/models/user_model.dart' as user_models;

/// Responsive home screen that uses adaptive UI components
class ResponsiveHomeScreen extends ConsumerWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Check if user is authenticated and redirect students to dashboard
    return FutureBuilder(
      future: _checkUserAndRedirect(context, ref),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Use the adaptive UI system to create the appropriate home screen
        return AdaptiveUISystem.createAdaptiveHomeScreen(context);
      },
    );
  }

  Future<void> _checkUserAndRedirect(
    BuildContext context,
    WidgetRef ref,
  ) async {
    try {
      final userManagementService = ref.read(userManagementServiceProvider);
      final currentUser = await userManagementService.getCurrentUser();

      if (currentUser != null &&
          currentUser.role == user_models.UserRole.student) {
        // Redirect students to their dashboard
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go('/student');
          }
        });
      }
    } catch (e) {
      // If there's an error getting user info, just stay on home
      debugPrint('Error checking user for redirect: $e');
    }
  }
}
