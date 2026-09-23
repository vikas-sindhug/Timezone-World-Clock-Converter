import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/time/time_formatter.dart';
import '../../../core/time/timezone_engine.dart';
import '../../../data/models/widget_configuration.dart';
import '../../../data/models/world_city.dart';

/// Pixel-perfect preview of the macOS Large Multi-Clock Widget ($364 \times 382$).
class LargeWidgetPreview extends StatelessWidget {
  final List<WorldCity> cities;
  final WidgetConfiguration config;
  final DateTime nowUtc;
  final Function(WorldCity city)? onCityTap;

  const LargeWidgetPreview({
    super.key,
    required this.cities,
    required this.config,
    required this.nowUtc,
    this.onCityTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayCities = cities.take(6).toList();

    return Container(
      width: 364,
      height: 382,
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
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.public_rounded,
                size: 14,
                color: AppColors.accentLight,
              ),
              const SizedBox(width: 6),
              const Text(
                'WORLD CLOCK',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${displayCities.length} CITIES',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.accentLight,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 6),

          // City Rows
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayCities.length,
              separatorBuilder: (_, index) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final city = displayCities[index];
                final localTime = TimezoneEngine.convertTo(nowUtc, city.timezoneId);
                final offsetStr = TimezoneEngine.getUtcOffsetString(city.timezoneId, nowUtc);
                final isDay = localTime.hour >= 6 && localTime.hour < 18;

                final timeStr = TimeFormatter.formatDigitalTime(
                  localTime,
                  is24Hour: config.is24Hour,
                  showSeconds: false,
                );
                final amPm = TimeFormatter.getAmPm(localTime);

                return InkWell(
                  onTap: () => onCityTap?.call(city),
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.04),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(city.flagEmoji, style: const TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                city.name,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${city.country} • $offsetStr',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (config.showDayNight) ...[
                          Icon(
                            isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                            size: 12,
                            color: isDay ? AppColors.dayAmber : AppColors.nightIndigo,
                          ),
                          const SizedBox(width: 8),
                        ],
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                timeStr,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              if (!config.is24Hour) ...[
                                const SizedBox(width: 3),
                                Text(
                                  amPm,
                                  style: const TextStyle(
                                    fontSize: 9,
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
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
