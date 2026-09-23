import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../data/models/widget_configuration.dart';
import '../data/models/world_city.dart';

class WidgetSyncService {
  static const MethodChannel _channel = MethodChannel('com.worldclock/widget_sync');

  /// Synchronizes widget data to native macOS App Group storage and reloads WidgetKit timelines.
  static Future<bool> syncToNative({
    required WorldCity? selectedCity,
    required List<WorldCity> multiCities,
    required WidgetConfiguration config,
  }) async {
    final payload = {
      'selectedCity': selectedCity != null ? _cityToMap(selectedCity) : null,
      'multiCities': multiCities.map(_cityToMap).toList(),
      'configuration': {
        'is24Hour': config.is24Hour,
        'showSeconds': config.showSeconds,
        'showAnalog': config.showAnalog,
        'showUtcOffset': config.showUtcOffset,
        'showDate': config.showDate,
        'showDifferenceFromLocal': config.showDifferenceFromLocal,
        'showDayNight': config.showDayNight,
        'themeMode': config.themeMode,
      },
      'updatedAt': DateTime.now().millisecondsSinceEpoch / 1000.0,
    };

    final jsonString = jsonEncode(payload);

    // Only invoke native MethodChannel on macOS
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        final result = await _channel.invokeMethod<bool>('syncWidgetData', jsonString);
        return result ?? true;
      } catch (e) {
        debugPrint('Error syncing widget data to macOS App Groups: $e');
        return false;
      }
    }

    // On Windows and other development platforms, log and return success
    debugPrint('[WidgetSyncService] Synced ${multiCities.length} cities to desktop widget payload.');
    return true;
  }

  /// Triggers a manual timeline reload on macOS WidgetKit.
  static Future<void> reloadAllTimelines() async {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      try {
        await _channel.invokeMethod('reloadTimelines');
      } catch (e) {
        debugPrint('Error requesting WidgetCenter reload: $e');
      }
    }
  }

  static Map<String, dynamic> _cityToMap(WorldCity city) {
    return {
      'id': city.id,
      'name': city.name,
      'country': city.country,
      'timezoneId': city.timezoneId,
      'flagEmoji': city.flagEmoji,
      'latitude': city.latitude,
      'longitude': city.longitude,
      'isFavorite': false,
    };
  }
}
