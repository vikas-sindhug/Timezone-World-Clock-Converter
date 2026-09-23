import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class TimeDifference {
  final int totalMinutes;
  final String formatted;
  final bool isAhead;
  final bool isSame;
  final int dayDifference; // -1, 0, 1

  const TimeDifference({
    required this.totalMinutes,
    required this.formatted,
    required this.isAhead,
    required this.isSame,
    required this.dayDifference,
  });
}

class TimezoneEngine {
  static bool _isInitialized = false;
  static String _localTimezoneId = 'UTC';

  static bool get isInitialized => _isInitialized;
  static String get localTimezoneId => _localTimezoneId;

  /// Initialize IANA database and detect device local timezone
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      tz_data.initializeTimeZones();
      _isInitialized = true;

      // Detect local timezone from OS
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        final detected = info.identifier;
        if (isValidTimezone(detected)) {
          _localTimezoneId = detected;
        } else {
          // Fallback based on system local DateTime offset
          _localTimezoneId = _fallbackTimezoneFromLocalOffset();
        }
      } catch (e) {
        debugPrint('Error getting local timezone from platform: $e');
        _localTimezoneId = _fallbackTimezoneFromLocalOffset();
      }

      debugPrint('TimezoneEngine initialized. Local timezone: $_localTimezoneId');
    } catch (e) {
      debugPrint('Error initializing TimezoneEngine: $e');
      _isInitialized = true;
      _localTimezoneId = 'UTC';
    }
  }

  static void setLocalTimezoneOverride(String timezoneId) {
    if (isValidTimezone(timezoneId)) {
      _localTimezoneId = timezoneId;
    }
  }

  static bool isValidTimezone(String timezoneId) {
    return tz.timeZoneDatabase.locations.containsKey(timezoneId);
  }

  static tz.Location getLocation(String timezoneId) {
    if (tz.timeZoneDatabase.locations.containsKey(timezoneId)) {
      return tz.getLocation(timezoneId);
    }
    // Fallback
    return tz.getLocation('UTC');
  }

  /// Get current time in specified timezone
  static tz.TZDateTime nowIn(String timezoneId) {
    final loc = getLocation(timezoneId);
    return tz.TZDateTime.now(loc);
  }

  /// Convert a given DateTime (in UTC or any tz) to target timezone
  static tz.TZDateTime convertTo(DateTime dateTime, String targetTimezoneId) {
    final loc = getLocation(targetTimezoneId);
    final utc = dateTime.isUtc ? dateTime : dateTime.toUtc();
    return tz.TZDateTime.from(utc, loc);
  }

  /// Get formatted UTC offset, e.g. "UTC+05:30", "UTC-04:00", "UTC"
  static String getUtcOffsetString(String timezoneId, [DateTime? time]) {
    final loc = getLocation(timezoneId);
    final targetTime = time != null
        ? tz.TZDateTime.from(time.toUtc(), loc)
        : tz.TZDateTime.now(loc);

    final offsetMs = targetTime.timeZoneOffset.inMilliseconds;
    if (offsetMs == 0) return 'UTC';

    final isNegative = offsetMs < 0;
    final totalMinutes = (offsetMs.abs() / (60 * 1000)).round();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    final sign = isNegative ? '-' : '+';
    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');

    return 'UTC$sign$hStr:$mStr';
  }

  /// Get offset duration
  static Duration getUtcOffset(String timezoneId, [DateTime? time]) {
    final loc = getLocation(timezoneId);
    final targetTime = time != null
        ? tz.TZDateTime.from(time.toUtc(), loc)
        : tz.TZDateTime.now(loc);
    return targetTime.timeZoneOffset;
  }

  /// Check whether daylight saving time (DST) is active
  static bool isDst(String timezoneId, [DateTime? time]) {
    final loc = getLocation(timezoneId);
    final targetTime = time != null
        ? tz.TZDateTime.from(time.toUtc(), loc)
        : tz.TZDateTime.now(loc);
    return targetTime.timeZone.isDst;
  }

  /// Get timezone abbreviation (e.g. JST, EST, EDT, IST)
  static String getTimezoneAbbreviation(String timezoneId, [DateTime? time]) {
    final loc = getLocation(timezoneId);
    final targetTime = time != null
        ? tz.TZDateTime.from(time.toUtc(), loc)
        : tz.TZDateTime.now(loc);
    final abbr = targetTime.timeZone.abbreviation;
    if (abbr.isNotEmpty && !abbr.contains('+') && !abbr.contains('-')) {
      return abbr;
    }
    // If abbreviation is an offset like "+0530", return formatted UTC offset
    return getUtcOffsetString(timezoneId, time);
  }

  /// Calculate relative time difference from reference timezone (default: local OS timezone)
  static TimeDifference getTimeDifference({
    required String targetTimezoneId,
    String? referenceTimezoneId,
    DateTime? referenceTime,
  }) {
    final refId = referenceTimezoneId ?? _localTimezoneId;
    final refLoc = getLocation(refId);
    final targetLoc = getLocation(targetTimezoneId);

    final nowUtc = referenceTime != null ? referenceTime.toUtc() : DateTime.now().toUtc();
    final refTime = tz.TZDateTime.from(nowUtc, refLoc);
    final targetTime = tz.TZDateTime.from(nowUtc, targetLoc);

    final refOffset = refTime.timeZoneOffset;
    final targetOffset = targetTime.timeZoneOffset;

    final diffMinutes = targetOffset.inMinutes - refOffset.inMinutes;

    // Calculate calendar day difference
    final refDateOnly = DateTime(refTime.year, refTime.month, refTime.day);
    final targetDateOnly = DateTime(targetTime.year, targetTime.month, targetTime.day);
    final dayDiff = targetDateOnly.difference(refDateOnly).inDays;

    if (diffMinutes == 0) {
      return const TimeDifference(
        totalMinutes: 0,
        formatted: 'Same time as local',
        isAhead: false,
        isSame: true,
        dayDifference: 0,
      );
    }

    final isAhead = diffMinutes > 0;
    final absMin = diffMinutes.abs();
    final hours = absMin ~/ 60;
    final mins = absMin % 60;

    final sign = isAhead ? '+' : '-';
    String formatted;
    if (mins == 0) {
      formatted = '$sign${hours}h from local';
    } else {
      formatted = '$sign${hours}h ${mins}m from local';
    }

    return TimeDifference(
      totalMinutes: diffMinutes,
      formatted: formatted,
      isAhead: isAhead,
      isSame: false,
      dayDifference: dayDiff,
    );
  }

  static String _fallbackTimezoneFromLocalOffset() {
    final offset = DateTime.now().timeZoneOffset;
    // Look through known timezones for matching current offset
    for (final entry in tz.timeZoneDatabase.locations.entries) {
      try {
        final nowTz = tz.TZDateTime.now(entry.value);
        if (nowTz.timeZoneOffset == offset) {
          return entry.key;
        }
      } catch (_) {}
    }
    return 'UTC';
  }
}
