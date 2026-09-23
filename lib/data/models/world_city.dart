class WorldCity {
  final String id;
  final String name;
  final String country;
  final String countryCode;
  final String timezoneId;
  final double latitude;
  final double longitude;
  final bool isPopular;
  final String flagEmoji;
  final List<String> searchKeywords;

  const WorldCity({
    required this.id,
    required this.name,
    required this.country,
    required this.countryCode,
    required this.timezoneId,
    required this.latitude,
    required this.longitude,
    this.isPopular = false,
    required this.flagEmoji,
    this.searchKeywords = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country': country,
      'countryCode': countryCode,
      'timezoneId': timezoneId,
      'latitude': latitude,
      'longitude': longitude,
      'isPopular': isPopular,
      'flagEmoji': flagEmoji,
      'searchKeywords': searchKeywords,
    };
  }

  factory WorldCity.fromJson(Map<String, dynamic> json) {
    return WorldCity(
      id: json['id'] as String,
      name: json['name'] as String,
      country: json['country'] as String,
      countryCode: json['countryCode'] as String? ?? '',
      timezoneId: json['timezoneId'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      isPopular: json['isPopular'] as bool? ?? false,
      flagEmoji: json['flagEmoji'] as String? ?? '🌐',
      searchKeywords: (json['searchKeywords'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorldCity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
