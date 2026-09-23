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
import '../../state/meeting_planner_state.dart';
import '../../state/settings_state.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';

class MeetingPlannerView extends StatefulWidget {
  const MeetingPlannerView({super.key});

  @override
  State<MeetingPlannerView> createState() => _MeetingPlannerViewState();
}

class _MeetingPlannerViewState extends State<MeetingPlannerView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final clockState = context.read<ClockState>();
      context.read<MeetingPlannerState>().initializeWithDefaults(clockState.cities);
    });
  }

  void _showAddParticipantDialog(MeetingPlannerState planner) {
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
                          const Text('Add Participant City', style: AppTypography.h2),
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
                          hintText: 'Search participant city...',
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
                            final isAdded = planner.participants.any((p) => p.id == c.id);
                            return ListTile(
                              leading: Text(c.flagEmoji, style: const TextStyle(fontSize: 20)),
                              title: Text(c.name, style: const TextStyle(color: AppColors.textPrimary)),
                              subtitle: Text(
                                '${c.country} • ${TimezoneEngine.getUtcOffsetString(c.timezoneId)}',
                                style: AppTypography.caption,
                              ),
                              trailing: isAdded
                                  ? const Text('Added', style: TextStyle(color: AppColors.textMuted, fontSize: 12))
                                  : null,
                              onTap: isAdded
                                  ? null
                                  : () {
                                      planner.addParticipant(c);
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
    final planner = context.watch<MeetingPlannerState>();
    final clockState = context.watch<ClockState>();
    final settingsState = context.watch<SettingsState>();
    final refTz = clockState.effectiveReferenceTimezone;

    final startHour = planner.startHour;
    final duration = planner.durationHours;
    final endHour = startHour + duration;

    final overlaps = planner.findBestOverlaps(refTz);

    final startHInt = startHour.floor();
    final startMInt = ((startHour - startHInt) * 60).round();
    final endHInt = endHour.floor();
    final endMInt = ((endHour - endHInt) * 60).round();

    final timeWindowLabel =
        '${startHInt.toString().padLeft(2, '0')}:${startMInt.toString().padLeft(2, '0')} - '
        '${endHInt.toString().padLeft(2, '0')}:${endMInt.toString().padLeft(2, '0')} ($refTz)';

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
                    const Text('Global Meeting Planner', style: AppTypography.h1),
                    const SizedBox(height: 2),
                    Text(
                      'Find the optimal meeting time across distributed global teams',
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );
                final addBtn = GlassButton(
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                  label: const Text('Add Participant'),
                  isPrimary: true,
                  onPressed: () => _showAddParticipantDialog(planner),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftInfo,
                      const SizedBox(height: 12),
                      addBtn,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: leftInfo),
                    const SizedBox(width: 16),
                    addBtn,
                  ],
                );
              },
            ),

            const SizedBox(height: 20),

            // Top Status & Meeting Controls Bar
            GlassContainer(
              padding: const EdgeInsets.all(18),
              borderRadius: BorderRadius.circular(16),
              borderColor: AppColors.glassBorderHighlight,
              child: Column(
                children: [
                  Wrap(
                    spacing: 16,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Meeting Time Window Highlight
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.glassAccent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.glassBorderAccent),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.access_time_rounded, size: 16, color: AppColors.accentLight),
                            const SizedBox(width: 8),
                            Text(
                              timeWindowLabel,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentLight,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Duration Selector
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Duration:', style: AppTypography.body),
                          const SizedBox(width: 8),
                          for (final d in [0.5, 1.0, 1.5, 2.0]) ...[
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(d == 0.5 ? '30m' : '${d.toStringAsFixed(d.truncateToDouble() == d ? 0 : 1)}h'),
                                selected: duration == d,
                                labelStyle: TextStyle(
                                  fontSize: 11,
                                  color: duration == d ? Colors.white : AppColors.textSecondary,
                                  fontWeight: duration == d ? FontWeight.w700 : FontWeight.w500,
                                ),
                                selectedColor: AppColors.accent,
                                backgroundColor: AppColors.glassSurface,
                                side: BorderSide(color: duration == d ? AppColors.accent : AppColors.glassBorder),
                                onSelected: (_) => planner.setDuration(d),
                              ),
                            ),
                          ],
                        ],
                      ),

                      // Date Picker Button
                      InkWell(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: planner.meetingDate,
                            firstDate: DateTime.now().subtract(const Duration(days: 30)),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                          );
                          if (picked != null) planner.setMeetingDate(picked);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: AppColors.glassSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('EEE, MMM d, y').format(planner.meetingDate),
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Draggable Start Time Slider
                  Row(
                    children: [
                      const Text('Drag Start Time: ', style: AppTypography.caption),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.accent,
                            inactiveTrackColor: AppColors.glassSurfaceHover,
                            thumbColor: Colors.white,
                            trackHeight: 6,
                          ),
                          child: Slider(
                            value: startHour,
                            min: 0.0,
                            max: 24.0 - duration,
                            divisions: ((24.0 - duration) * 2).round(), // 30 min steps
                            onChanged: (val) => planner.setStartHour(val),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Smart "Best Overlap" Recommendations Panel
            GlassContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.dayAmber),
                      SizedBox(width: 8),
                      Text(
                        'Smart Overlap Recommendations (click to apply)',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: overlaps.map((rec) {
                      final isSelected = (planner.startHour - rec.startHour).abs() < 0.1;
                      return InkWell(
                        onTap: () => planner.setStartHour(rec.startHour),
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.accent : AppColors.glassSurface,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.accentLight : AppColors.glassBorder,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 14,
                                color: isSelected ? Colors.white : AppColors.workingHoursGreen,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                rec.label,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Timeline Legend
            Wrap(
              spacing: 14,
              runSpacing: 8,
              children: [
                _LegendDot(color: AppColors.workingHoursGreen, label: 'Working (9 AM - 6 PM)'),
                _LegendDot(color: AppColors.accent, label: 'Selected Meeting'),
                _LegendDot(color: AppColors.dayAmber, label: 'Early Morning (7-9 AM)'),
                _LegendDot(color: AppColors.nightIndigo, label: 'Evening (6-11 PM)'),
                _LegendDot(color: AppColors.surfaceElevated, label: 'Sleeping (11 PM - 7 AM)'),
              ],
            ),

            const SizedBox(height: 16),

            // 24-Hour Column Headers (12 AM, 3 AM, 6 AM, 9 AM, 12 PM, 3 PM, 6 PM, 9 PM)
            Padding(
              padding: const EdgeInsets.only(left: 200, right: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('12 AM', style: AppTypography.caption),
                  Text('3 AM', style: AppTypography.caption),
                  Text('6 AM', style: AppTypography.caption),
                  Text('9 AM', style: AppTypography.caption),
                  Text('12 PM', style: AppTypography.caption),
                  Text('3 PM', style: AppTypography.caption),
                  Text('6 PM', style: AppTypography.caption),
                  Text('9 PM', style: AppTypography.caption),
                  Text('12 AM', style: AppTypography.caption),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Horizontal Participant Tracks
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: planner.participants.length,
              itemBuilder: (context, index) {
                final city = planner.participants[index];
                return _ParticipantTimelineTrack(
                  city: city,
                  planner: planner,
                  refTz: refTz,
                  is24Hour: settingsState.is24Hour,
                  onRemove: () => planner.removeParticipant(city.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _ParticipantTimelineTrack extends StatelessWidget {
  final WorldCity city;
  final MeetingPlannerState planner;
  final String refTz;
  final bool is24Hour;
  final VoidCallback onRemove;

  const _ParticipantTimelineTrack({
    required this.city,
    required this.planner,
    required this.refTz,
    required this.is24Hour,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final meetingTime = planner.getParticipantMeetingTime(city, refTz);
    final offsetStr = TimezoneEngine.getUtcOffsetString(city.timezoneId, meetingTime);
    final timeStr = TimeFormatter.formatDigitalTime(
      meetingTime,
      is24Hour: is24Hour,
      showSeconds: false,
    );
    final amPm = TimeFormatter.getAmPm(meetingTime);
    final status = MeetingPlannerState.getHourStatus(meetingTime.hour);

    Color statusColor;
    String statusLabel;
    switch (status) {
      case HourStatus.working:
        statusColor = AppColors.workingHoursGreen;
        statusLabel = 'Working Hours';
        break;
      case HourStatus.earlyMorning:
        statusColor = AppColors.dayAmber;
        statusLabel = 'Early Morning';
        break;
      case HourStatus.evening:
        statusColor = AppColors.nightIndigo;
        statusLabel = 'Evening';
        break;
      case HourStatus.sleeping:
        statusColor = AppColors.textMuted;
        statusLabel = 'Sleeping Hours';
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassContainer(
        padding: const EdgeInsets.all(14),
        borderRadius: BorderRadius.circular(14),
        child: Row(
          children: [
            // City Info & Local Meeting Time
            SizedBox(
              width: 200,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(city.flagEmoji, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          city.name,
                          style: AppTypography.bodyBold,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14, color: AppColors.textMuted),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: onRemove,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          timeStr,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (!is24Hour) ...[
                          const SizedBox(width: 3),
                          Text(amPm, style: const TextStyle(fontSize: 10, color: AppColors.accentLight)),
                        ],
                        const SizedBox(width: 6),
                        Text(
                          offsetStr,
                          style: AppTypography.caption,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // 24 Hour Visual Horizontal Strip
            Expanded(
              child: SizedBox(
                height: 38,
                child: Row(
                  children: List.generate(24, (refHour) {
                    // Find what local hour this corresponds to
                    final refDt = DateTime(
                      planner.meetingDate.year,
                      planner.meetingDate.month,
                      planner.meetingDate.day,
                      refHour,
                    );
                    final refUtc = TimezoneEngine.convertTo(refDt, refTz).toUtc();
                    final localTzDt = TimezoneEngine.convertTo(refUtc, city.timezoneId);
                    final localH = localTzDt.hour;
                    final localStatus = MeetingPlannerState.getHourStatus(localH);

                    final isMeetingSlot =
                        refHour >= planner.startHour.floor() &&
                        refHour < (planner.startHour + planner.durationHours).ceil();

                    Color cellColor;
                    if (isMeetingSlot) {
                      cellColor = AppColors.accent;
                    } else {
                      switch (localStatus) {
                        case HourStatus.working:
                          cellColor = AppColors.workingHoursGreen.withValues(alpha: 0.28);
                          break;
                        case HourStatus.earlyMorning:
                          cellColor = AppColors.dayAmber.withValues(alpha: 0.28);
                          break;
                        case HourStatus.evening:
                          cellColor = AppColors.nightIndigo.withValues(alpha: 0.28);
                          break;
                        case HourStatus.sleeping:
                          cellColor = AppColors.glassSurface;
                          break;
                      }
                    }

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color: cellColor,
                          borderRadius: BorderRadius.circular(4),
                          border: isMeetingSlot
                              ? Border.all(color: Colors.white, width: 1.2)
                              : Border.all(color: Colors.white.withValues(alpha: 0.05), width: 0.5),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          localH.toString(),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: isMeetingSlot ? FontWeight.w700 : FontWeight.w500,
                            color: isMeetingSlot
                                ? Colors.white
                                : (localStatus == HourStatus.working
                                    ? AppColors.workingHoursGreen
                                    : AppColors.textMuted),
                          ),
                        ),
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

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: AppTypography.caption),
      ],
    );
  }
}
