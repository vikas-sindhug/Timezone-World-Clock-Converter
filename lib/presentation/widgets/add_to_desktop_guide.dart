import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';

/// Modal dialog showing native instructions for placing WorldClock widgets via the macOS Widget Gallery.
class AddToDesktopGuideDialog extends StatelessWidget {
  final String? cityName;

  const AddToDesktopGuideDialog({super.key, this.cityName});

  static Future<void> show(BuildContext context, {String? cityName}) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (ctx) => AddToDesktopGuideDialog(cityName: cityName),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: GlassContainer(
            borderRadius: BorderRadius.circular(20),
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.widgets_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            cityName != null ? '$cityName Widget Ready' : 'Add Widget to Mac Desktop',
                            style: AppTypography.h3,
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Follow these steps in macOS to place the widget',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                      splashRadius: 18,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                const Divider(height: 1, color: AppColors.glassBorder),
                const SizedBox(height: 20),

                // Step 1
                _buildStepRow(
                  stepNumber: '1',
                  title: 'Open macOS Widget Gallery',
                  description:
                      'Right-click anywhere on your macOS Desktop and select "Edit Widgets..." (or click the date/time in the top menu bar, scroll down, and click "Edit Widgets").',
                  icon: Icons.desktop_mac_rounded,
                ),

                const SizedBox(height: 16),

                // Step 2
                _buildStepRow(
                  stepNumber: '2',
                  title: 'Select WorldClock in the Sidebar',
                  description:
                      'Scroll or search for "WorldClock" in the app list to reveal the Small, Medium, and Large widgets.',
                  icon: Icons.search_rounded,
                ),

                const SizedBox(height: 16),

                // Step 3
                _buildStepRow(
                  stepNumber: '3',
                  title: 'Choose Size & Click (+) Add Widget',
                  description:
                      'Choose Small, Medium, or Large, then click the green (+) button or drag the widget directly to your preferred spot on your desktop.',
                  icon: Icons.add_circle_outline_rounded,
                ),

                const SizedBox(height: 16),

                // Step 4
                _buildStepRow(
                  stepNumber: '4',
                  title: 'Customize Your City Anytime',
                  description:
                      'Right-click any widget on your desktop and choose "Edit Widget" to change the city, toggle analog dial, seconds, or UTC offset.',
                  icon: Icons.tune_rounded,
                ),

                const SizedBox(height: 24),

                // Footer Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GlassButton(
                      label: const Text('Got It'),
                      isPrimary: true,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({
    required String stepNumber,
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          alignment: Alignment.center,
          child: Text(
            stepNumber,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.accentLight,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.bodyBold),
              const SizedBox(height: 2),
              Text(
                description,
                style: AppTypography.caption.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
