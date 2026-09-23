import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/time/time_formatter.dart';
import '../../../core/time/timezone_engine.dart';
import '../../../data/models/widget_configuration.dart';
import '../../../data/models/world_city.dart';
import 'analog_widget_preview.dart';

/// Pixel-perfect preview of the macOS Small Widget ($170 \times 170$).
class SmallWidgetPreview extends StatelessWidget {
  final WorldCity city;
  final WidgetConfiguration config;
  final DateTime nowUtc;

  const SmallWidgetPreview({
    super.key,
    required this.city,
    required this.config,
    required this.nowUtc,
  });

  @override
  Widget build(BuildContext context) {
    final localTime = TimezoneEngine.convertTo(nowUtc, city.timezoneId);
    final offsetStr = TimezoneEngine.getUtcOffsetString(city.timezoneId, nowUtc);
    final isDay = localTime.hour >= 6 && localTime.hour < 18;

    final timeStr = TimeFormatter.formatDigitalTime(
      localTime,
      is24Hour: config.is24Hour,
      showSeconds: config.showSeconds,
    );
    final amPm = TimeFormatter.getAmPm(localTime);
    final dateStr = TimeFormatter.formatMediumDate(localTime);

    return Container(
      width: 170,
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row: Flag, Name, Day/Night
          Row(
            children: [
              Text(city.flagEmoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  city.name,
                  style: const TextStyle(
                    fontSize: 13,
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
                  size: 11,
                  color: isDay ? AppColors.dayAmber : AppColors.nightIndigo,
                ),
              ],
            ],
          ),

          Text(
            city.country,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.55),
            ),
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          if (config.showAnalog) ...[
            Center(
              child: AnalogWidgetPreview(
                time: localTime,
                size: 38,
                isDay: isDay,
              ),
            ),
            const Spacer(),
          ],

          // Large Readable Digital Time
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  timeStr,
                  style: TextStyle(
                    fontSize: config.showAnalog ? 15 : 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                if (!config.is24Hour) ...[
                  const SizedBox(width: 4),
                  Text(
                    amPm,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentLight,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (config.showDate) ...[
            const SizedBox(height: 2),
            Text(
              dateStr,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.65),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],

          if (config.showUtcOffset) ...[
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
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
          ],
        ],
      ),
    );
  }
}
