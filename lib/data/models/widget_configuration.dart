/// Configuration parameters for desktop widgets.
class WidgetConfiguration {
  final String? singleCityId;
  final List<String> multiCityIds;
  final bool is24Hour;
  final bool showSeconds;
  final bool showAnalog;
  final bool showUtcOffset;
  final bool showDate;
  final bool showDifferenceFromLocal;
  final bool showDayNight;
  final String themeMode; // "system", "dark", "light"

  const WidgetConfiguration({
    this.singleCityId,
    this.multiCityIds = const [],
    this.is24Hour = false,
    this.showSeconds = false,
    this.showAnalog = false,
    this.showUtcOffset = true,
    this.showDate = true,
    this.showDifferenceFromLocal = true,
    this.showDayNight = true,
    this.themeMode = 'system',
  });

  WidgetConfiguration copyWith({
    String? singleCityId,
    List<String>? multiCityIds,
    bool? is24Hour,
    bool? showSeconds,
    bool? showAnalog,
    bool? showUtcOffset,
    bool? showDate,
    bool? showDifferenceFromLocal,
    bool? showDayNight,
    String? themeMode,
  }) {
    return WidgetConfiguration(
      singleCityId: singleCityId ?? this.singleCityId,
      multiCityIds: multiCityIds ?? this.multiCityIds,
      is24Hour: is24Hour ?? this.is24Hour,
      showSeconds: showSeconds ?? this.showSeconds,
      showAnalog: showAnalog ?? this.showAnalog,
      showUtcOffset: showUtcOffset ?? this.showUtcOffset,
      showDate: showDate ?? this.showDate,
      showDifferenceFromLocal: showDifferenceFromLocal ?? this.showDifferenceFromLocal,
      showDayNight: showDayNight ?? this.showDayNight,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'singleCityId': singleCityId,
      'multiCityIds': multiCityIds,
      'is24Hour': is24Hour,
      'showSeconds': showSeconds,
      'showAnalog': showAnalog,
      'showUtcOffset': showUtcOffset,
      'showDate': showDate,
      'showDifferenceFromLocal': showDifferenceFromLocal,
      'showDayNight': showDayNight,
      'themeMode': themeMode,
    };
  }

  factory WidgetConfiguration.fromJson(Map<String, dynamic> json) {
    return WidgetConfiguration(
      singleCityId: json['singleCityId'] as String?,
      multiCityIds: (json['multiCityIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      is24Hour: json['is24Hour'] as bool? ?? false,
      showSeconds: json['showSeconds'] as bool? ?? false,
      showAnalog: json['showAnalog'] as bool? ?? false,
      showUtcOffset: json['showUtcOffset'] as bool? ?? true,
      showDate: json['showDate'] as bool? ?? true,
      showDifferenceFromLocal: json['showDifferenceFromLocal'] as bool? ?? true,
      showDayNight: json['showDayNight'] as bool? ?? true,
      themeMode: json['themeMode'] as String? ?? 'system',
    );
  }
}
