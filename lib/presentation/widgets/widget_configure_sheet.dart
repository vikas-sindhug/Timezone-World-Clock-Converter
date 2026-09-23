import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../state/clock_state.dart';
import '../../state/widget_state.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';

/// Modal dialog allowing the user to configure macOS Desktop Widget options.
class WidgetConfigureSheet extends StatelessWidget {
  const WidgetConfigureSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (_) => const Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.symmetric(horizontal: 40, vertical: 24),
        child: WidgetConfigureSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final widgetState = context.watch<DesktopWidgetState>();
    final clockState = context.watch<ClockState>();
    final cities = clockState.cities;
    final config = widgetState.config;
    final selectedCity = widgetState.getSelectedCity(cities);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 580, maxHeight: 680),
      child: GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(20),
        borderColor: AppColors.glassBorderHighlight,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.glassAccent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.glassBorderAccent),
                  ),
                  child: const Icon(Icons.widgets_rounded, size: 20, color: AppColors.accentLight),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Widget Configuration', style: AppTypography.h2),
                      Text(
                        'Customize how your macOS desktop widgets display live time and details',
                        style: AppTypography.caption,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppColors.textMuted),
                  splashRadius: 18,
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            const SizedBox(height: 20),
            Divider(height: 1, color: AppColors.glassBorder),
            const SizedBox(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Primary City Selection for Single Widget
                    const Text('Primary City (Small & Medium Widgets)', style: AppTypography.bodyBold),
                    const SizedBox(height: 4),
                    const Text(
                      'Choose which clock appears on single-city desktop widgets',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.glassSurface,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.glassBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCity?.id,
                          isExpanded: true,
                          dropdownColor: const Color(0xFF1B2030),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.accentLight),
                          items: cities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city.id,
                              child: Row(
                                children: [
                                  Text(city.flagEmoji, style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Text(city.name, style: AppTypography.bodyBold),
                                  const SizedBox(width: 6),
                                  Text('(${city.country})', style: AppTypography.caption),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (newId) {
                            if (newId != null) {
                              widgetState.setSingleCity(newId, cities);
                            }
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Display Information Toggles
                    const Text('Display Information', style: AppTypography.bodyBold),
                    const SizedBox(height: 4),
                    const Text(
                      'Turn visual elements on or off. Widgets automatically adapt their layout.',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 12),

                    _ToggleTile(
                      title: '12-Hour / 24-Hour Time Format',
                      subtitle: 'Use 24-hour military notation instead of AM/PM',
                      value: config.is24Hour,
                      onChanged: (val) => widgetState.updateConfig(
                        is24Hour: val,
                        availableCities: cities,
                      ),
                    ),
                    _ToggleTile(
                      title: 'Show Seconds in Medium Widget',
                      subtitle: 'Display high-precision live seconds',
                      value: config.showSeconds,
                      onChanged: (val) => widgetState.updateConfig(
                        showSeconds: val,
                        availableCities: cities,
                      ),
                    ),
                    _ToggleTile(
                      title: 'Show Analog Clock Dial',
                      subtitle: 'Display minimalist vector analog dial alongside digital time',
                      value: config.showAnalog,
                      onChanged: (val) => widgetState.updateConfig(
                        showAnalog: val,
                        availableCities: cities,
                      ),
                    ),
                    _ToggleTile(
                      title: 'Show Calendar Date',
                      subtitle: 'Show the current day of week and date in the city’s timezone',
                      value: config.showDate,
                      onChanged: (val) => widgetState.updateConfig(
                        showDate: val,
                        availableCities: cities,
                      ),
                    ),
                    _ToggleTile(
                      title: 'Show UTC Offset Badge',
                      subtitle: 'Display exact standard offset (e.g. UTC+09:00, UTC+05:30)',
                      value: config.showUtcOffset,
                      onChanged: (val) => widgetState.updateConfig(
                        showUtcOffset: val,
                        availableCities: cities,
                      ),
                    ),
                    _ToggleTile(
                      title: 'Show Difference from Local Time',
                      subtitle: 'Display relative difference (e.g. +3h 30m from local)',
                      value: config.showDifferenceFromLocal,
                      onChanged: (val) => widgetState.updateConfig(
                        showDifferenceFromLocal: val,
                        availableCities: cities,
                      ),
                    ),
                    _ToggleTile(
                      title: 'Show Day / Night Solar Status',
                      subtitle: 'Display sun/moon indicator based on local astronomical position',
                      value: config.showDayNight,
                      onChanged: (val) => widgetState.updateConfig(
                        showDayNight: val,
                        availableCities: cities,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Multi-Clock Selection
                    const Text('Multi-City Widget Slots (Large Widget)', style: AppTypography.bodyBold),
                    const SizedBox(height: 4),
                    const Text(
                      'Select between 2 and 6 cities to display simultaneously on the large desktop widget',
                      style: AppTypography.caption,
                    ),
                    const SizedBox(height: 10),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: cities.map((city) {
                        final isIncluded = config.multiCityIds.contains(city.id);
                        return FilterChip(
                          selected: isIncluded,
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(city.flagEmoji),
                              const SizedBox(width: 6),
                              Text(city.name),
                            ],
                          ),
                          selectedColor: AppColors.accent,
                          backgroundColor: AppColors.glassSurface,
                          side: BorderSide(
                            color: isIncluded ? AppColors.accentLight : AppColors.glassBorder,
                          ),
                          onSelected: (_) {
                            widgetState.toggleMultiCity(city.id, cities);
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            Divider(height: 1, color: AppColors.glassBorder),
            const SizedBox(height: 16),

            // Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GlassButton(
                  label: const Text('Done'),
                  isPrimary: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.glassSurface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.bodyBold),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.caption),
                ],
              ),
            ),
            Switch(
              value: value,
              activeThumbColor: AppColors.accentLight,
              activeTrackColor: AppColors.accent,
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}
