import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/time/time_formatter.dart';
import '../../core/time/timezone_engine.dart';
import '../../data/models/world_city.dart';
import '../../data/repositories/city_database.dart';
import '../../state/clock_state.dart';
import '../../state/converter_state.dart';
import '../../state/settings_state.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';

class TimeConverterView extends StatefulWidget {
  const TimeConverterView({super.key});

  @override
  State<TimeConverterView> createState() => _TimeConverterViewState();
}

class _TimeConverterViewState extends State<TimeConverterView>
    with SingleTickerProviderStateMixin {
  late AnimationController _swapAnimController;

  @override
  void initState() {
    super.initState();
    _swapAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _swapAnimController.dispose();
    super.dispose();
  }

  void _handleSwap(ConverterState converter) {
    _swapAnimController.forward(from: 0.0);
    converter.swap();
  }

  Future<void> _selectDate(BuildContext context, ConverterState converter) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: converter.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surfaceElevated,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      converter.setDate(picked);
    }
  }

  void _showCityPicker(
    BuildContext context, {
    required WorldCity current,
    required ValueChanged<WorldCity> onSelected,
  }) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) {
        String filter = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cities = CityDatabase.search(filter);
            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480, maxHeight: 560),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(18),
                  borderColor: AppColors.glassBorderHighlight,
                  borderWidth: 1.2,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Text('Select City', style: AppTypography.h2),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        autofocus: true,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: InputDecoration(
                          hintText: 'Search city or timezone...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onChanged: (val) {
                          setDialogState(() => filter = val);
                        },
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: cities.length,
                          itemBuilder: (context, index) {
                            final c = cities[index];
                            final isCur = c.id == current.id;
                            final offset = TimezoneEngine.getUtcOffsetString(c.timezoneId);
                            return ListTile(
                              leading: Text(c.flagEmoji, style: const TextStyle(fontSize: 20)),
                              title: Text(
                                c.name,
                                style: TextStyle(
                                  color: isCur ? AppColors.accentLight : AppColors.textPrimary,
                                  fontWeight: isCur ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              subtitle: Text(
                                '${c.country} • $offset',
                                style: AppTypography.caption,
                              ),
                              trailing: isCur
                                  ? const Icon(Icons.check, color: AppColors.accentLight, size: 18)
                                  : null,
                              onTap: () {
                                onSelected(c);
                                Navigator.of(context).pop();
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final converter = context.watch<ConverterState>();
    final clockState = context.watch<ClockState>();
    final settingsState = context.watch<SettingsState>();

    final srcTime = converter.sourceTzDateTime;
    final tgtTime = converter.targetTzDateTime;
    final dayDiff = converter.dayDifference;
    final diff = converter.timeDifference;

    final fromOffset = TimezoneEngine.getUtcOffsetString(converter.fromCity.timezoneId, srcTime);
    final toOffset = TimezoneEngine.getUtcOffsetString(converter.toCity.timezoneId, tgtTime);

    final multiResults = converter.convertToMultiple(clockState.cities);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 650;
                final leftInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Timezone Converter', style: AppTypography.h1),
                    const SizedBox(height: 2),
                    Text(
                      'Convert any date and time across global IANA timezones with DST accuracy',
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
                final resetBtn = GlassButton(
                  isPrimary: false,
                  icon: const Icon(Icons.restore_rounded, size: 16, color: AppColors.textSecondary),
                  label: const Text('Reset to Now', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  onPressed: () => converter.initializeWithLocal(TimezoneEngine.localTimezoneId),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftInfo,
                      const SizedBox(height: 12),
                      resetBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: leftInfo),
                    const SizedBox(width: 16),
                    resetBtn,
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            // Main 2-Way Conversion Interactive Panel
            GlassContainer(
              padding: const EdgeInsets.all(24),
              borderRadius: BorderRadius.circular(16),
              borderColor: AppColors.glassBorderHighlight,
              borderWidth: 1.2,
              child: LayoutBuilder(
                builder: (context, boxConstraints) {
                  final isNarrow = boxConstraints.maxWidth < 680;

                  final fromCard = _CityConversionSelectorCard(
                    label: 'FROM',
                    city: converter.fromCity,
                    time: srcTime,
                    offsetStr: fromOffset,
                    is24Hour: settingsState.is24Hour,
                    onPickCity: () => _showCityPicker(
                      context,
                      current: converter.fromCity,
                      onSelected: converter.setFromCity,
                    ),
                  );

                  final swapBtn = RotationTransition(
                    turns: Tween(begin: 0.0, end: 0.5).animate(
                      CurvedAnimation(
                        parent: _swapAnimController,
                        curve: Curves.easeInOutBack,
                      ),
                    ),
                    child: GlassContainer(
                      borderRadius: BorderRadius.circular(24),
                      borderColor: AppColors.glassBorderAccent,
                      padding: const EdgeInsets.all(2),
                      child: IconButton(
                        icon: const Icon(Icons.swap_horiz_rounded),
                        color: AppColors.accentLight,
                        iconSize: 22,
                        tooltip: 'Swap locations',
                        onPressed: () => _handleSwap(converter),
                      ),
                    ),
                  );

                  final toCard = _CityConversionSelectorCard(
                    label: 'TO',
                    city: converter.toCity,
                    time: tgtTime,
                    offsetStr: toOffset,
                    is24Hour: settingsState.is24Hour,
                    dayDifference: dayDiff,
                    onPickCity: () => _showCityPicker(
                      context,
                      current: converter.toCity,
                      onSelected: converter.setToCity,
                    ),
                  );

                  final dateSelector = InkWell(
                    onTap: () => _selectDate(context, converter),
                    borderRadius: BorderRadius.circular(10),
                    child: GlassContainer(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      borderRadius: BorderRadius.circular(10),
                      borderColor: AppColors.glassBorder,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.accentLight),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMM d, y').format(converter.selectedDate),
                            style: AppTypography.bodyBold,
                          ),
                        ],
                      ),
                    ),
                  );

                  final timeSlider = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Adjust Time: ${converter.selectedHour.toString().padLeft(2, '0')}:${converter.selectedMinute.toString().padLeft(2, '0')}',
                            style: AppTypography.caption.copyWith(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            diff.formatted,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: diff.isAhead ? AppColors.accentLight : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: AppColors.accent,
                          inactiveTrackColor: AppColors.surfaceElevated,
                          thumbColor: Colors.white,
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: converter.selectedHour + (converter.selectedMinute / 60.0),
                          min: 0.0,
                          max: 23.75,
                          divisions: 95, // 15-minute increments
                          onChanged: (val) {
                            final h = val.floor();
                            final m = ((val - h) * 60).round();
                            converter.setTime(h, m);
                          },
                        ),
                      ),
                    ],
                  );

                  return Column(
                    children: [
                      if (isNarrow) ...[
                        fromCard,
                        const SizedBox(height: 8),
                        Center(child: swapBtn),
                        const SizedBox(height: 8),
                        toCard,
                      ] else ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(child: fromCard),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              child: swapBtn,
                            ),
                            Expanded(child: toCard),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),
                      const Divider(height: 1, color: AppColors.glassBorder),
                      const SizedBox(height: 20),
                      if (isNarrow) ...[
                        dateSelector,
                        const SizedBox(height: 16),
                        timeSlider,
                      ] else ...[
                        Row(
                          children: [
                            dateSelector,
                            const SizedBox(width: 20),
                            Expanded(child: timeSlider),
                          ],
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Multi-city Conversion Table
            Row(
              children: [
                const Icon(Icons.view_list_rounded, size: 18, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  'Converted Across Monitored Cities (${multiResults.length})',
                  style: AppTypography.h2,
                ),
              ],
            ),
            const SizedBox(height: 12),

            GlassContainer(
              borderRadius: BorderRadius.circular(14),
              borderColor: AppColors.glassBorder,
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: multiResults.length,
                separatorBuilder: (context, index) => const Divider(
                  height: 1,
                  indent: 60,
                  color: AppColors.glassBorder,
                ),
                itemBuilder: (context, index) {
                  final item = multiResults[index];
                  final timeStr = TimeFormatter.formatDigitalTime(
                    item.localTime,
                    is24Hour: settingsState.is24Hour,
                    showSeconds: false,
                  );
                  final amPm = TimeFormatter.getAmPm(item.localTime);
                  final dateStr = TimeFormatter.formatMediumDate(item.localTime);

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Text(item.city.flagEmoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.city.name, style: AppTypography.bodyBold),
                              Text(
                                '${item.city.country} • ${item.offsetString}',
                                style: AppTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        if (item.dayDifference != 0) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.glassSurface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppColors.glassBorder),
                            ),
                            child: Text(
                              item.dayDifference > 0 ? '+${item.dayDifference}d' : '${item.dayDifference}d',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: item.dayDifference > 0 ? AppColors.accentLight : AppColors.dayAmber,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Row(
                              children: [
                                Text(timeStr, style: AppTypography.clockMedium.copyWith(fontSize: 20)),
                                if (!settingsState.is24Hour) ...[
                                  const SizedBox(width: 4),
                                  Text(amPm, style: AppTypography.caption.copyWith(color: AppColors.accentLight)),
                                ],
                              ],
                            ),
                            Text(dateStr, style: AppTypography.caption),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CityConversionSelectorCard extends StatelessWidget {
  final String label;
  final WorldCity city;
  final DateTime time;
  final String offsetStr;
  final bool is24Hour;
  final int? dayDifference;
  final VoidCallback onPickCity;

  const _CityConversionSelectorCard({
    required this.label,
    required this.city,
    required this.time,
    required this.offsetStr,
    required this.is24Hour,
    this.dayDifference,
    required this.onPickCity,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = TimeFormatter.formatDigitalTime(
      time,
      is24Hour: is24Hour,
      showSeconds: false,
    );
    final amPm = TimeFormatter.getAmPm(time);

    return GlassContainer(
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(12),
      borderColor: AppColors.glassBorder,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.glassAccent.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.glassBorderAccent, width: 0.8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentLight,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(),
              InkWell(
                onTap: onPickCity,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    children: const [
                      Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.accentLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Icon(Icons.chevron_right, size: 14, color: AppColors.accentLight),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(city.flagEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      city.name,
                      style: AppTypography.h2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${city.country} • $offsetStr',
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(timeStr, style: AppTypography.clockLarge),
                if (!is24Hour) ...[
                  const SizedBox(width: 6),
                  Text(amPm, style: AppTypography.clockAmPm),
                ],
                if (dayDifference != null && dayDifference != 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: dayDifference! > 0 ? AppColors.accentMuted : AppColors.dayAmberMuted,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      dayDifference! > 0 ? 'Next Day (+1)' : 'Prev Day (-1)',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: dayDifference! > 0 ? AppColors.accentLight : AppColors.dayAmber,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('EEEE, MMMM d, y').format(time),
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}
