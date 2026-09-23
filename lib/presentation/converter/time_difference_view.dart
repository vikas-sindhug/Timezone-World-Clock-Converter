import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/time/time_formatter.dart';
import '../../core/time/timezone_engine.dart';
import '../../data/models/world_city.dart';
import '../../data/repositories/city_database.dart';
import '../../state/clock_state.dart';
import '../../state/settings_state.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';

class TimeDifferenceView extends StatefulWidget {
  const TimeDifferenceView({super.key});

  @override
  State<TimeDifferenceView> createState() => _TimeDifferenceViewState();
}

class _TimeDifferenceViewState extends State<TimeDifferenceView> {
  WorldCity _cityA = CityDatabase.findById('jaipur_in') ?? CityDatabase.allCities.first;
  WorldCity _cityB = CityDatabase.findById('new_york_us') ?? CityDatabase.allCities[1];

  void _showCityPicker(bool isA) {
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
                constraints: const BoxConstraints(maxWidth: 460, maxHeight: 520),
                child: GlassContainer(
                  borderRadius: BorderRadius.circular(18),
                  borderColor: AppColors.glassBorderHighlight,
                  borderWidth: 1.2,
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Text(isA ? 'Select City A' : 'Select City B', style: AppTypography.h2),
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
                          hintText: 'Search city...',
                          hintStyle: const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
                          filled: true,
                          fillColor: AppColors.surface,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: AppColors.border),
                          ),
                        ),
                        onChanged: (val) => setDialogState(() => filter = val),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.builder(
                          itemCount: cities.length,
                          itemBuilder: (context, index) {
                            final c = cities[index];
                            return ListTile(
                              leading: Text(c.flagEmoji, style: const TextStyle(fontSize: 20)),
                              title: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)),
                              subtitle: Text(
                                '${c.country} • ${TimezoneEngine.getUtcOffsetString(c.timezoneId)}',
                                style: AppTypography.caption,
                              ),
                              onTap: () {
                                setState(() {
                                  if (isA) {
                                    _cityA = c;
                                  } else {
                                    _cityB = c;
                                  }
                                });
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
    final clockState = context.watch<ClockState>();
    final settingsState = context.watch<SettingsState>();
    final nowUtc = clockState.currentUtcTime;

    final timeA = TimezoneEngine.convertTo(nowUtc, _cityA.timezoneId);
    final timeB = TimezoneEngine.convertTo(nowUtc, _cityB.timezoneId);

    final offsetA = TimezoneEngine.getUtcOffsetString(_cityA.timezoneId, nowUtc);
    final offsetB = TimezoneEngine.getUtcOffsetString(_cityB.timezoneId, nowUtc);

    final abbrA = TimezoneEngine.getTimezoneAbbreviation(_cityA.timezoneId, nowUtc);
    final abbrB = TimezoneEngine.getTimezoneAbbreviation(_cityB.timezoneId, nowUtc);

    final isDstA = TimezoneEngine.isDst(_cityA.timezoneId, nowUtc);
    final isDstB = TimezoneEngine.isDst(_cityB.timezoneId, nowUtc);

    final diff = TimezoneEngine.getTimeDifference(
      targetTimezoneId: _cityA.timezoneId,
      referenceTimezoneId: _cityB.timezoneId,
      referenceTime: nowUtc,
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(28, 24, 28, 36),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Text('Time Difference', style: AppTypography.h1),
            const SizedBox(height: 2),
            Text(
              'Dynamic offset and working hours comparison calculated from IANA timezone rules',
              style: AppTypography.caption,
            ),

            const SizedBox(height: 24),

            // Comparison Hero Cards (Responsive)
            LayoutBuilder(
              builder: (context, boxConstraints) {
                final isNarrow = boxConstraints.maxWidth < 960;

                final cardA = _ComparisonCityCard(
                  title: 'CITY A',
                  city: _cityA,
                  time: timeA,
                  offsetStr: offsetA,
                  abbr: abbrA,
                  isDst: isDstA,
                  is24Hour: settingsState.is24Hour,
                  showSeconds: settingsState.showSeconds,
                  onPickCity: () => _showCityPicker(true),
                );

                final diffBadge = ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 280),
                  child: GlassContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    borderRadius: BorderRadius.circular(16),
                    borderColor: AppColors.glassBorderAccent,
                    borderWidth: 1.2,
                    enableGlow: true,
                    glowColor: AppColors.accent.withValues(alpha: 0.22),
                    shadows: AppColors.glassShadowHover,
                    child: Column(
                      children: [
                        const Text(
                          'DIFFERENCE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: AppColors.accentLight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            diff.formatted,
                            style: AppTypography.h1.copyWith(
                              color: Colors.white,
                              fontSize: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          diff.isSame
                              ? 'Both cities are in the same time'
                              : '${_cityA.name} is ${diff.isAhead ? "ahead of" : "behind"} ${_cityB.name}',
                          style: AppTypography.caption,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );

                final cardB = _ComparisonCityCard(
                  title: 'CITY B',
                  city: _cityB,
                  time: timeB,
                  offsetStr: offsetB,
                  abbr: abbrB,
                  isDst: isDstB,
                  is24Hour: settingsState.is24Hour,
                  showSeconds: settingsState.showSeconds,
                  onPickCity: () => _showCityPicker(false),
                );

                if (isNarrow) {
                  return Column(
                    children: [
                      cardA,
                      const SizedBox(height: 12),
                      diffBadge,
                      const SizedBox(height: 12),
                      cardB,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: cardA),
                    const SizedBox(width: 16),
                    diffBadge,
                    const SizedBox(width: 16),
                    Expanded(child: cardB),
                  ],
                );
              },
            ),

            const SizedBox(height: 32),

            // 24-Hour Comparative Alignment Track
            Text(
              '24-Hour Alignment',
              style: AppTypography.h2,
            ),
            const SizedBox(height: 12),

            GlassContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(14),
              borderColor: AppColors.glassBorder,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CityAlignmentRow(city: _cityA, nowUtc: nowUtc),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: AppColors.glassBorder),
                  const SizedBox(height: 16),
                  _CityAlignmentRow(city: _cityB, nowUtc: nowUtc),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComparisonCityCard extends StatelessWidget {
  final String title;
  final WorldCity city;
  final DateTime time;
  final String offsetStr;
  final String abbr;
  final bool isDst;
  final bool is24Hour;
  final bool showSeconds;
  final VoidCallback onPickCity;

  const _ComparisonCityCard({
    required this.title,
    required this.city,
    required this.time,
    required this.offsetStr,
    required this.abbr,
    required this.isDst,
    required this.is24Hour,
    required this.showSeconds,
    required this.onPickCity,
  });

  @override
  Widget build(BuildContext context) {
    final timeStr = TimeFormatter.formatDigitalTime(
      time,
      is24Hour: is24Hour,
      showSeconds: showSeconds,
    );
    final amPm = TimeFormatter.getAmPm(time);

    return GlassContainer(
      padding: const EdgeInsets.all(22),
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.glassBorderHighlight,
      borderWidth: 1.2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.6,
                ),
              ),
              GlassButton(
                isPrimary: false,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                borderRadius: BorderRadius.circular(6),
                icon: const Icon(Icons.swap_vert_rounded, size: 14, color: AppColors.accentLight),
                label: const Text('Change', style: TextStyle(fontSize: 11, color: AppColors.accentLight, fontWeight: FontWeight.w600)),
                onPressed: onPickCity,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(city.flagEmoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  city.name,
                  style: AppTypography.h2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDst) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.accent.withValues(alpha: 0.35), width: 0.8),
                  ),
                  child: const Text(
                    'DST ACTIVE',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accentLight,
                    ),
                  ),
                ),
              ],
            ],
          ),
          Text(
            '${city.country} • $abbr ($offsetStr)',
            style: AppTypography.caption,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 18),
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
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            TimeFormatter.formatFullDate(time),
            style: AppTypography.caption,
          ),
        ],
      ),
    );
  }
}

class _CityAlignmentRow extends StatelessWidget {
  final WorldCity city;
  final DateTime nowUtc;

  const _CityAlignmentRow({required this.city, required this.nowUtc});

  @override
  Widget build(BuildContext context) {
    final localNow = TimezoneEngine.convertTo(nowUtc, city.timezoneId);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(city.flagEmoji, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(city.name, style: AppTypography.bodyBold),
            const SizedBox(width: 8),
            Text(
              '${localNow.hour.toString().padLeft(2, '0')}:${localNow.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                color: AppColors.accentLight,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 24 Hour blocks
        SizedBox(
          height: 28,
          child: Row(
            children: List.generate(24, (hour) {
              final isCurrent = hour == localNow.hour;
              final isWork = hour >= 9 && hour < 18;
              final isSleep = hour < 7 || hour >= 23;

              Color bg;
              if (isCurrent) {
                bg = AppColors.accent;
              } else if (isWork) {
                bg = AppColors.workingHoursGreenMuted;
              } else if (isSleep) {
                bg = AppColors.surfaceElevated;
              } else {
                bg = AppColors.nightIndigoMuted;
              }

              return Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(4),
                    border: isCurrent ? Border.all(color: Colors.white, width: 1.5) : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hour.toString(),
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w500,
                      color: isCurrent
                          ? Colors.white
                          : (isWork ? AppColors.workingHoursGreen : AppColors.textMuted),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
