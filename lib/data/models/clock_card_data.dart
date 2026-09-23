import 'package:timezone/timezone.dart' as tz;
import '../../core/solar/solar_calculator.dart';
import '../../core/time/timezone_engine.dart';
import 'world_city.dart';

class ClockCardData {
  final WorldCity city;
  final tz.TZDateTime currentTime;
  final bool isFavorite;
  final TimeDifference timeDifference;
  final String utcOffset;
  final String tzAbbreviation;
  final bool isDst;
  final SolarPosition solarPosition;
  final SolarTimes solarTimes;

  const ClockCardData({
    required this.city,
    required this.currentTime,
    required this.isFavorite,
    required this.timeDifference,
    required this.utcOffset,
    required this.tzAbbreviation,
    required this.isDst,
    required this.solarPosition,
    required this.solarTimes,
  });

  ClockCardData copyWith({
    WorldCity? city,
    tz.TZDateTime? currentTime,
    bool? isFavorite,
    TimeDifference? timeDifference,
    String? utcOffset,
    String? tzAbbreviation,
    bool? isDst,
    SolarPosition? solarPosition,
    SolarTimes? solarTimes,
  }) {
    return ClockCardData(
      city: city ?? this.city,
      currentTime: currentTime ?? this.currentTime,
      isFavorite: isFavorite ?? this.isFavorite,
      timeDifference: timeDifference ?? this.timeDifference,
      utcOffset: utcOffset ?? this.utcOffset,
      tzAbbreviation: tzAbbreviation ?? this.tzAbbreviation,
      isDst: isDst ?? this.isDst,
      solarPosition: solarPosition ?? this.solarPosition,
      solarTimes: solarTimes ?? this.solarTimes,
    );
  }
}
