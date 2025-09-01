import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Interactive math tools for visual learning
class InteractiveMathTools {
  /// Number line widget for addition/subtraction
  static Widget buildNumberLine({
    required BuildContext context,
    required int start,
    required int end,
    required int currentValue,
    required Color color,
    Function(int)? onNumberTap,
  }) {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CustomPaint(
        size: const Size(double.infinity, 80),
        painter: _NumberLinePainter(
          start: start,
          end: end,
          currentValue: currentValue,
          color: color,
        ),
        child: GestureDetector(
          onTapDown: (details) {
            if (onNumberTap != null) {
              final RenderBox renderBox =
                  context.findRenderObject() as RenderBox;
              final localPosition = renderBox.globalToLocal(
                details.globalPosition,
              );
              final width = renderBox.size.width - 32; // Account for padding
              final ratio = localPosition.dx / width;
              final tappedNumber = start + ((end - start) * ratio).round();
              onNumberTap(tappedNumber.clamp(start, end));
            }
          },
        ),
      ),
    );
  }

  /// Fraction visualization tool
  static Widget buildFractionVisualizer({
    required BuildContext context,
    required int numerator,
    required int denominator,
    required Color color,
    bool showAnimation = true,
  }) {
    return Column(
      children: [
        // Fraction display
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$numerator',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Container(
              width: 40,
              height: 2,
              color: color,
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
            Text(
              '$denominator',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // Visual fraction representation
        _buildFractionCircles(numerator, denominator, color, showAnimation),

        const SizedBox(height: 16),

        // Alternative bar representation
        _buildFractionBars(numerator, denominator, color, showAnimation),
      ],
    );
  }

  /// Build fraction circles
  static Widget _buildFractionCircles(
    int numerator,
    int denominator,
    Color color,
    bool animate,
  ) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _FractionCirclePainter(
          numerator: numerator,
          denominator: denominator,
          color: color,
          animationProgress: animate ? 1.0 : 1.0,
        ),
      ),
    );
  }

  /// Build fraction bars
  static Widget _buildFractionBars(
    int numerator,
    int denominator,
    Color color,
    bool animate,
  ) {
    return Column(
      children: List.generate(denominator, (index) {
        final isFilled = index < numerator;
        return TweenAnimationBuilder<double>(
          duration: Duration(milliseconds: animate ? 200 + (index * 100) : 0),
          tween: Tween(begin: 0.0, end: 1.0),
          builder: (context, value, child) {
            return Container(
              width: 200 * value,
              height: 20,
              margin: const EdgeInsets.symmetric(vertical: 2),
              decoration: BoxDecoration(
                color: isFilled ? color : color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: color, width: 1),
              ),
            );
          },
        );
      }),
    );
  }

  /// Multiplication grid visualizer
  static Widget buildMultiplicationGrid({
    required BuildContext context,
    required int factor1,
    required int factor2,
    required Color color,
    bool showAnimation = true,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            '$factor1 × $factor2 = ${factor1 * factor2}',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 16),

          // Grid visualization
          _buildGrid(factor1, factor2, color, showAnimation),
        ],
      ),
    );
  }

  /// Build multiplication grid
  static Widget _buildGrid(int rows, int cols, Color color, bool animate) {
    return Column(
      children: List.generate(rows, (row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(cols, (col) {
            return TweenAnimationBuilder<double>(
              duration: Duration(
                milliseconds: animate ? 100 + ((row * cols + col) * 50) : 0,
              ),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: value,
                  child: Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              },
            );
          }),
        );
      }),
    );
  }

  /// Geometry shape builder
  static Widget buildGeometryShape({
    required BuildContext context,
    required String shapeType,
    required Map<String, double> dimensions,
    required Color color,
  }) {
    return SizedBox(
      width: 200,
      height: 200,
      child: CustomPaint(
        painter: _GeometryShapePainter(
          shapeType: shapeType,
          dimensions: dimensions,
          color: color,
        ),
      ),
    );
  }
}

/// Custom painter for number line
class _NumberLinePainter extends CustomPainter {
  final int start;
  final int end;
  final int currentValue;
  final Color color;

  _NumberLinePainter({
    required this.start,
    required this.end,
    required this.currentValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final textPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Draw main line
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );

    // Draw tick marks and numbers
    for (int i = start; i <= end; i++) {
      final x = (i - start) / (end - start) * size.width;

      // Tick mark
      canvas.drawLine(
        Offset(x, size.height / 2 - 10),
        Offset(x, size.height / 2 + 10),
        paint,
      );

      // Number label
      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: i == currentValue ? color : color.withValues(alpha: 0.6),
          fontSize: i == currentValue ? 16 : 12,
          fontWeight: i == currentValue ? FontWeight.bold : FontWeight.normal,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, size.height / 2 + 15),
      );
    }

    // Highlight current value
    final currentX = (currentValue - start) / (end - start) * size.width;
    canvas.drawCircle(
      Offset(currentX, size.height / 2),
      8,
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for fraction circles
class _FractionCirclePainter extends CustomPainter {
  final int numerator;
  final int denominator;
  final Color color;
  final double animationProgress;

  _FractionCirclePainter({
    required this.numerator,
    required this.denominator,
    required this.color,
    required this.animationProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 10;

    // Draw circle outline
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );

    // Draw fraction segments
    final segmentAngle = 2 * math.pi / denominator;

    for (int i = 0; i < denominator; i++) {
      final startAngle = -math.pi / 2 + i * segmentAngle;
      final isFilled = i < numerator;

      if (isFilled) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          startAngle,
          segmentAngle * animationProgress,
          true,
          Paint()..color = color.withValues(alpha: 0.7),
        );
      }

      // Draw segment dividers
      final endX = center.dx + radius * math.cos(startAngle);
      final endY = center.dy + radius * math.sin(startAngle);
      canvas.drawLine(
        center,
        Offset(endX, endY),
        Paint()
          ..color = color
          ..strokeWidth = 1,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

/// Custom painter for geometry shapes
class _GeometryShapePainter extends CustomPainter {
  final String shapeType;
  final Map<String, double> dimensions;
  final Color color;

  _GeometryShapePainter({
    required this.shapeType,
    required this.dimensions,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final center = Offset(size.width / 2, size.height / 2);

    switch (shapeType.toLowerCase()) {
      case 'circle':
        final radius = dimensions['radius'] ?? 50;
        canvas.drawCircle(center, radius, paint);
        break;

      case 'square':
        final sideLength = dimensions['side'] ?? 80;
        final rect = Rect.fromCenter(
          center: center,
          width: sideLength,
          height: sideLength,
        );
        canvas.drawRect(rect, paint);
        break;

      case 'rectangle':
        final width = dimensions['width'] ?? 100;
        final height = dimensions['height'] ?? 60;
        final rect = Rect.fromCenter(
          center: center,
          width: width,
          height: height,
        );
        canvas.drawRect(rect, paint);
        break;

      case 'triangle':
        final sideLength = dimensions['side'] ?? 80;
        final height = sideLength * math.sqrt(3) / 2;

        final path = Path();
        path.moveTo(center.dx, center.dy - height / 2);
        path.lineTo(center.dx - sideLength / 2, center.dy + height / 2);
        path.lineTo(center.dx + sideLength / 2, center.dy + height / 2);
        path.close();

        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
