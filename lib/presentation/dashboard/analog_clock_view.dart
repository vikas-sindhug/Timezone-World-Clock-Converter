import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class AnalogClockView extends StatelessWidget {
  final DateTime time;
  final double size;
  final bool isDay;
  final bool showSeconds;

  const AnalogClockView({
    super.key,
    required this.time,
    this.size = 72,
    this.isDay = true,
    this.showSeconds = true,
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
          showSeconds: showSeconds,
        ),
      ),
    );
  }
}

class _AnalogClockPainter extends CustomPainter {
  final DateTime time;
  final bool isDay;
  final bool showSeconds;

  _AnalogClockPainter({
    required this.time,
    required this.isDay,
    required this.showSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Outer Liquid Glass Dial Background
    final dialRect = Rect.fromCircle(center: center, radius: radius);
    final dialPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0x38FFFFFF),
          Color(0x10FFFFFF),
          Color(0x06FFFFFF),
        ],
        stops: [0.0, 0.45, 1.0],
      ).createShader(dialRect)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, dialPaint);

    // Subtle glass specular rim
    final rimPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          isDay
              ? AppColors.dayAmber.withValues(alpha: 0.40)
              : AppColors.nightIndigo.withValues(alpha: 0.40),
          Colors.white.withValues(alpha: 0.15),
          Colors.white.withValues(alpha: 0.04),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(dialRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius - 0.6, rimPaint);

    // 2. Hour Markers (Ticks)
    final tickPaint = Paint()
      ..color = AppColors.textMuted.withValues(alpha: 0.5)
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < 12; i++) {
      final angle = i * (math.pi / 6);
      final isMajor = i % 3 == 0;
      final tickLength = isMajor ? radius * 0.18 : radius * 0.10;
      tickPaint.strokeWidth = isMajor ? 1.5 : 1.0;
      tickPaint.color = isMajor
          ? AppColors.textSecondary
          : AppColors.textMuted.withValues(alpha: 0.4);

      final p1 = Offset(
        center.dx + (radius - 4) * math.cos(angle),
        center.dy + (radius - 4) * math.sin(angle),
      );
      final p2 = Offset(
        center.dx + (radius - 4 - tickLength) * math.cos(angle),
        center.dy + (radius - 4 - tickLength) * math.sin(angle),
      );
      canvas.drawLine(p1, p2, tickPaint);
    }

    // Hand calculations
    final second = time.second + (time.millisecond / 1000.0);
    final minute = time.minute + (second / 60.0);
    final hour = (time.hour % 12) + (minute / 60.0);

    final hourAngle = (hour * 30.0 - 90.0) * (math.pi / 180.0);
    final minuteAngle = (minute * 6.0 - 90.0) * (math.pi / 180.0);
    final secondAngle = (second * 6.0 - 90.0) * (math.pi / 180.0);

    // 3. Hour Hand
    final hourPaint = Paint()
      ..color = AppColors.textPrimary
      ..strokeWidth = 2.4
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

    // 4. Minute Hand
    final minutePaint = Paint()
      ..color = AppColors.textPrimary.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    final minuteLength = radius * 0.72;
    canvas.drawLine(
      center,
      Offset(
        center.dx + minuteLength * math.cos(minuteAngle),
        center.dy + minuteLength * math.sin(minuteAngle),
      ),
      minutePaint,
    );

    // 5. Second Hand
    if (showSeconds) {
      final secondPaint = Paint()
        ..color = AppColors.accent
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final secondLength = radius * 0.82;
      final secondTail = radius * 0.15;

      canvas.drawLine(
        Offset(
          center.dx - secondTail * math.cos(secondAngle),
          center.dy - secondTail * math.sin(secondAngle),
        ),
        Offset(
          center.dx + secondLength * math.cos(secondAngle),
          center.dy + secondLength * math.sin(secondAngle),
        ),
        secondPaint,
      );

      // Center accent dot
      final centerDot = Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 2.2, centerDot);
    } else {
      final centerDot = Paint()
        ..color = AppColors.textPrimary
        ..style = PaintingStyle.fill;
      canvas.drawCircle(center, 2.0, centerDot);
    }
  }

  @override
  bool shouldRepaint(covariant _AnalogClockPainter oldDelegate) {
    return oldDelegate.time.second != time.second ||
        oldDelegate.time.minute != time.minute ||
        oldDelegate.time.hour != time.hour ||
        oldDelegate.isDay != isDay ||
        oldDelegate.showSeconds != showSeconds;
  }
}
