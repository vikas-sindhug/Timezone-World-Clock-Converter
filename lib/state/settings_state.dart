import 'package:flutter/foundation.dart';
import '../core/time/timezone_engine.dart';
import '../data/repositories/settings_repository.dart';

class SettingsState extends ChangeNotifier {
  bool _is24Hour = false;
  bool _showSeconds = true;
  bool _showAnalogClock = true;
  String? _referenceTimezone;
  bool _glassEffectsEnabled = true;
  bool _reducedMotion = false;
  String _transparencyLevel = 'medium'; // 'high', 'medium', 'low'
  bool _isLoaded = false;

  bool get is24Hour => _is24Hour;
  bool get showSeconds => _showSeconds;
  bool get showAnalogClock => _showAnalogClock;
  String? get referenceTimezone => _referenceTimezone;
  bool get glassEffectsEnabled => _glassEffectsEnabled;
  bool get reducedMotion => _reducedMotion;
  String get transparencyLevel => _transparencyLevel;
  bool get isLoaded => _isLoaded;

  String get effectiveReferenceTimezone =>
      _referenceTimezone ?? TimezoneEngine.localTimezoneId;

  Future<void> load() async {
    _is24Hour = await SettingsRepository.loadIs24Hour();
    _showSeconds = await SettingsRepository.loadShowSeconds();
    _showAnalogClock = await SettingsRepository.loadShowAnalogClock();
    _referenceTimezone = await SettingsRepository.loadReferenceTimezone();
    _glassEffectsEnabled = await SettingsRepository.loadGlassEffectsEnabled();
    _reducedMotion = await SettingsRepository.loadReducedMotion();
    _transparencyLevel = await SettingsRepository.loadTransparencyLevel();
    _isLoaded = true;
    notifyListeners();
  }

  void toggle24Hour() {
    _is24Hour = !_is24Hour;
    SettingsRepository.saveIs24Hour(_is24Hour);
    notifyListeners();
  }

  void toggleShowSeconds() {
    _showSeconds = !_showSeconds;
    SettingsRepository.saveShowSeconds(_showSeconds);
    notifyListeners();
  }

  void toggleShowAnalogClock() {
    _showAnalogClock = !_showAnalogClock;
    SettingsRepository.saveShowAnalogClock(_showAnalogClock);
    notifyListeners();
  }

  void setReferenceTimezone(String? timezoneId) {
    _referenceTimezone = timezoneId;
    SettingsRepository.saveReferenceTimezone(timezoneId);
    notifyListeners();
  }

  void toggleGlassEffects() {
    _glassEffectsEnabled = !_glassEffectsEnabled;
    SettingsRepository.saveGlassEffectsEnabled(_glassEffectsEnabled);
    notifyListeners();
  }

  void toggleReducedMotion() {
    _reducedMotion = !_reducedMotion;
    SettingsRepository.saveReducedMotion(_reducedMotion);
    notifyListeners();
  }

  void setTransparencyLevel(String level) {
    _transparencyLevel = level;
    SettingsRepository.saveTransparencyLevel(level);
    notifyListeners();
  }
}
