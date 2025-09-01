import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../preferences/preferences_notifier.dart';

/// Adaptive animation controller that respects reduced motion preferences
class AdaptiveAnimationController extends AnimationController {
  final WidgetRef? ref;
  final Duration originalDuration;

  AdaptiveAnimationController({
    required this.originalDuration,
    required super.vsync,
    this.ref,
  }) : super(duration: originalDuration) {
    _updateDurationFromPreferences();
  }

  /// Update animation duration based on reduced motion preference
  void _updateDurationFromPreferences() {
    if (ref == null) return;

    try {
      final prefs = ref!.read(currentUserGamePreferencesProvider);
      if (prefs?.reducedMotion == true) {
        // Reduce animation duration by 80%
        final reducedMs = (originalDuration.inMilliseconds * 0.2).round();
        duration = Duration(milliseconds: reducedMs < 50 ? 50 : reducedMs);
      } else {
        duration = originalDuration;
      }
    } catch (e) {
      duration = originalDuration;
    }
  }

  /// Create adaptive animation controller with preference watching
  static AdaptiveAnimationController create({
    required Duration duration,
    required TickerProvider vsync,
    WidgetRef? ref,
  }) {
    return AdaptiveAnimationController(
      originalDuration: duration,
      vsync: vsync,
      ref: ref,
    );
  }
}

/// Extension for easy adaptive animation creation
extension AdaptiveAnimations on TickerProvider {
  AdaptiveAnimationController createAdaptiveController({
    required Duration duration,
    WidgetRef? ref,
  }) {
    return AdaptiveAnimationController.create(
      duration: duration,
      vsync: this,
      ref: ref,
    );
  }
}

/// Provider for adaptive animation durations
final adaptiveAnimationDurationProvider = Provider.family<Duration, Duration>((
  ref,
  originalDuration,
) {
  final prefs = ref.watch(currentUserGamePreferencesProvider);
  if (prefs?.reducedMotion == true) {
    final reducedMs = (originalDuration.inMilliseconds * 0.2).round();
    return Duration(milliseconds: reducedMs < 50 ? 50 : reducedMs);
  }
  return originalDuration;
});
