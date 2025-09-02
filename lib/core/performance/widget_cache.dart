import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// High-performance widget cache for frequently used components
class WidgetCache {
  static final Map<String, Widget> _cache = {};
  static const int maxCacheSize = 100;
  
  /// Get cached widget or create and cache it
  static Widget getCachedWidget(String key, Widget Function() builder) {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    
    final widget = builder();
    
    // Manage cache size
    if (_cache.length >= maxCacheSize) {
      _cache.clear();
    }
    
    _cache[key] = widget;
    return widget;
  }
  
  /// Clear widget cache
  static void clearCache() {
    _cache.clear();
  }
  
  /// Get cache size
  static int get cacheSize => _cache.length;
}

/// Optimized reusable widgets
class OptimizedWidgets {
  /// Optimized SizedBox with common sizes
  static const Widget space4 = SizedBox(height: 4);
  static const Widget space8 = SizedBox(height: 8);
  static const Widget space12 = SizedBox(height: 12);
  static const Widget space16 = SizedBox(height: 16);
  static const Widget space20 = SizedBox(height: 20);
  static const Widget space24 = SizedBox(height: 24);
  
  static const Widget spaceW4 = SizedBox(width: 4);
  static const Widget spaceW8 = SizedBox(width: 8);
  static const Widget spaceW12 = SizedBox(width: 12);
  static const Widget spaceW16 = SizedBox(width: 16);
  
  /// Optimized dividers
  static const Widget verticalDivider = SizedBox(
    width: 1,
    height: 35,
    child: DecoratedBox(
      decoration: BoxDecoration(color: Color(0xFFE5E7EB)),
    ),
  );
  
  /// Optimized loading indicator
  static Widget loadingIndicator({
    required Color color,
    double size = 40,
    double strokeWidth = 3,
  }) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(color),
        strokeWidth: strokeWidth,
        backgroundColor: color.withValues(alpha: 0.15),
      ),
    );
  }
  
  /// Optimized icon container
  static Widget iconContainer({
    required IconData icon,
    required Color color,
    double size = 24,
    double containerSize = 48,
    double alpha = 0.1,
  }) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: alpha),
        borderRadius: BorderRadius.circular(containerSize * 0.25),
      ),
      child: Icon(
        icon,
        size: size,
        color: color,
      ),
    );
  }
}

/// Performance monitoring widget
class PerformanceMonitor extends StatefulWidget {
  final Widget child;
  final String widgetName;
  
  const PerformanceMonitor({
    super.key,
    required this.child,
    required this.widgetName,
  });

  @override
  State<PerformanceMonitor> createState() => _PerformanceMonitorState();
}

class _PerformanceMonitorState extends State<PerformanceMonitor> {
  late final Stopwatch _stopwatch;
  
  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
  }
  
  @override
  void dispose() {
    _stopwatch.stop();
    if (kDebugMode && _stopwatch.elapsedMilliseconds > 16) {
      debugPrint('⚠️ ${widget.widgetName} took ${_stopwatch.elapsedMilliseconds}ms to render');
    }
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
