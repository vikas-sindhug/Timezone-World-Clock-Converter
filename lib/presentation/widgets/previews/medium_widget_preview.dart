import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/time/time_formatter.dart';
import '../../../core/time/timezone_engine.dart';
import '../../../data/models/widget_configuration.dart';
import '../../../data/models/world_city.dart';
import 'analog_widget_preview.dart';

/// Pixel-perfect preview of the macOS Medium Widget ($364 \times 170$).
class MediumWidgetPreview extends StatelessWidget {
  final WorldCity city;
  final WidgetConfiguration config;
  final DateTime nowUtc;
  final String refTz;

  const MediumWidgetPreview({
    super.key,
    required this.city,
    required this.config,
    required this.nowUtc,
    required this.refTz,
  });

  @override
  Widget build(BuildContext context) {
    final localTime = TimezoneEngine.convertTo(nowUtc, city.timezoneId);
    final offsetStr = TimezoneEngine.getUtcOffsetString(city.timezoneId, nowUtc);
    final diff = TimezoneEngine.getTimeDifference(
      targetTimezoneId: city.timezoneId,
      referenceTimezoneId: refTz,
      referenceTime: nowUtc,
    );
    final diffStr = diff.formatted;
    final isDay = localTime.hour >= 6 && localTime.hour < 18;

    final timeStr = TimeFormatter.formatDigitalTime(
      localTime,
      is24Hour: config.is24Hour,
      showSeconds: config.showSeconds,
    );
    final amPm = TimeFormatter.getAmPm(localTime);
    final fullDateStr = TimeFormatter.formatFullDate(localTime);

    return Container(
      width: 364,
      height: 170,
      decoration: BoxDecoration(
        color: const Color(0xFF131722).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Left Column
          Expanded(
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (config.showDayNight) ...[
                      const SizedBox(width: 4),
                      Icon(
                        isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                        size: 13,
                        color: isDay ? AppColors.dayAmber : AppColors.nightIndigo,
                      ),
                    ],
                  ],
                ),
                Text(
                  city.country,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.55),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),

                const Spacer(),

                if (config.showDate) ...[
                  Text(
                    fullDateStr,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                ],

                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (config.showUtcOffset)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          offsetStr,
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentLight,
                          ),
                        ),
                      ),
                    if (config.showDifferenceFromLocal)
                      Text(
                        diffStr,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 14),

          // Right Column: Analog clock or large digital time
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (config.showAnalog) ...[
                AnalogWidgetPreview(
                  time: localTime,
                  size: 64,
                  isDay: isDay,
                ),
                const SizedBox(height: 8),
              ],
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      timeStr,
                      style: TextStyle(
                        fontSize: config.showAnalog ? 18 : 28,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                    ),
                    if (!config.is24Hour) ...[
                      const SizedBox(width: 4),
                      Text(
                        amPm,
                        style: TextStyle(
                          fontSize: config.showAnalog ? 11 : 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
