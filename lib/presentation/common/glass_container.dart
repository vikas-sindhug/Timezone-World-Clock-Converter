import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../state/settings_state.dart';

/// Reusable Apple-inspired Liquid Glass Container.
///
/// Features:
/// - Strategic backdrop blur with graceful opaque fallback
/// - Multi-layer translucent dark navy/charcoal glass
/// - Specular top-edge light refraction border
/// - Configurable borderRadius, padding, margin, and elevation
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? surfaceColor;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;
  final bool enableGlow;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 16.0,
    this.surfaceColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
    this.enableGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState?>();
    final isGlassEnabled = settings?.glassEffectsEnabled ?? true;
    final transparencyLevel = settings?.transparencyLevel ?? 'medium';

    final effectiveRadius = borderRadius ?? BorderRadius.circular(16);

    // Determine opacity based on settings
    double alphaMultiplier;
    switch (transparencyLevel) {
      case 'high':
        alphaMultiplier = 0.75;
        break;
      case 'low':
        alphaMultiplier = 1.25;
        break;
      case 'medium':
      default:
        alphaMultiplier = 1.0;
        break;
    }

    final effectiveSurface = surfaceColor ??
        (isGlassEnabled
            ? AppColors.glassSurface.withValues(
                alpha: (0.60 * alphaMultiplier).clamp(0.35, 0.92),
              )
            : AppColors.surfaceElevated);

    final effectiveBorderColor = borderColor ??
        (isGlassEnabled
            ? AppColors.glassBorderHighlight.withValues(
                alpha: (0.18 * alphaMultiplier).clamp(0.10, 0.35),
              )
            : AppColors.border);

    final effectiveShadows = shadows ??
        (isGlassEnabled
            ? (enableGlow
                ? [
                    ...AppColors.cardShadow,
                    BoxShadow(
                      color: (glowColor ?? AppColors.accent).withValues(alpha: 0.22),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : AppColors.cardShadow)
            : AppColors.cardShadow);

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveSurface,
        borderRadius: effectiveRadius,
        border: Border.all(
          color: effectiveBorderColor,
          width: borderWidth,
        ),
        boxShadow: effectiveShadows,
      ),
      child: child,
    );

    if (isGlassEnabled && blur > 0) {
      content = ClipRRect(
        borderRadius: effectiveRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: content,
        ),
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
