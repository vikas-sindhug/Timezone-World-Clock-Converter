import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/time/timezone_engine.dart';
import '../data/models/world_city.dart';
import '../data/repositories/city_database.dart';

enum HourStatus {
  sleeping,     // 11 PM - 7 AM
  earlyMorning, // 7 AM - 9 AM
  working,      // 9 AM - 6 PM
  evening,      // 6 PM - 11 PM
}

class OverlapSlotRecommendation {
  final double startHour; // in reference tz
  final int workingParticipantsCount;
  final int totalParticipants;
  final double score;
  final String label;

  const OverlapSlotRecommendation({
    required this.startHour,
    required this.workingParticipantsCount,
    required this.totalParticipants,
    required this.score,
    required this.label,
  });
}

class MeetingPlannerState extends ChangeNotifier {
  List<WorldCity> _participants = [];
  DateTime _meetingDate = DateTime.now();
  double _startHour = 14.0; // 2:00 PM in reference tz
  double _durationHours = 1.0; // 1 hour meeting

  List<WorldCity> get participants => _participants;
  DateTime get meetingDate => _meetingDate;
  double get startHour => _startHour;
  double get durationHours => _durationHours;

  void initializeWithDefaults(List<WorldCity> savedCities) {
    if (_participants.isEmpty) {
      if (savedCities.isNotEmpty) {
        _participants = savedCities.take(4).toList();
      } else {
        _participants = [
          CityDatabase.findById('new_york_us')!,
          CityDatabase.findById('london_gb')!,
          CityDatabase.findById('tokyo_jp')!,
        ];
      }
    }
    notifyListeners();
  }

  void addParticipant(WorldCity city) {
    if (_participants.any((c) => c.id == city.id)) return;
    _participants.add(city);
    notifyListeners();
  }

  void removeParticipant(String cityId) {
    if (_participants.length <= 1) return; // Keep at least 1
    _participants.removeWhere((c) => c.id == cityId);
    notifyListeners();
  }

  void setMeetingDate(DateTime date) {
    _meetingDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setStartHour(double hour) {
    _startHour = hour.clamp(0.0, 24.0 - _durationHours);
    notifyListeners();
  }

  void setDuration(double hours) {
    _durationHours = hours.clamp(0.5, 4.0);
    if (_startHour + _durationHours > 24.0) {
      _startHour = 24.0 - _durationHours;
    }
    notifyListeners();
  }

  /// Get status of an hour (0-23)
  static HourStatus getHourStatus(int hour) {
    if (hour >= 9 && hour < 18) {
      return HourStatus.working;
    } else if (hour >= 7 && hour < 9) {
      return HourStatus.earlyMorning;
    } else if (hour >= 18 && hour < 23) {
      return HourStatus.evening;
    } else {
      return HourStatus.sleeping;
    }
  }

  /// Convert reference date & hour to UTC
  DateTime getMeetingStartUtc(String referenceTzId) {
    final refLoc = TimezoneEngine.getLocation(referenceTzId);
    final hour = _startHour.floor();
    final minute = ((_startHour - hour) * 60).round();
    final refTime = tz.TZDateTime(
      refLoc,
      _meetingDate.year,
      _meetingDate.month,
      _meetingDate.day,
      hour,
      minute,
      0,
    );
    return refTime.toUtc();
  }

  /// Get local meeting time in participant timezone
  tz.TZDateTime getParticipantMeetingTime(WorldCity city, String referenceTzId) {
    final utc = getMeetingStartUtc(referenceTzId);
    final loc = TimezoneEngine.getLocation(city.timezoneId);
    return tz.TZDateTime.from(utc, loc);
  }

  /// Calculate "Best Overlap" slots across 24h day
  List<OverlapSlotRecommendation> findBestOverlaps(String referenceTzId) {
    if (_participants.isEmpty) return [];

    final recommendations = <OverlapSlotRecommendation>[];
    final refLoc = TimezoneEngine.getLocation(referenceTzId);

    // Test slots every 30 minutes (0.0, 0.5, 1.0, ..., 23.5)
    for (double candidate = 0.0; candidate <= (24.0 - _durationHours); candidate += 0.5) {
      final hour = candidate.floor();
      final minute = ((candidate - hour) * 60).round();
      final refTime = tz.TZDateTime(
        refLoc,
        _meetingDate.year,
        _meetingDate.month,
        _meetingDate.day,
        hour,
        minute,
        0,
      );
      final utc = refTime.toUtc();

      int workingCount = 0;
      double slotScore = 0;

      for (final p in _participants) {
        final pLoc = TimezoneEngine.getLocation(p.timezoneId);
        final pTime = tz.TZDateTime.from(utc, pLoc);
        final pHour = pTime.hour;
        final status = getHourStatus(pHour);

        switch (status) {
          case HourStatus.working:
            workingCount++;
            slotScore += 10.0;
            break;
          case HourStatus.evening:
            slotScore += 4.0;
            break;
          case HourStatus.earlyMorning:
            slotScore += 2.0;
            break;
          case HourStatus.sleeping:
            slotScore -= 12.0;
            break;
        }
      }

      final hStr = hour.toString().padLeft(2, '0');
      final mStr = minute.toString().padLeft(2, '0');
      recommendations.add(OverlapSlotRecommendation(
        startHour: candidate,
        workingParticipantsCount: workingCount,
        totalParticipants: _participants.length,
        score: slotScore,
        label: '$hStr:$mStr ($workingCount/${_participants.length} in working hours)',
      ));
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(5).toList();
  }
}
