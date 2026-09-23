import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_typography.dart';
import '../../core/solar/solar_calculator.dart';
import '../../core/time/time_formatter.dart';
import '../../core/time/timezone_engine.dart';
import '../../data/models/world_city.dart';
import '../../data/repositories/city_database.dart';
import '../../state/clock_state.dart';
import '../../state/settings_state.dart';
import '../common/glass_button.dart';
import '../common/glass_container.dart';
import 'map_painter.dart';

class WorldMapView extends StatefulWidget {
  const WorldMapView({super.key});

  @override
  State<WorldMapView> createState() => _WorldMapViewState();
}

class _WorldMapViewState extends State<WorldMapView> {
  WorldCity? _selectedCity;

  @override
  void initState() {
    super.initState();
    _selectedCity = CityDatabase.findById('tokyo_jp');
  }

  void _onTapUp(TapUpDetails details, Size mapSize) {
    // Find closest city to tap position
    final localPos = details.localPosition;
    double closestDist = 28.0; // hit test radius in pixels
    WorldCity? found;

    for (final city in CityDatabase.allCities) {
      final cityOffset = WorldMapPainter.latLonToOffset(
        city.latitude,
        city.longitude,
        mapSize,
      );
      final dist = (cityOffset - localPos).distance;
      if (dist < closestDist) {
        closestDist = dist;
        found = city;
      }
    }

    if (found != null) {
      setState(() => _selectedCity = found);
    }
  }

  @override
  Widget build(BuildContext context) {
    final clockState = context.watch<ClockState>();
    final settingsState = context.watch<SettingsState>();
    final nowUtc = clockState.currentUtcTime;
    final savedIds = clockState.cities.map((c) => c.id).toSet();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(28, 24, 28, 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 750;
                final leftInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Global Timezone Map',
                      style: AppTypography.h1,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Live solar day/night boundary with real-time solar terminator',
                      style: AppTypography.caption,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                );

                final legend = GlassContainer(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  borderRadius: BorderRadius.circular(10),
                  borderColor: AppColors.glassBorder,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.dayAmber,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Sunlit Day', style: AppTypography.caption),
                      const SizedBox(width: 14),
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFF0A0C14),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Night Shadow', style: AppTypography.caption),
                      const SizedBox(width: 14),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Text('Saved City', style: AppTypography.caption),
                    ],
                  ),
                );

                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      leftInfo,
                      const SizedBox(height: 12),
                      legend,
                    ],
                  );
                }

                return Row(
                  children: [
                    Expanded(child: leftInfo),
                    const SizedBox(width: 16),
                    legend,
                  ],
                );
              },
            ),
          ),

          // Main Map Display Area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
              child: Stack(
                children: [
                  // Map Canvas Card
                  GlassContainer(
                    width: double.infinity,
                    height: double.infinity,
                    borderRadius: BorderRadius.circular(16),
                    borderColor: AppColors.glassBorderHighlight,
                    borderWidth: 1.2,
                    clipBehavior: Clip.antiAlias,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final size = Size(constraints.maxWidth, constraints.maxHeight);
                        return GestureDetector(
                          onTapUp: (details) => _onTapUp(details, size),
                          child: CustomPaint(
                            size: size,
                            painter: WorldMapPainter(
                              utcTime: nowUtc,
                              allCities: CityDatabase.allCities,
                              savedCityIds: savedIds,
                              selectedCity: _selectedCity,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Meridian Offset Bar at Bottom of Map
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 12,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('-12h', style: AppTypography.caption),
                        Text('-8h', style: AppTypography.caption),
                        Text('-4h', style: AppTypography.caption),
                        Text('UTC 0', style: AppTypography.caption),
                        Text('+4h', style: AppTypography.caption),
                        Text('+8h', style: AppTypography.caption),
                        Text('+12h', style: AppTypography.caption),
                      ],
                    ),
                  ),

                  // Floating City Details Card (Top Right / Bottom Right)
                  if (_selectedCity != null)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: _SelectedCityCard(
                        city: _selectedCity!,
                        nowUtc: nowUtc,
                        is24Hour: settingsState.is24Hour,
                        showSeconds: settingsState.showSeconds,
                        isSaved: savedIds.contains(_selectedCity!.id),
                        onToggleSaved: () {
                          if (savedIds.contains(_selectedCity!.id)) {
                            clockState.removeCity(_selectedCity!.id);
                          } else {
                            clockState.addCity(_selectedCity!);
                          }
                        },
                        onClose: () => setState(() => _selectedCity = null),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedCityCard extends StatelessWidget {
  final WorldCity city;
  final DateTime nowUtc;
  final bool is24Hour;
  final bool showSeconds;
  final bool isSaved;
  final VoidCallback onToggleSaved;
  final VoidCallback onClose;

  const _SelectedCityCard({
    required this.city,
    required this.nowUtc,
    required this.is24Hour,
    required this.showSeconds,
    required this.isSaved,
    required this.onToggleSaved,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final localTime = TimezoneEngine.convertTo(nowUtc, city.timezoneId);
    final offsetStr = TimezoneEngine.getUtcOffsetString(city.timezoneId, nowUtc);
    final abbr = TimezoneEngine.getTimezoneAbbreviation(city.timezoneId, nowUtc);
    final isDst = TimezoneEngine.isDst(city.timezoneId, nowUtc);

    final solarPos = SolarCalculator.calculatePosition(
      latitude: city.latitude,
      longitude: city.longitude,
      utcTime: nowUtc,
    );
    final solarTimes = SolarCalculator.calculateSolarTimes(
      latitude: city.latitude,
      longitude: city.longitude,
      date: nowUtc,
    );

    final timeStr = TimeFormatter.formatDigitalTime(
      localTime,
      is24Hour: is24Hour,
      showSeconds: showSeconds,
    );
    final amPm = TimeFormatter.getAmPm(localTime);
    final isDay = solarPos.isDay;

    return GlassContainer(
      width: 310,
      padding: const EdgeInsets.all(18),
      borderRadius: BorderRadius.circular(16),
      borderColor: AppColors.glassBorderHighlight,
      borderWidth: 1.2,
      enableGlow: true,
      glowColor: AppColors.accent.withValues(alpha: 0.18),
      shadows: AppColors.glassShadowHover,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Text(city.flagEmoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  city.name,
                  style: AppTypography.h3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 16),
                color: AppColors.textMuted,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onClose,
              ),
            ],
          ),
          Text(
            '${city.country} • ${city.timezoneId}',
            style: AppTypography.caption,
          ),
          const SizedBox(height: 12),

          // Digital Time
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
                  style: AppTypography.clockMedium,
                ),
                if (!is24Hour) ...[
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
          Text(
            '${TimeFormatter.formatMediumDate(localTime)} • $abbr ($offsetStr)',
            style: AppTypography.caption,
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.glassBorder),
          const SizedBox(height: 10),

          // Solar phase & status
          Row(
            children: [
              Icon(
                isDay ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                size: 14,
                color: isDay ? AppColors.dayAmber : AppColors.nightIndigo,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  solarPos.phase,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDay ? AppColors.dayAmber : AppColors.nightIndigo,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isDst) ...[
                const SizedBox(width: 8),
                const Text(
                  'DST Active',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.accentLight,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 6),
          Text(
            'Rise: ${TimeFormatter.formatSunTime(solarTimes.sunrise, is24Hour: is24Hour)} • Set: ${TimeFormatter.formatSunTime(solarTimes.sunset, is24Hour: is24Hour)}',
            style: AppTypography.caption,
          ),

          const SizedBox(height: 14),

          // Add / Remove from Dashboard
          SizedBox(
            width: double.infinity,
            child: GlassButton(
              isPrimary: !isSaved,
              padding: const EdgeInsets.symmetric(vertical: 10),
              icon: Icon(
                isSaved ? Icons.check_rounded : Icons.add_rounded,
                size: 16,
                color: isSaved ? AppColors.workingHoursGreen : Colors.white,
              ),
              label: Text(
                isSaved ? 'Pinned to Dashboard' : 'Add to Dashboard',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSaved ? AppColors.workingHoursGreen : Colors.white,
                ),
              ),
              onPressed: onToggleSaved,
            ),
          ),
        ],
      ),
    );
  }
}
