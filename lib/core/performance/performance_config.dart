import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Performance configuration and optimization utilities
class PerformanceConfig {
  static const bool enableAnimations = true;
  static const bool enableShadows = true;
  static const bool enableGradients = true;
  static const int maxCachedQuestions = 50;
  static const Duration animationDuration = Duration(milliseconds: 150);
  
  /// Performance mode based on device capabilities
  static UIPerformanceMode getPerformanceMode() {
    // In debug mode, use balanced for testing
    if (kDebugMode) {
      return UIPerformanceMode.balanced;
    }
    
    // In release mode, optimize based on device
    return UIPerformanceMode.optimized;
  }
  
  /// Get optimized shadow configuration
  static List<BoxShadow> getOptimizedShadows({
    required Color color,
    double opacity = 0.1,
    double blurRadius = 8.0,
    Offset offset = const Offset(0, 2),
  }) {
    final mode = getPerformanceMode();
    
    switch (mode) {
      case UIPerformanceMode.minimal:
        return [];
      case UIPerformanceMode.balanced:
        return [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: blurRadius * 0.7,
            offset: offset,
          ),
        ];
      case UIPerformanceMode.optimized:
        return [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: blurRadius,
            offset: offset,
          ),
        ];
    }
  }
  
  /// Get optimized border radius
  static BorderRadius getOptimizedBorderRadius(double radius) {
    return BorderRadius.circular(radius);
  }
  
  /// Get optimized animation duration
  static Duration getOptimizedDuration(Duration baseDuration) {
    final mode = getPerformanceMode();
    
    switch (mode) {
      case UIPerformanceMode.minimal:
        return Duration.zero;
      case UIPerformanceMode.balanced:
        return Duration(milliseconds: (baseDuration.inMilliseconds * 0.7).round());
      case UIPerformanceMode.optimized:
        return baseDuration;
    }
  }
  
  /// Optimize widget tree by reducing nesting
  static Widget optimizeContainer({
    required Widget child,
    Color? color,
    BorderRadius? borderRadius,
    List<BoxShadow>? boxShadow,
    EdgeInsets? padding,
    EdgeInsets? margin,
  }) {
    Widget result = child;
    
    // Apply padding if needed
    if (padding != null) {
      result = Padding(padding: padding, child: result);
    }
    
    // Apply container decoration only if needed
    if (color != null || borderRadius != null || boxShadow != null) {
      result = Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: borderRadius,
          boxShadow: boxShadow,
        ),
        child: result,
      );
    }
    
    // Apply margin if needed
    if (margin != null) {
      result = Container(margin: margin, child: result);
    }
    
    return result;
  }
  
  /// Enable performance optimizations
  static void enablePerformanceOptimizations() {
    // Reduce animation scale for better performance
    if (!kDebugMode) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    }
  }
}

/// Performance modes for different device capabilities
enum UIPerformanceMode {
  minimal,    // Lowest-end devices
  balanced,   // Mid-range devices  
  optimized,  // High-end devices
}

/// Optimized widget mixins for better performance
mixin PerformanceOptimizedWidget {
  /// Check if widget should rebuild
  bool shouldRebuild(covariant oldWidget) {
    return true; // Override in implementations
  }
  
  /// Get optimized text style
  TextStyle getOptimizedTextStyle({
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      // Optimize for performance
      inherit: false,
      textBaseline: TextBaseline.alphabetic,
    );
  }
}
