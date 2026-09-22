import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Official FocusHabitual Vector Logo Widget.
/// Faithfully reproduces the concentric focus target and cobalt squircle geometry.
class FocusHabitualLogo extends StatelessWidget {
  const FocusHabitualLogo({
    super.key,
    this.size = 36,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _LogoPainter(),
      ),
    );
  }
}

class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w / 2, h / 2);
    final scale = w / 100.0;

    // 1. Background rounded squircle (Cobalt Sapphire #2563EB)
    final bgPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, w, h),
      Radius.circular(26 * scale),
    );
    canvas.drawRRect(bgRect, bgPaint);

    // 2. Translucent outer circle ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4 * scale;
    canvas.drawCircle(center, 26 * scale, ringPaint);

    // 3. Highlighted active arc (top right quadrant)
    final arcPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.5 * scale
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: 26 * scale),
      -math.pi / 2,
      math.pi / 2,
      false,
      arcPaint,
    );

    // 4. White center target disc
    final discPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10 * scale, discPaint);

    // 5. Center cobalt core dot
    final corePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4 * scale, corePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
