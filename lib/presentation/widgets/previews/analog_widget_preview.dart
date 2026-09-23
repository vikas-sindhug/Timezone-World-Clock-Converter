import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Pixel-perfect native SwiftUI Analog Clock Widget renderer for Flutter previews.
class AnalogWidgetPreview extends StatelessWidget {
  final DateTime time;
  final double size;
  final bool isDay;

  const AnalogWidgetPreview({
    super.key,
    required this.time,
    this.size = 56,
    this.isDay = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AnalogClockPainter(
          time: time,
          isDay: isDay,
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final bool isDay;

  _AnalogClockPainter({required this.time, required this.isDay});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Dial background
    final bgPaint = Paint()
      ..color = const Color(0xFF0C0F17).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Outer rim highlight
    final rimPaint = Paint()
      ..color = isDay
          ? AppColors.dayAmber.withValues(alpha: 0.45)
          : AppColors.nightIndigo.withValues(alpha: 0.40)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 0.6, rimPaint);

    // 4 major hour tick marks (12, 3, 6, 9)
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.65)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 4; i++) {
      final angle = i * (math.pi / 2);
      final p1 = Offset(
        center.dx + (radius - 6) * math.cos(angle),
        center.dy + (radius - 6) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 2) * math.cos(angle),
        center.dy + (radius - 2) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Hour Hand
    final hour = time.hour % 12;
    final minute = time.minute;
    final second = time.second;
    final hourAngle = (hour + minute / 60.0) * (2 * math.pi / 12) - math.pi / 2;

    final hourPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final hourLength = radius * 0.52;
    canvas.drawLine(
      center,
      Offset(
        center.dx + hourLength * math.cos(hourAngle),
        center.dy + hourLength * math.sin(hourAngle),
      ),
      hourPaint,
    );

    // Minute Hand
    final minuteAngle = (minute + second / 60.0) * (2 * math.pi / 60) - math.pi / 2;
    final minutePaint = Paint()
      ..color = const Color(0xFFD6E4FF)
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round;

    final minuteLength = radius * 0.74;
    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * math.cos(minuteAngle),
        center.dy + minuteLength * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    // Center pivot cap
    final capPaint = Paint()
      ..color = AppColors.accentLight
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3.0, capPaint);
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return oldDelegate.time.second != time.second ||
        oldDelegate.time.minute != time.minute ||
        oldDelegate.time.hour != time.hour;
  }
}
