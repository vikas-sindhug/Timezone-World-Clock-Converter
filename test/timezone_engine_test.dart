import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:world_clock/core/solar/solar_calculator.dart';
import 'package:world_clock/core/time/timezone_engine.dart';
import 'package:world_clock/data/repositories/city_database.dart';
import 'package:world_clock/state/meeting_planner_state.dart';

void main() {
  setUpAll(() async {
    await TimezoneEngine.initialize();
  });

  group('TimezoneEngine Tests', () {
    test('Correctly calculates standard and half-hour UTC offsets', () {
      // Tokyo: UTC+9
      final tokyoOffset = TimezoneEngine.getUtcOffsetString('Asia/Tokyo');
      expect(tokyoOffset, equals('UTC+09:00'));

      // Kolkata: UTC+05:30
      final kolkataOffset = TimezoneEngine.getUtcOffsetString('Asia/Kolkata');
      expect(kolkataOffset, equals('UTC+05:30'));

      // Kathmandu: UTC+05:45
      final kathmanduOffset = TimezoneEngine.getUtcOffsetString('Asia/Kathmandu');
      expect(kathmanduOffset, equals('UTC+05:45'));

      // UTC
      final utcOffset = TimezoneEngine.getUtcOffsetString('UTC');
      expect(utcOffset, equals('UTC'));
    });

    test('Correctly computes relative difference between Jaipur and New York', () {
      // Using UTC reference date (summer EDT)
      final summerDate = DateTime.utc(2026, 7, 15, 12, 0); // NYC is EDT (UTC-4)
      final diffSummer = TimezoneEngine.getTimeDifference(
        targetTimezoneId: 'Asia/Kolkata',
        referenceTimezoneId: 'America/New_York',
        referenceTime: summerDate,
      );
      // IST is +05:30, EDT is -04:00 -> difference is +9h 30m
      expect(diffSummer.totalMinutes, equals(570)); // 9.5 hours
      expect(diffSummer.formatted, equals('+9h 30m from local'));

      // Using winter reference date (winter EST)
      final winterDate = DateTime.utc(2026, 1, 15, 12, 0); // NYC is EST (UTC-5)
      final diffWinter = TimezoneEngine.getTimeDifference(
        targetTimezoneId: 'Asia/Kolkata',
        referenceTimezoneId: 'America/New_York',
        referenceTime: winterDate,
      );
      // IST is +05:30, EST is -05:00 -> difference is +10h 30m
      expect(diffWinter.totalMinutes, equals(630)); // 10.5 hours
      expect(diffWinter.formatted, equals('+10h 30m from local'));
    });

    test('Handles midnight crossing and calendar date changes correctly', () {
      // 11:30 PM in London on Sep 22
      final londonLoc = TimezoneEngine.getLocation('Europe/London');
      final londonTime = tz.TZDateTime(londonLoc, 2026, 9, 22, 23, 30);
      final tokyoTime = TimezoneEngine.convertTo(londonTime, 'Asia/Tokyo');

      // London is BST (UTC+1) -> 23:30 BST = 22:30 UTC.
      // Tokyo is JST (UTC+9) -> 22:30 + 9h = 07:30 next day (Sep 23)
      expect(tokyoTime.day, equals(23));
      expect(tokyoTime.hour, equals(7));
      expect(tokyoTime.minute, equals(30));
    });

    test('Accurately detects Daylight Saving Time (DST)', () {
      // New York in July (EDT) has DST = true
      final summer = DateTime.utc(2026, 7, 1);
      expect(TimezoneEngine.isDst('America/New_York', summer), isTrue);

      // New York in January (EST) has DST = false
      final winter = DateTime.utc(2026, 1, 1);
      expect(TimezoneEngine.isDst('America/New_York', winter), isFalse);

      // Tokyo never observes DST
      expect(TimezoneEngine.isDst('Asia/Tokyo', summer), isFalse);
    });
  });

  group('SolarCalculator Tests', () {
    test('Calculates valid sunrise and sunset for coordinates', () {
      final tokyoTimes = SolarCalculator.calculateSolarTimes(
        latitude: 35.6762,
        longitude: 139.6503,
        date: DateTime.utc(2026, 9, 22),
      );

      expect(tokyoTimes.sunrise, isNotNull);
      expect(tokyoTimes.sunset, isNotNull);
      expect(tokyoTimes.solarNoon, isNotNull);
      expect(tokyoTimes.sunrise!.isBefore(tokyoTimes.sunset!), isTrue);
    });

    test('Calculates solar elevation and day/night status', () {
      // Noon at subsolar point (lon 0, lat 0 at 12:00 UTC on equinox)
      final posNoon = SolarCalculator.calculatePosition(
        latitude: 0.0,
        longitude: 0.0,
        utcTime: DateTime.utc(2026, 9, 22, 12, 0),
      );
      expect(posNoon.isDay, isTrue);
      expect(posNoon.altitudeDegrees, greaterThan(80.0));

      // Midnight at anti-solar point
      final posMidnight = SolarCalculator.calculatePosition(
        latitude: 0.0,
        longitude: 180.0,
        utcTime: DateTime.utc(2026, 9, 22, 12, 0),
      );
      expect(posMidnight.isDay, isFalse);
      expect(posMidnight.altitudeDegrees, lessThan(-50.0));
    });
  });

  group('CityDatabase Tests', () {
    test('Search returns matches across city name, country, and aliases', () {
      final tokyoResults = CityDatabase.search('Tokyo');
      expect(tokyoResults.any((c) => c.name == 'Tokyo'), isTrue);

      final indiaResults = CityDatabase.search('India');
      expect(indiaResults.length, greaterThanOrEqualTo(4)); // Jaipur, Delhi, Mumbai, Bengaluru

      final nycResults = CityDatabase.search('NYC');
      expect(nycResults.any((c) => c.id == 'new_york_us'), isTrue);
    });
  });

  group('MeetingPlannerState Tests', () {
    test('Finds working hours overlaps across timezones', () {
      final state = MeetingPlannerState();
      state.initializeWithDefaults([
        CityDatabase.findById('new_york_us')!,
        CityDatabase.findById('london_gb')!,
      ]);
      state.setDuration(1.0);

      final overlaps = state.findBestOverlaps('America/New_York');
      expect(overlaps, isNotEmpty);
      // When NY is 9 AM - 12 PM, London is 2 PM - 5 PM (both working hours!)
      final best = overlaps.first;
      expect(best.workingParticipantsCount, equals(2));
    });
  });
}
