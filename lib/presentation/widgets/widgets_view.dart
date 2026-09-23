import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/time/time_formatter.dart';
import '../../core/time/timezone_engine.dart';
import '../../state/clock_state.dart';
import '../../state/settings_state.dart';
import '../../state/widget_state.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';
import 'previews/large_widget_preview.dart';
import 'previews/medium_widget_preview.dart';
import 'previews/small_widget_preview.dart';
import 'widget_configure_sheet.dart';

/// Dedicated Widgets view managing available desktop widgets, options, and live previews.
class WidgetsView extends StatefulWidget {
  const WidgetsView({super.key});

  @override
  State<WidgetsView> createState() => _WidgetsViewState();
}

class _WidgetsViewState extends State<WidgetsView> {
  int _selectedPreviewTab = 0; // 0: Small, 1: Medium, 2: Large, 3: All

  @override
  Widget build(BuildContext context) {
    final clockState = context.watch<ClockState>();
    final widgetState = context.watch<DesktopWidgetState>();
    final settingsState = context.watch<SettingsState>();

    final cities = clockState.cities;
    final nowUtc = clockState.currentUtcTime;
    final config = widgetState.config;
    final refTz = clockState.effectiveReferenceTimezone;

    final selectedCity = widgetState.getSelectedCity(cities) ??
        (cities.isNotEmpty ? cities.first : null);
    final multiCities = widgetState.getMultiCities(cities);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                final leftInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('macOS Desktop Widgets', style: AppTypography.h1),
                    const SizedBox(height: 2),
                    Text(
                      'Live Apple WidgetKit desktop widgets powered by native macOS SwiftUI & App Groups',
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );

                final actionBtns = Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    GlassButton(
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: const Text('Configure Widgets'),
                      isPrimary: false,
                      onPressed: () => WidgetConfigureSheet.show(context),
                    ),
                    GlassButton(
                      icon: const Icon(Icons.sync_rounded, size: 16),
                      label: const Text('Sync Timelines'),
                      isPrimary: true,
                      onPressed: () async {
                        await widgetState.syncWithAvailableCities(cities);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Synchronized widget timelines with macOS WidgetKit'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftInfo,
                      const SizedBox(height: 12),
                      actionBtns,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: leftInfo),
                    const SizedBox(width: 16),
                    actionBtns,
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Live Preview Card & Size Switcher
            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(18),
              borderColor: AppColors.glassBorderHighlight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.visibility_outlined, size: 16, color: AppColors.accentLight),
                      const SizedBox(width: 8),
                      const Text('Live Widget Preview', style: AppTypography.bodyBold),
                      const Spacer(),
                      // Size tabs
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: AppColors.glassSurface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            _SizeTabItem(
                              label: 'Small',
                              isSelected: _selectedPreviewTab == 0,
                              onTap: () => setState(() => _selectedPreviewTab = 0),
                            ),
                            _SizeTabItem(
                              label: 'Medium',
                              isSelected: _selectedPreviewTab == 1,
                              onTap: () => setState(() => _selectedPreviewTab = 1),
                            ),
                            _SizeTabItem(
                              label: 'Large (Multi)',
                              isSelected: _selectedPreviewTab == 2,
                              onTap: () => setState(() => _selectedPreviewTab = 2),
                            ),
                            _SizeTabItem(
                              label: 'All',
                              isSelected: _selectedPreviewTab == 3,
                              onTap: () => setState(() => _selectedPreviewTab = 3),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (selectedCity == null)
                    Container(
                      padding: const EdgeInsets.all(24),
                      alignment: Alignment.center,
                      child: const Text('Add cities to your world clocks to preview desktop widgets'),
                    )
                  else
                    // Previews Container
                    Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_selectedPreviewTab == 0 || _selectedPreviewTab == 3) ...[
                                Column(
                                  children: [
                                    const Text('Small (170 × 170)', style: AppTypography.caption),
                                    const SizedBox(height: 8),
                                    SmallWidgetPreview(
                                      city: selectedCity,
                                      config: config,
                                      nowUtc: nowUtc,
                                    ),
                                  ],
                                ),
                                if (_selectedPreviewTab == 3) const SizedBox(width: 20),
                              ],

                              if (_selectedPreviewTab == 1 || _selectedPreviewTab == 3) ...[
                                Column(
                                  children: [
                                    const Text('Medium (364 × 170)', style: AppTypography.caption),
                                    const SizedBox(height: 8),
                                    MediumWidgetPreview(
                                      city: selectedCity,
                                      config: config,
                                      nowUtc: nowUtc,
                                      refTz: refTz,
                                    ),
                                  ],
                                ),
                                if (_selectedPreviewTab == 3) const SizedBox(width: 20),
                              ],

                              if (_selectedPreviewTab == 2 || _selectedPreviewTab == 3) ...[
                                Column(
                                  children: [
                                    const Text('Large (364 × 382)', style: AppTypography.caption),
                                    const SizedBox(height: 8),
                                    LargeWidgetPreview(
                                      cities: multiCities,
                                      config: config,
                                      nowUtc: nowUtc,
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Available Clocks List for Desktop Widgets
            Row(
              children: [
                const Icon(Icons.devices_rounded, size: 18, color: AppColors.accentLight),
                const SizedBox(width: 8),
                const Text('Available Desktop Widgets', style: AppTypography.h2),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${cities.length} Eligible',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentLight,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Select which clock appears on single-city desktop widgets or toggle inclusion in the multi-clock widget.',
              style: AppTypography.caption,
            ),

            const SizedBox(height: 14),

            // Clocks Grid / List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cities.length,
              itemBuilder: (context, index) {
                final city = cities[index];
                final isPrimary = widgetState.singleCityId == city.id;
                final isMulti = widgetState.multiCityIds.contains(city.id);

                final localTime = TimezoneEngine.convertTo(nowUtc, city.timezoneId);
                final offsetStr = TimezoneEngine.getUtcOffsetString(city.timezoneId, nowUtc);
                final timeStr = TimeFormatter.formatDigitalTime(
                  localTime,
                  is24Hour: settingsState.is24Hour,
                  showSeconds: false,
                );
                final amPm = TimeFormatter.getAmPm(localTime);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    borderRadius: BorderRadius.circular(14),
                    borderColor: isPrimary ? AppColors.accentLight : AppColors.glassBorder,
                    child: Row(
                      children: [
                        Text(city.flagEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(city.name, style: AppTypography.bodyBold),
                                  const SizedBox(width: 6),
                                  Text('• ${city.country}', style: AppTypography.caption),
                                  if (isPrimary) ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accent,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'PRIMARY WIDGET',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                  if (isMulti) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.glassAccent,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: AppColors.glassBorderAccent),
                                      ),
                                      child: const Text(
                                        'IN MULTI-CLOCK',
                                        style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.accentLight),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${city.timezoneId} • $offsetStr',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),

                        // Time
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              timeStr,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (!settingsState.is24Hour) ...[
                              const SizedBox(width: 4),
                              Text(amPm, style: AppTypography.caption.copyWith(color: AppColors.accentLight)),
                            ],
                          ],
                        ),

                        const SizedBox(width: 16),

                        // Actions
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GlassButton(
                              label: Text(isPrimary ? 'Active Primary' : 'Set as Primary'),
                              isPrimary: isPrimary,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              onPressed: () {
                                widgetState.setSingleCity(city.id, cities);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                isMulti ? Icons.library_add_check_rounded : Icons.library_add_rounded,
                                size: 18,
                                color: isMulti ? AppColors.accentLight : AppColors.textMuted,
                              ),
                              tooltip: isMulti ? 'Remove from Multi-Clock' : 'Add to Multi-Clock',
                              onPressed: () {
                                widgetState.toggleMultiCity(city.id, cities);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // macOS Native Usage Banner
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(14),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.apple_rounded, size: 20, color: AppColors.accentLight),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('How to Add to macOS Desktop', style: AppTypography.bodyBold),
                        SizedBox(height: 2),
                        Text(
                          'On macOS Sonoma (14.0+) or Sequoia (15.0+), right-click your desktop background, select "Edit Widgets...", find "WorldClock", and drag your preferred widget size directly onto the desktop.',
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SizeTabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _SizeTabItem({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
