import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/time/timezone_engine.dart';
import '../data/models/world_city.dart';
import '../data/repositories/city_database.dart';

class ConvertedCityResult {
  final WorldCity city;
  final tz.TZDateTime localTime;
  final String offsetString;
  final int dayDifference;

  const ConvertedCityResult({
    required this.city,
    required this.localTime,
    required this.offsetString,
    required this.dayDifference,
  });
}

class ConverterState extends ChangeNotifier {
  WorldCity _fromCity = CityDatabase.findById('new_york_us') ?? CityDatabase.allCities.first;
  WorldCity _toCity = CityDatabase.findById('tokyo_jp') ?? CityDatabase.allCities[1];
  
  DateTime _selectedDate = DateTime.now();
  int _selectedHour = 9; // 9 AM
  int _selectedMinute = 0;

  WorldCity get fromCity => _fromCity;
  WorldCity get toCity => _toCity;
  DateTime get selectedDate => _selectedDate;
  int get selectedHour => _selectedHour;
  int get selectedMinute => _selectedMinute;

  void initializeWithLocal(String? localTzId) {
    if (localTzId != null) {
      final localCity = CityDatabase.findByTimezone(localTzId);
      if (localCity != null) {
        _fromCity = localCity;
      }
    }
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _selectedHour = now.hour;
    _selectedMinute = (now.minute ~/ 15) * 15; // Round to 15m
    notifyListeners();
  }

  void setFromCity(WorldCity city) {
    _fromCity = city;
    notifyListeners();
  }

  void setToCity(WorldCity city) {
    _toCity = city;
    notifyListeners();
  }

  void swap() {
    final temp = _fromCity;
    _fromCity = _toCity;
    _toCity = temp;
    notifyListeners();
  }

  void setDate(DateTime date) {
    _selectedDate = DateTime(date.year, date.month, date.day);
    notifyListeners();
  }

  void setTime(int hour, int minute) {
    _selectedHour = hour.clamp(0, 23);
    _selectedMinute = minute.clamp(0, 59);
    notifyListeners();
  }

  /// Construct source TZDateTime in fromCity timezone
  tz.TZDateTime get sourceTzDateTime {
    final loc = TimezoneEngine.getLocation(_fromCity.timezoneId);
    return tz.TZDateTime(
      loc,
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedHour,
      _selectedMinute,
      0,
    );
  }

  /// Convert to target city timezone
  tz.TZDateTime get targetTzDateTime {
    final sourceDt = sourceTzDateTime;
    final utc = sourceDt.toUtc();
    final toLoc = TimezoneEngine.getLocation(_toCity.timezoneId);
    return tz.TZDateTime.from(utc, toLoc);
  }

  /// Day difference between target and source (-1, 0, +1)
  int get dayDifference {
    final src = sourceTzDateTime;
    final tgt = targetTzDateTime;
    final srcDate = DateTime(src.year, src.month, src.day);
    final tgtDate = DateTime(tgt.year, tgt.month, tgt.day);
    return tgtDate.difference(srcDate).inDays;
  }

  /// Exact difference between toCity and fromCity
  TimeDifference get timeDifference {
    final src = sourceTzDateTime;
    return TimezoneEngine.getTimeDifference(
      targetTimezoneId: _toCity.timezoneId,
      referenceTimezoneId: _fromCity.timezoneId,
      referenceTime: src.toUtc(),
    );
  }

  /// Convert source time to multiple other cities
  List<ConvertedCityResult> convertToMultiple(List<WorldCity> cities) {
    final utc = sourceTzDateTime.toUtc();
    final srcDate = DateTime(sourceTzDateTime.year, sourceTzDateTime.month, sourceTzDateTime.day);

    return cities.map((city) {
      final loc = TimezoneEngine.getLocation(city.timezoneId);
      final local = tz.TZDateTime.from(utc, loc);
      final offset = TimezoneEngine.getUtcOffsetString(city.timezoneId, utc);
      final targetDate = DateTime(local.year, local.month, local.day);
      final dayDiff = targetDate.difference(srcDate).inDays;

      return ConvertedCityResult(
        city: city,
        localTime: local,
        offsetString: offset,
        dayDifference: dayDiff,
      );
    }).toList();
  }
}
