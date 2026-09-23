import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animation/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../state/settings_state.dart';

/// Interactive Apple-inspired Liquid Glass Button with tactile press animation.
class GlassButton extends StatefulWidget {
  final Widget? icon;
  final Widget? label;
  final String? tooltip;
  final VoidCallback? onPressed;
  final bool isPrimary;
  final bool isSelected;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;

  const GlassButton({
    super.key,
    this.icon,
    this.label,
    this.tooltip,
    required this.onPressed,
    this.isPrimary = false,
    this.isSelected = false,
    this.padding,
    this.borderRadius,
    this.width,
    this.height,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton> with SingleTickerProviderStateMixin {
  late AnimationController _pressAnim;
  late Animation<double> _scaleAnim;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _pressAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 180),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressAnim, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _pressAnim.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.onPressed != null) {
      _pressAnim.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.onPressed != null) {
      _pressAnim.reverse();
      widget.onPressed!();
    }
  }

  void _handleTapCancel() {
    _pressAnim.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState?>();
    final isReducedMotion = settings?.reducedMotion ?? false;
    final isGlassEnabled = settings?.glassEffectsEnabled ?? true;

    final radius = widget.borderRadius ?? BorderRadius.circular(9);

    // Styling variants
    Color backgroundColor;
    Color borderColor;
    Color foregroundColor;

    if (widget.isPrimary) {
      backgroundColor = _isHovered
          ? (isGlassEnabled ? AppColors.accent.withValues(alpha: 0.90) : AppColors.accentLight)
          : (isGlassEnabled ? AppColors.accent.withValues(alpha: 0.80) : AppColors.accent);
      borderColor = AppColors.accentLight.withValues(alpha: 0.50);
      foregroundColor = Colors.white;
    } else if (widget.isSelected) {
      backgroundColor = isGlassEnabled
          ? AppColors.glassAccent
          : AppColors.surfaceHover;
      borderColor = AppColors.accent.withValues(alpha: 0.45);
      foregroundColor = AppColors.accentLight;
    } else {
      backgroundColor = _isHovered
          ? (isGlassEnabled ? AppColors.glassSurfaceHover : AppColors.surfaceHover)
          : (isGlassEnabled ? AppColors.glassSurfaceLow : AppColors.surfaceElevated);
      borderColor = _isHovered
          ? AppColors.glassBorderHighlight
          : AppColors.glassBorder;
      foregroundColor = _isHovered ? AppColors.textPrimary : AppColors.textSecondary;
    }

    Widget buttonContent = AnimatedContainer(
      duration: AppAnimations.getDuration(AppAnimations.fast, reducedMotion: isReducedMotion),
      curve: AppAnimations.smooth,
      width: widget.width,
      height: widget.height,
      padding: widget.padding ??
          const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: radius,
        border: Border.all(color: borderColor, width: 1.0),
        boxShadow: widget.isPrimary && _isHovered
            ? AppColors.glowBlue
            : (_isHovered ? AppColors.cardShadow : null),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: foregroundColor,
        ),
        child: IconTheme(
          data: IconThemeData(
            size: 16,
            color: foregroundColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                widget.icon!,
                if (widget.label != null) const SizedBox(width: 8),
              ],
              if (widget.label != null)
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: widget.label!,
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    Widget interactive = MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        behavior: HitTestBehavior.opaque,
        child: isReducedMotion
            ? buttonContent
            : ScaleTransition(
                scale: _scaleAnim,
                child: buttonContent,
              ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: interactive,
      );
    }

    return interactive;
  }
}
