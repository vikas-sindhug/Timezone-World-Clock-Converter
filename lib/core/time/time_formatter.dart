import 'package:intl/intl.dart';

class TimeFormatter {
  static final _dateFull = DateFormat('EEEE, MMMM d, y');
  static final _dateMedium = DateFormat('EEE, MMM d');
  static final _dateShort = DateFormat('MMM d');
  static final _solarTime12 = DateFormat('h:mm a');
  static final _solarTime24 = DateFormat('HH:mm');

  /// Format digital time with or without seconds in 12h or 24h format
  static String formatDigitalTime(
    DateTime time, {
    required bool is24Hour,
    required bool showSeconds,
  }) {
    if (is24Hour) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      if (showSeconds) {
        final s = time.second.toString().padLeft(2, '0');
        return '$h:$m:$s';
      }
      return '$h:$m';
    } else {
      var h = time.hour % 12;
      if (h == 0) h = 12;
      final hStr = h.toString().padLeft(2, '0');
      final mStr = time.minute.toString().padLeft(2, '0');
      if (showSeconds) {
        final sStr = time.second.toString().padLeft(2, '0');
        return '$hStr:$mStr:$sStr';
      }
      return '$hStr:$mStr';
    }
  }

  /// Get AM/PM indicator for 12-hour mode
  static String getAmPm(DateTime time) {
    return time.hour >= 12 ? 'PM' : 'AM';
  }

  /// Full date: "Tuesday, September 22, 2026"
  static String formatFullDate(DateTime time) {
    return _dateFull.format(time);
  }

  /// Medium date: "Tue, Sep 22"
  static String formatMediumDate(DateTime time) {
    return _dateMedium.format(time);
  }

  /// Short date: "Sep 22"
  static String formatShortDate(DateTime time) {
    return _dateShort.format(time);
  }

  /// Format sunrise or sunset time
  static String formatSunTime(DateTime? time, {required bool is24Hour}) {
    if (time == null) return '--:--';
    return is24Hour ? _solarTime24.format(time) : _solarTime12.format(time);
  }

  /// Format duration offset difference, e.g. "+10h 30m" or "-5h"
  static String formatDifference(int totalMinutes) {
    if (totalMinutes == 0) return '0h';
    final isAhead = totalMinutes > 0;
    final absMin = totalMinutes.abs();
    final h = absMin ~/ 60;
    final m = absMin % 60;
    final sign = isAhead ? '+' : '-';
    if (m == 0) return '$sign${h}h';
    return '$sign${h}h ${m}m';
  }
}
