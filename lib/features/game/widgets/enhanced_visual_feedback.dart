import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Enhanced visual feedback system for math games
class EnhancedVisualFeedback {
  /// Create animated number visualization
  static Widget buildNumberVisualization({
    required BuildContext context,
    required int number,
    required String operation,
    required Color color,
    bool showAnimation = true,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: showAnimation ? 800 : 0),
      curve: Curves.elasticOut,
      child: Column(
        children: [
          // Visual representation using dots/objects
          if (number <= 20) _buildDotVisualization(number, color),
          if (number > 20 && number <= 100)
            _buildGroupVisualization(number, color),
          if (number > 100) _buildPlaceValueVisualization(number, color),

          const SizedBox(height: 16),

          // Number display with animation
          TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: showAnimation ? 1000 : 0),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Text(
                    '$number',
                    style: TextStyle(
                      fontSize: 24 + (8 * value),
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Build dot visualization for small numbers (1-20)
  static Widget _buildDotVisualization(int number, Color color) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: List.generate(number, (index) {
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: 200 + (index * 50)),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }

  /// Build group visualization for medium numbers (21-100)
  static Widget _buildGroupVisualization(int number, Color color) {
    final groups = (number / 10).ceil();
    final remainder = number % 10;

    return Column(
      children: [
        // Groups of 10
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(groups - (remainder > 0 ? 1 : 0), (index) {
            return _buildGroupOf10(color, index);
          }),
        ),

        // Remainder
        if (remainder > 0) ...[
          const SizedBox(height: 8),
          _buildPartialGroup(remainder, color, groups - 1),
        ],
      ],
    );
  }

  /// Build group of 10 dots
  static Widget _buildGroupOf10(Color color, int groupIndex) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (groupIndex * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: color, width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              children: List.generate(10, (index) {
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  /// Build partial group for remainder
  static Widget _buildPartialGroup(int count, Color color, int groupIndex) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (groupIndex * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 2,
              runSpacing: 2,
              children: List.generate(count, (index) {
                return Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  /// Build place value visualization for large numbers (100+)
  static Widget _buildPlaceValueVisualization(int number, Color color) {
    final hundreds = number ~/ 100;
    final tens = (number % 100) ~/ 10;
    final ones = number % 10;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        if (hundreds > 0)
          _buildPlaceValueColumn('Hundreds', hundreds, color, 0),
        if (tens > 0 || hundreds > 0)
          _buildPlaceValueColumn('Tens', tens, color, 1),
        _buildPlaceValueColumn('Ones', ones, color, 2),
      ],
    );
  }

  /// Build place value column
  static Widget _buildPlaceValueColumn(
    String label,
    int value,
    Color color,
    int index,
  ) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 400 + (index * 200)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, animValue, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animValue)),
          child: Opacity(
            opacity: animValue,
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 40,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    border: Border.all(color: color, width: 2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '$value',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Create animated progress ring
  static Widget buildProgressRing({
    required BuildContext context,
    required double progress, // 0.0 to 1.0
    required Color color,
    required String label,
    double size = 100,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1500),
      tween: Tween(begin: 0.0, end: progress),
      builder: (context, value, child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: size,
                height: size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.1),
                ),
              ),

              // Progress circle
              CustomPaint(
                size: Size(size, size),
                painter: _ProgressRingPainter(
                  progress: value,
                  color: color,
                  strokeWidth: 8,
                ),
              ),

              // Center content
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${(value * 100).round()}%',
                      style: TextStyle(
                        fontSize: size * 0.15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: size * 0.08,
                        color: color.withValues(alpha: 0.8),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Create celebration animation
  static Widget buildCelebrationAnimation({
    required BuildContext context,
    required bool isCorrect,
    required VoidCallback onComplete,
  }) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 2000),
      tween: Tween(begin: 0.0, end: 1.0),
      onEnd: onComplete,
      builder: (context, value, child) {
        return Stack(
          children: [
            // Confetti effect for correct answers
            if (isCorrect) ..._buildConfettiParticles(value),

            // Feedback icon
            Center(
              child: Transform.scale(
                scale: 1.0 + (math.sin(value * math.pi * 4) * 0.1),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isCorrect ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (isCorrect ? Colors.green : Colors.red)
                            .withValues(alpha: 0.3),
                        blurRadius: 20 * value,
                        spreadRadius: 5 * value,
                      ),
                    ],
                  ),
                  child: Icon(
                    isCorrect ? Icons.check : Icons.close,
                    size: 60,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build confetti particles
  static List<Widget> _buildConfettiParticles(double animationValue) {
    return List.generate(20, (index) {
      final random = math.Random(index);
      final startX = random.nextDouble();
      final startY = random.nextDouble() * 0.3;
      final endY = 1.0 + random.nextDouble() * 0.5;
      final rotation = random.nextDouble() * 6.28;

      return Positioned(
        left: 400 * startX, // Use fixed width instead of context
        top: 600 * (startY + (endY - startY) * animationValue),
        child: Transform.rotate(
          angle: rotation * animationValue,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.primaries[index % Colors.primaries.length],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      );
    });
  }
}

/// Custom painter for progress ring
class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw progress arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start from top
      2 * math.pi * progress, // Progress amount
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
