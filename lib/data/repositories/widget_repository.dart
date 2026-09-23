import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/widget_configuration.dart';

class WidgetRepository {
  static const String _keyWidgetConfig = 'world_clock_widget_config';

  Future<WidgetConfiguration> loadConfiguration() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_keyWidgetConfig);
    if (jsonStr == null || jsonStr.isEmpty) {
      return const WidgetConfiguration();
    }
    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WidgetConfiguration.fromJson(map);
    } catch (_) {
      return const WidgetConfiguration();
    }
  }

  Future<void> saveConfiguration(WidgetConfiguration config) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = jsonEncode(config.toJson());
    await prefs.setString(_keyWidgetConfig, jsonStr);
  }
}
