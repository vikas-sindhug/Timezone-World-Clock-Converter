import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/solar/solar_calculator.dart';
import '../core/time/timezone_engine.dart';
import '../data/models/clock_card_data.dart';
import '../data/models/world_city.dart';
import '../data/repositories/city_database.dart';
import '../data/repositories/settings_repository.dart';

class ClockState extends ChangeNotifier {
  List<WorldCity> _cities = [];
  Set<String> _favoriteIds = {};
  Timer? _ticker;
  DateTime _currentUtcTime = DateTime.now().toUtc();
  String? _referenceTimezoneOverride;
  bool _isLoaded = false;

  List<WorldCity> get cities => _cities;
  Set<String> get favoriteIds => _favoriteIds;
  DateTime get currentUtcTime => _currentUtcTime;
  bool get isLoaded => _isLoaded;

  ClockState() {
    _startTicker();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      _currentUtcTime = DateTime.now().toUtc();
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> load() async {
    final savedIds = await SettingsRepository.loadSavedCityIds();
    final favIds = await SettingsRepository.loadFavoriteCityIds();

    final loadedCities = <WorldCity>[];
    for (final id in savedIds) {
      final city = CityDatabase.findById(id);
      if (city != null) {
        loadedCities.add(city);
      }
    }

    _cities = loadedCities;
    _favoriteIds = favIds;
    _isLoaded = true;
    notifyListeners();
  }

  void setReferenceTimezone(String? timezoneId) {
    _referenceTimezoneOverride = timezoneId;
    notifyListeners();
  }

  String get effectiveReferenceTimezone =>
      _referenceTimezoneOverride ?? TimezoneEngine.localTimezoneId;

  /// Check if city is already added
  bool isCitySaved(String cityId) {
    return _cities.any((c) => c.id == cityId);
  }

  /// Add city to dashboard
  void addCity(WorldCity city) {
    if (isCitySaved(city.id)) return;
    _cities.add(city);
    _save();
    notifyListeners();
  }

  /// Remove city from dashboard
  void removeCity(String cityId) {
    _cities.removeWhere((c) => c.id == cityId);
    _favoriteIds.remove(cityId);
    _save();
    notifyListeners();
  }

  /// Toggle favorite status (favorites appear at top)
  void toggleFavorite(String cityId) {
    if (_favoriteIds.contains(cityId)) {
      _favoriteIds.remove(cityId);
    } else {
      _favoriteIds.add(cityId);
    }
    SettingsRepository.saveFavoriteCityIds(_favoriteIds);
    notifyListeners();
  }

  /// Reorder cities
  void reorderCities(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _cities.removeAt(oldIndex);
    _cities.insert(newIndex, item);
    _save();
    notifyListeners();
  }

  void _save() {
    final ids = _cities.map((c) => c.id).toList();
    SettingsRepository.saveCityIds(ids);
    SettingsRepository.saveFavoriteCityIds(_favoriteIds);
  }

  /// Computed clock cards sorted: favorites first, then regular order
  List<ClockCardData> get clockCards {
    final nowUtc = _currentUtcTime;
    final refTz = effectiveReferenceTimezone;

    // Split favorites and regular
    final favorites = <WorldCity>[];
    final regulars = <WorldCity>[];

    for (final city in _cities) {
      if (_favoriteIds.contains(city.id)) {
        favorites.add(city);
      } else {
        regulars.add(city);
      }
    }

    final sortedCities = [...favorites, ...regulars];

    return sortedCities.map((city) {
      final localTzTime = TimezoneEngine.convertTo(nowUtc, city.timezoneId);
      final isFav = _favoriteIds.contains(city.id);
      final diff = TimezoneEngine.getTimeDifference(
        targetTimezoneId: city.timezoneId,
        referenceTimezoneId: refTz,
        referenceTime: nowUtc,
      );
      final offset = TimezoneEngine.getUtcOffsetString(city.timezoneId, nowUtc);
      final abbr = TimezoneEngine.getTimezoneAbbreviation(city.timezoneId, nowUtc);
      final isDst = TimezoneEngine.isDst(city.timezoneId, nowUtc);

      final solPos = SolarCalculator.calculatePosition(
        latitude: city.latitude,
        longitude: city.longitude,
        utcTime: nowUtc,
      );

      final solTimes = SolarCalculator.calculateSolarTimes(
        latitude: city.latitude,
        longitude: city.longitude,
        date: nowUtc,
      );

      return ClockCardData(
        city: city,
        currentTime: localTzTime,
        isFavorite: isFav,
        timeDifference: diff,
        utcOffset: offset,
        tzAbbreviation: abbr,
        isDst: isDst,
        solarPosition: solPos,
        solarTimes: solTimes,
      );
    }).toList();
  }
}
