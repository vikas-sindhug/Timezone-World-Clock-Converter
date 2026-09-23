import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animation/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../state/settings_state.dart';

/// Authentic iPhone-inspired sliding glass segmented control.
class GlassSegmentedControl<T> extends StatelessWidget {
  final List<T> values;
  final List<String> labels;
  final T selectedValue;
  final ValueChanged<T> onValueChanged;
  final double height;
  final double? width;

  const GlassSegmentedControl({
    super.key,
    required this.values,
    required this.labels,
    required this.selectedValue,
    required this.onValueChanged,
    this.height = 34.0,
    this.width,
  }) : assert(values.length == labels.length, 'values and labels must have equal length');

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsState?>();
    final isReducedMotion = settings?.reducedMotion ?? false;
    final isGlassEnabled = settings?.glassEffectsEnabled ?? true;

    final selectedIndex = values.indexOf(selectedValue);
    final count = values.length;
    final resolvedWidth = width ?? (count * 52.0 + 6.0);

    return SizedBox(
      width: resolvedWidth,
      height: height,
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isGlassEnabled ? AppColors.glassSurfaceLow : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isGlassEnabled ? AppColors.glassBorder : AppColors.border,
            width: 1.0,
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
          final totalWidth = constraints.maxWidth;
          final itemWidth = totalWidth / count;

          return Stack(
            children: [
              // Sliding Active Glass Pill
              AnimatedPositioned(
                duration: AppAnimations.getDuration(
                  const Duration(milliseconds: 240),
                  reducedMotion: isReducedMotion,
                ),
                curve: AppAnimations.smooth,
                left: (selectedIndex >= 0 ? selectedIndex : 0) * itemWidth,
                top: 0,
                bottom: 0,
                width: itemWidth,
                child: Container(
                  decoration: BoxDecoration(
                    color: isGlassEnabled
                        ? AppColors.glassSurfaceActive
                        : AppColors.surfaceHover,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                      color: isGlassEnabled
                          ? AppColors.glassBorderHighlight
                          : AppColors.borderFocus.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),

              // Labels row
              Row(
                children: List.generate(count, (index) {
                  final isSelected = index == selectedIndex;
                  return Expanded(
                    child: InkWell(
                      onTap: () => onValueChanged(values[index]),
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: AnimatedDefaultTextStyle(
                          duration: AppAnimations.getDuration(
                            AppAnimations.fast,
                            reducedMotion: isReducedMotion,
                          ),
                          curve: AppAnimations.smooth,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textMuted,
                          ),
                          child: Text(labels[index]),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    ),
    );
  }
}
