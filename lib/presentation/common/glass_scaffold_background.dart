import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Depth-rich subtle ambient background for Apple-inspired Liquid Glass UI.
class GlassScaffoldBackground extends StatelessWidget {
  final Widget child;

  const GlassScaffoldBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Deep Void Base
        Container(
          color: AppColors.glassBaseDark,
        ),

        // 2. Ambient Top-Center Cool Blue Radial Illumination
        Positioned(
          top: -120,
          left: 0,
          right: 0,
          height: 480,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.0, -0.3),
                  radius: 1.1,
                  colors: [
                    const Color(0xFF1E3A8A).withValues(alpha: 0.14),
                    const Color(0xFF0F172A).withValues(alpha: 0.05),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ),

        // 3. Ambient Bottom-Right Soft Violet Tint (extremely subtle depth)
        Positioned(
          bottom: -150,
          right: -100,
          width: 500,
          height: 500,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    const Color(0xFF4338CA).withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),

        // 4. Main Foreground Content
        child,
      ],
    );
  }
}
