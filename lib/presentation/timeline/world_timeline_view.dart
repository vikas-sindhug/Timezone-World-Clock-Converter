import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/time/time_formatter.dart';
import '../../core/time/timezone_engine.dart';
import '../../data/models/world_city.dart';
import '../../state/clock_state.dart';
import '../../state/settings_state.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';

class WorldTimelineView extends StatefulWidget {
  const WorldTimelineView({super.key});

  @override
  State<WorldTimelineView> createState() => _WorldTimelineViewState();
}

class _WorldTimelineViewState extends State<WorldTimelineView> {
  double _scrubHour = -1; // -1 means live time

  @override
  Widget build(BuildContext context) {
    final clockState = context.watch<ClockState>();
    final settingsState = context.watch<SettingsState>();
    final nowUtc = clockState.currentUtcTime;

    // Use either scrubbed UTC time or live UTC time
    DateTime activeUtc;
    if (_scrubHour >= 0) {
      final h = _scrubHour.floor();
      final m = ((_scrubHour - h) * 60).round();
      activeUtc = DateTime.utc(nowUtc.year, nowUtc.month, nowUtc.day, h, m, 0);
    } else {
      activeUtc = nowUtc;
    }

    final isLive = _scrubHour < 0;

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
                    const Text('World Time Timeline', style: AppTypography.h1),
                    const SizedBox(height: 2),
                    Text(
                      'Comparative daylight spectrum and daylight phases across global cities',
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
                final rightWidget = !isLive
                    ? GlassButton(
                        icon: const Icon(Icons.play_arrow_rounded, size: 16),
                        label: const Text('Return to Live Time'),
                        isPrimary: true,
                        onPressed: () => setState(() => _scrubHour = -1),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.workingHoursGreenMuted,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.workingHoursGreen.withValues(alpha: 0.4)),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.workingHoursGreen.withValues(alpha: 0.15),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.fiber_manual_record, size: 10, color: AppColors.workingHoursGreen),
                            SizedBox(width: 6),
                            Text(
                              'LIVE TICKING',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.workingHoursGreen,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftInfo,
                      const SizedBox(height: 12),
                      rightWidget,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: leftInfo),
                    const SizedBox(width: 16),
                    rightWidget,
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Scrubber Bar
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              borderColor: AppColors.glassBorderHighlight,
              child: Row(
                children: [
                  const Text('Scrub Timeline (UTC): ', style: AppTypography.caption),
                  const SizedBox(width: 8),
                  Text(
                    '${activeUtc.hour.toString().padLeft(2, '0')}:${activeUtc.minute.toString().padLeft(2, '0')} UTC',
                    style: AppTypography.bodyBold.copyWith(color: AppColors.accentLight),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.accent,
                        inactiveTrackColor: AppColors.glassSurfaceHover,
                        thumbColor: Colors.white,
                        trackHeight: 4,
                      ),
                      child: Slider(
                        value: _scrubHour >= 0
                            ? _scrubHour
                            : (nowUtc.hour + nowUtc.minute / 60.0),
                        min: 0.0,
                        max: 23.99,
                        onChanged: (val) {
                          setState(() => _scrubHour = val);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Daylight Spectrum Legend
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _PhaseLegend(color: const Color(0xFF1E1B4B), label: 'Night (21-06)'),
                _PhaseLegend(color: const Color(0xFFB45309), label: 'Morning (06-12)'),
                _PhaseLegend(color: const Color(0xFF047857), label: 'Afternoon (12-17)'),
                _PhaseLegend(color: const Color(0xFF4338CA), label: 'Evening (17-21)'),
              ],
            ),

            const SizedBox(height: 16),

            // Timeline Tracks List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: clockState.cities.length,
              itemBuilder: (context, index) {
                final city = clockState.cities[index];
                return _CityTimelineTrack(
                  city: city,
                  utcTime: activeUtc,
                  is24Hour: settingsState.is24Hour,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CityTimelineTrack extends StatelessWidget {
  final WorldCity city;
  final DateTime utcTime;
  final bool is24Hour;

  const _CityTimelineTrack({
    required this.city,
    required this.utcTime,
    required this.is24Hour,
  });

  String _getPhase(int hour) {
    if (hour >= 6 && hour < 12) return 'Morning';
    if (hour >= 12 && hour < 17) return 'Afternoon';
    if (hour >= 17 && hour < 21) return 'Evening';
    return 'Night';
  }

  Color _getPhaseColor(int hour) {
    if (hour >= 6 && hour < 12) return const Color(0xFFB45309);
    if (hour >= 12 && hour < 17) return const Color(0xFF047857);
    if (hour >= 17 && hour < 21) return const Color(0xFF4338CA);
    return const Color(0xFF1E1B4B);
  }

  @override
  Widget build(BuildContext context) {
    final localTime = TimezoneEngine.convertTo(utcTime, city.timezoneId);
    final offsetStr = TimezoneEngine.getUtcOffsetString(city.timezoneId, utcTime);
    final timeStr = TimeFormatter.formatDigitalTime(
      localTime,
      is24Hour: is24Hour,
      showSeconds: false,
    );
    final amPm = TimeFormatter.getAmPm(localTime);
    final phase = _getPhase(localTime.hour);
    final phaseColor = _getPhaseColor(localTime.hour);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(city.flagEmoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    city.name,
                    style: AppTypography.h3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${city.country} • $offsetStr',
                    style: AppTypography.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                const Spacer(),
                // Phase Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: phaseColor.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: phaseColor.withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    phase,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Row(
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
                    if (!is24Hour) ...[
                      const SizedBox(width: 4),
                      Text(amPm, style: AppTypography.caption.copyWith(color: AppColors.accentLight)),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 24 Hour Daylight Spectrum Ribbon
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                height: 20,
                child: Row(
                  children: List.generate(24, (hour) {
                    final isCurrent = hour == localTime.hour;
                    final cellColor = _getPhaseColor(hour);

                    return Expanded(
                      child: Container(
                        color: isCurrent ? AppColors.accentLight : cellColor.withValues(alpha: 0.5),
                        alignment: Alignment.center,
                        child: isCurrent
                            ? Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseLegend extends StatelessWidget {
  final Color color;
  final String label;

  const _PhaseLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
