import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/barrel.dart';

/// Responsive home screen that uses adaptive UI components
class ResponsiveHomeScreen extends ConsumerWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use the adaptive UI system to create the appropriate home screen
    return AdaptiveUISystem.createAdaptiveHomeScreen(context);
  }
}
