import 'package:flutter/foundation.dart';
import '../data/models/widget_configuration.dart';
import '../data/models/world_city.dart';
import '../data/repositories/widget_repository.dart';
import '../services/widget_sync_service.dart';

class DesktopWidgetState extends ChangeNotifier {
  final WidgetRepository _repository;

  WidgetConfiguration _config = const WidgetConfiguration();
  bool _isInitialized = false;

  DesktopWidgetState({WidgetRepository? repository})
      : _repository = repository ?? WidgetRepository();

  WidgetConfiguration get config => _config;
  bool get isInitialized => _isInitialized;

  String? get singleCityId => _config.singleCityId;
  List<String> get multiCityIds => _config.multiCityIds;
  bool get is24Hour => _config.is24Hour;
  bool get showSeconds => _config.showSeconds;
  bool get showAnalog => _config.showAnalog;
  bool get showUtcOffset => _config.showUtcOffset;
  bool get showDate => _config.showDate;
  bool get showDifferenceFromLocal => _config.showDifferenceFromLocal;
  bool get showDayNight => _config.showDayNight;
  String get themeMode => _config.themeMode;

  /// Initializes the widget state from persistent storage and syncs with available cities.
  Future<void> initialize(List<WorldCity> availableCities) async {
    _config = await _repository.loadConfiguration();

    // Default single city if none configured or no longer exists
    String? resolvedSingle = _config.singleCityId;
    if (resolvedSingle == null || !availableCities.any((c) => c.id == resolvedSingle)) {
      resolvedSingle = availableCities.isNotEmpty ? availableCities.first.id : null;
    }

    // Default multi-cities if none configured
    List<String> resolvedMulti = List<String>.from(_config.multiCityIds);
    resolvedMulti.removeWhere((id) => !availableCities.any((c) => c.id == id));
    if (resolvedMulti.isEmpty && availableCities.isNotEmpty) {
      resolvedMulti = availableCities.take(4).map((c) => c.id).toList();
    }

    _config = _config.copyWith(
      singleCityId: resolvedSingle,
      multiCityIds: resolvedMulti,
    );

    _isInitialized = true;
    notifyListeners();

    await _repository.saveConfiguration(_config);
    await syncWithAvailableCities(availableCities);
  }

  /// Sets the active single-city for Small and Medium widgets.
  Future<void> setSingleCity(String cityId, List<WorldCity> availableCities) async {
    if (_config.singleCityId == cityId) return;
    _config = _config.copyWith(singleCityId: cityId);
    notifyListeners();
    await _repository.saveConfiguration(_config);
    await syncWithAvailableCities(availableCities);
  }

  /// Sets the ordered list of cities for Multi-City widgets (2 to 6 cities).
  Future<void> setMultiCities(List<String> cityIds, List<WorldCity> availableCities) async {
    _config = _config.copyWith(multiCityIds: cityIds);
    notifyListeners();
    await _repository.saveConfiguration(_config);
    await syncWithAvailableCities(availableCities);
  }

  /// Toggles a city in the multi-clock widget list.
  Future<void> toggleMultiCity(String cityId, List<WorldCity> availableCities) async {
    final list = List<String>.from(_config.multiCityIds);
    if (list.contains(cityId)) {
      if (list.length > 2) {
        list.remove(cityId);
      }
    } else {
      if (list.length < 6) {
        list.add(cityId);
      }
    }
    await setMultiCities(list, availableCities);
  }

  /// Reorders items in the multi-clock widget list.
  Future<void> reorderMultiCities(int oldIndex, int newIndex, List<WorldCity> availableCities) async {
    final list = List<String>.from(_config.multiCityIds);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    await setMultiCities(list, availableCities);
  }

  /// Updates widget configuration display toggles.
  Future<void> updateConfig({
    bool? is24Hour,
    bool? showSeconds,
    bool? showAnalog,
    bool? showUtcOffset,
    bool? showDate,
    bool? showDifferenceFromLocal,
    bool? showDayNight,
    String? themeMode,
    List<WorldCity>? availableCities,
  }) async {
    _config = _config.copyWith(
      is24Hour: is24Hour,
      showSeconds: showSeconds,
      showAnalog: showAnalog,
      showUtcOffset: showUtcOffset,
      showDate: showDate,
      showDifferenceFromLocal: showDifferenceFromLocal,
      showDayNight: showDayNight,
      themeMode: themeMode,
    );
    notifyListeners();
    await _repository.saveConfiguration(_config);

    if (availableCities != null) {
      await syncWithAvailableCities(availableCities);
    }
  }

  /// Resolves active single city object.
  WorldCity? getSelectedCity(List<WorldCity> availableCities) {
    if (availableCities.isEmpty) return null;
    final id = _config.singleCityId;
    if (id == null) return availableCities.first;
    return availableCities.firstWhere(
      (c) => c.id == id,
      orElse: () => availableCities.first,
    );
  }

  /// Resolves active multi-city objects.
  List<WorldCity> getMultiCities(List<WorldCity> availableCities) {
    if (availableCities.isEmpty) return [];
    final map = {for (final c in availableCities) c.id: c};
    final resolved = <WorldCity>[];
    for (final id in _config.multiCityIds) {
      final city = map[id];
      if (city != null) resolved.add(city);
    }
    if (resolved.isEmpty) {
      return availableCities.take(4).toList();
    }
    return resolved;
  }

  /// Synchronizes widget data with macOS WidgetKit App Groups.
  Future<void> syncWithAvailableCities(List<WorldCity> availableCities) async {
    final selected = getSelectedCity(availableCities);
    final multi = getMultiCities(availableCities);

    await WidgetSyncService.syncToNative(
      selectedCity: selected,
      multiCities: multi,
      config: _config,
    );
  }
}
