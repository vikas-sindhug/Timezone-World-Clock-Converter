import 'package:shared_preferences/shared_preferences.dart';

class SettingsRepository {
  static const String _keySavedCities = 'worldclock_saved_city_ids';
  static const String _keyFavorites = 'worldclock_favorite_city_ids';
  static const String _key24Hour = 'worldclock_is_24_hour';
  static const String _keyShowSeconds = 'worldclock_show_seconds';
  static const String _keyShowAnalogClock = 'worldclock_show_analog_clock';
  static const String _keyReferenceTz = 'worldclock_reference_timezone';
  static const String _keyGlassEffects = 'worldclock_glass_effects_enabled';
  static const String _keyReducedMotion = 'worldclock_reduced_motion';
  static const String _keyTransparency = 'worldclock_transparency_level';

  // Default initial cities if none saved
  static const List<String> defaultCityIds = [
    'tokyo_jp',
    'london_gb',
    'new_york_us',
    'jaipur_in',
    'san_francisco_us',
    'dubai_ae',
  ];

  static Future<List<String>> loadSavedCityIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySavedCities);
    if (list == null || list.isEmpty) {
      return defaultCityIds;
    }
    return list;
  }

  static Future<void> saveCityIds(List<String> cityIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySavedCities, cityIds);
  }

  static Future<Set<String>> loadFavoriteCityIds() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyFavorites);
    return list?.toSet() ?? <String>{};
  }

  static Future<void> saveFavoriteCityIds(Set<String> favoriteIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keyFavorites, favoriteIds.toList());
  }

  static Future<bool> loadIs24Hour() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key24Hour) ?? false;
  }

  static Future<void> saveIs24Hour(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key24Hour, value);
  }

  static Future<bool> loadShowSeconds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowSeconds) ?? true;
  }

  static Future<void> saveShowSeconds(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowSeconds, value);
  }

  static Future<bool> loadShowAnalogClock() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowAnalogClock) ?? true;
  }

  static Future<void> saveShowAnalogClock(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowAnalogClock, value);
  }

  static Future<String?> loadReferenceTimezone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyReferenceTz);
  }

  static Future<void> saveReferenceTimezone(String? timezoneId) async {
    final prefs = await SharedPreferences.getInstance();
    if (timezoneId == null) {
      await prefs.remove(_keyReferenceTz);
    } else {
      await prefs.setString(_keyReferenceTz, timezoneId);
    }
  }

  static Future<bool> loadGlassEffectsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyGlassEffects) ?? true;
  }

  static Future<void> saveGlassEffectsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyGlassEffects, value);
  }

  static Future<bool> loadReducedMotion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyReducedMotion) ?? false;
  }

  static Future<void> saveReducedMotion(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReducedMotion, value);
  }

  static Future<String> loadTransparencyLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyTransparency) ?? 'medium';
  }

  static Future<void> saveTransparencyLevel(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyTransparency, value);
  }
}
