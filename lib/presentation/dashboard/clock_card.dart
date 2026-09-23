import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/animation/app_animations.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/time/time_formatter.dart';
import '../../data/models/clock_card_data.dart';
import '../../state/clock_state.dart';
import '../../state/widget_state.dart';
import '../common/glass_container.dart';
import '../widgets/add_to_desktop_guide.dart';
import 'analog_clock_view.dart';

class ClockCard extends StatefulWidget {
  final ClockCardData data;
  final bool is24Hour;
  final bool showSeconds;
  final bool showAnalogClock;
  final VoidCallback onToggleFavorite;
  final VoidCallback onRemove;

  const ClockCard({
    super.key,
    required this.data,
    required this.is24Hour,
    required this.showSeconds,
    required this.showAnalogClock,
    required this.onToggleFavorite,
    required this.onRemove,
  });

  @override
  State<ClockCard> createState() => _ClockCardState();
}

class _ClockCardState extends State<ClockCard> with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _starController;
  late Animation<double> _starScale;

  @override
  void initState() {
    super.initState();
    _starController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _starScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35).chain(CurveTween(curve: Curves.easeOutCubic)), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 1.0).chain(CurveTween(curve: Curves.easeInCubic)), weight: 50),
    ]).animate(_starController);
  }

  @override
  void dispose() {
    _starController.dispose();
    super.dispose();
  }

  void _handleToggleFavorite() {
    _starController.forward(from: 0.0);
    widget.onToggleFavorite();
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final time = data.currentTime;
    final isDay = data.solarPosition.isDay;

    // Digital time formatting
    final digitalTimeString = TimeFormatter.formatDigitalTime(
      time,
      is24Hour: widget.is24Hour,
      showSeconds: false,
    );
    final secondsString = time.second.toString().padLeft(2, '0');
    final amPm = TimeFormatter.getAmPm(time);

    // Solar times
    final sunriseStr = TimeFormatter.formatSunTime(
      data.solarTimes.sunrise,
      is24Hour: widget.is24Hour,
    );
    final sunsetStr = TimeFormatter.formatSunTime(
      data.solarTimes.sunset,
      is24Hour: widget.is24Hour,
    );

    const analogSize = 56.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedSlide(
        duration: AppAnimations.fast,
        curve: AppAnimations.smooth,
        offset: Offset(0, _isHovered ? -0.015 : 0.0),
        child: GlassContainer(
          borderRadius: BorderRadius.circular(16),
          borderColor: data.isFavorite
              ? AppColors.glassBorderAccent
              : (_isHovered ? AppColors.glassBorderHighlight : AppColors.glassBorder),
          borderWidth: data.isFavorite ? 1.5 : 1.0,
          enableGlow: data.isFavorite || _isHovered,
          glowColor: data.isFavorite
              ? AppColors.accent.withValues(alpha: 0.22)
              : AppColors.accent.withValues(alpha: 0.10),
          shadows: _isHovered ? AppColors.glassShadowHover : AppColors.cardShadow,
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top Row: City Name, Flag & Action Icons
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              data.city.flagEmoji,
                              style: const TextStyle(fontSize: 16),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                data.city.name,
                                style: AppTypography.h2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (data.isDst) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.18),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: AppColors.accent.withValues(alpha: 0.35),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Text(
                                  'DST',
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
                        const SizedBox(height: 2),
                        Text(
                          data.city.country,
                          style: AppTypography.body.copyWith(
                            color: AppColors.textMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Widget, Favorite & Delete Actions with tactile feedback
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Builder(
                        builder: (context) {
                          final widgetState = context.watch<DesktopWidgetState?>();
                          final status = widgetState?.getStatusForCity(
                                data.city.id,
                                data.city.timezoneId,
                              ) ??
                              DesktopWidgetStatus.notConfigured;
                          final isConfigured =
                              status == DesktopWidgetStatus.configured;
                          final isPrepared =
                              status == DesktopWidgetStatus.prepared;

                          final Color iconColor;
                          final IconData iconData;
                          final String tooltipText;

                          if (isConfigured) {
                            iconColor = AppColors.success;
                            iconData = Icons.widgets_rounded;
                            tooltipText = '${data.city.name} placed on macOS Desktop';
                          } else if (isPrepared) {
                            iconColor = AppColors.accentLight;
                            iconData = Icons.widgets_rounded;
                            tooltipText = '${data.city.name} prepared for macOS Desktop Widget';
                          } else {
                            iconColor = AppColors.textMuted;
                            iconData = Icons.widgets_outlined;
                            tooltipText = 'Add ${data.city.name} Widget';
                          }

                          return IconButton(
                            icon: Icon(
                              iconData,
                              size: 18,
                              color: iconColor,
                            ),
                            tooltip: tooltipText,
                            splashRadius: 18,
                            hoverColor: AppColors.glassSurfaceHover,
                            onPressed: () async {
                              final ws = context.read<DesktopWidgetState?>();
                              final cs = context.read<ClockState?>();
                              if (ws != null && cs != null) {
                                await ws.setSingleCity(data.city.id, cs.cities);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          '${data.city.name} widget is ready.'),
                                      duration: const Duration(seconds: 4),
                                      action: SnackBarAction(
                                        label: 'Add to Desktop',
                                        onPressed: () {
                                          AddToDesktopGuideDialog.show(
                                            context,
                                            cityName: data.city.name,
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                          );
                        },
                      ),
                      ScaleTransition(
                        scale: _starScale,
                        child: IconButton(
                          icon: Icon(
                            data.isFavorite
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 20,
                            color: data.isFavorite
                                ? AppColors.dayAmber
                                : AppColors.textMuted,
                          ),
                          tooltip: data.isFavorite ? 'Unfavorite' : 'Pin to top',
                          splashRadius: 18,
                          onPressed: _handleToggleFavorite,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          size: 18,
                          color: AppColors.textMuted,
                        ),
                        tooltip: 'Remove',
                        splashRadius: 18,
                        hoverColor: AppColors.glassSurfaceHover,
                        onPressed: widget.onRemove,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Middle: Digital Time & Optional Analog Clock
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Digital Time Display with scale down protection
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                digitalTimeString,
                                style: AppTypography.clockLarge,
                              ),
                              if (widget.showSeconds) ...[
                                const SizedBox(width: 2),
                                Text(
                                  ':$secondsString',
                                  style: AppTypography.clockSeconds,
                                ),
                              ],
                              if (!widget.is24Hour) ...[
                                const SizedBox(width: 6),
                                Text(
                                  amPm,
                                  style: AppTypography.clockAmPm,
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Day of week & Full date
                        Text(
                          '${TimeFormatter.formatMediumDate(time)}, ${time.year}',
                          style: AppTypography.bodyBold.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                  if (widget.showAnalogClock) ...[
                    const SizedBox(width: 10),
                    AnalogClockView(
                      time: time,
                      size: analogSize,
                      isDay: isDay,
                      showSeconds: widget.showSeconds,
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 14),
              const Divider(height: 1, color: AppColors.glassBorder),
              const SizedBox(height: 12),

              // Bottom Badges: Day/Night, Difference from Local, UTC Offset
              Wrap(
                spacing: 6,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  // Day / Night Indicator Pill (Glass styled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDay
                          ? AppColors.dayAmberMuted
                          : AppColors.nightIndigoMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDay
                            ? AppColors.dayAmber.withValues(alpha: 0.35)
                            : AppColors.nightIndigo.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDay
                              ? Icons.wb_sunny_rounded
                              : Icons.nightlight_round,
                          size: 12,
                          color:
                              isDay ? AppColors.dayAmber : AppColors.nightIndigo,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.solarPosition.phase,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDay
                                ? AppColors.dayAmber
                                : AppColors.nightIndigo,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Difference from Local Time Pill (Glass styled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          data.timeDifference.isSame
                              ? Icons.check_circle_outline_rounded
                              : (data.timeDifference.isAhead
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded),
                          size: 11,
                          color: data.timeDifference.isSame
                              ? AppColors.workingHoursGreen
                              : (data.timeDifference.isAhead
                                  ? AppColors.accentLight
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          data.timeDifference.formatted,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: data.timeDifference.isSame
                                ? AppColors.workingHoursGreen
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Timezone Abbreviation & UTC Offset (Glass styled)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: AppColors.glassSurface,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Text(
                      '${data.tzAbbreviation} (${data.utcOffset})',
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Solar details: Sunrise & Sunset with Wrap for safe auto-break
              Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wb_twilight_rounded,
                        size: 13,
                        color: AppColors.dayAmber,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Rise $sunriseStr',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.nights_stay_outlined,
                        size: 13,
                        color: AppColors.nightIndigo,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Set $sunsetStr',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
