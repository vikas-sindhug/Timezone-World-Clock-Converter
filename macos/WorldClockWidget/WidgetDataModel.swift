import Foundation

/// Data structure representing a city shared between Flutter and WidgetKit.
public struct WidgetCityData: Codable, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let country: String
    public let timezoneId: String
    public let flagEmoji: String
    public let latitude: Double
    public let longitude: Double
    public let isFavorite: Bool

    public init(
        id: String,
        name: String,
        country: String,
        timezoneId: String,
        flagEmoji: String,
        latitude: Double,
        longitude: Double,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.timezoneId = timezoneId
        self.flagEmoji = flagEmoji
        self.latitude = latitude
        self.longitude = longitude
        self.isFavorite = isFavorite
    }

    /// Returns the Foundation TimeZone for this city.
    public var timeZone: TimeZone {
        TimeZone(identifier: timezoneId) ?? TimeZone.current
    }

    /// Computes the UTC offset string (e.g., "UTC+09:00", "UTC-04:00", "UTC+05:30") for a given date.
    public func utcOffsetString(for date: Date = Date()) -> String {
        let seconds = timeZone.secondsFromGMT(for: date)
        let hours = seconds / 3600
        let minutes = abs((seconds % 3600) / 60)
        let sign = hours >= 0 ? "+" : "-"
        return String(format: "UTC%@%02d:%02d", sign, abs(hours), minutes)
    }

    /// Computes the difference string relative to the system's local timezone.
    public func differenceFromLocalString(for date: Date = Date()) -> String {
        let localSeconds = TimeZone.current.secondsFromGMT(for: date)
        let citySeconds = timeZone.secondsFromGMT(for: date)
        let diffSeconds = citySeconds - localSeconds
        if diffSeconds == 0 {
            return "Same time as local"
        }
        let totalMinutes = abs(diffSeconds) / 60
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60
        let sign = diffSeconds > 0 ? "+" : "-"
        if minutes == 0 {
            return "\(sign)\(hours)h from local"
        } else {
            return "\(sign)\(hours)h \(minutes)m from local"
        }
    }

    /// Approximate solar day/night calculation using solar elevation.
    public func isDaytime(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        var calInTz = calendar
        calInTz.timeZone = timeZone
        let hour = calInTz.component(.hour, from: date)
        // General daytime window 06:00 to 18:00 in local timezone
        return hour >= 6 && hour < 18
    }

    /// Formatted time string according to 24h setting.
    public func formatTime(for date: Date, is24Hour: Bool, showSeconds: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        if is24Hour {
            formatter.dateFormat = showSeconds ? "HH:mm:ss" : "HH:mm"
        } else {
            formatter.dateFormat = showSeconds ? "h:mm:ss a" : "h:mm a"
        }
        return formatter.string(from: date)
    }

    /// Formatted date string (e.g., "Tue, Sep 22" or "Tuesday, September 22").
    public func formatDate(for date: Date, full: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = full ? "EEEE, MMMM d" : "EEE, MMM d"
        return formatter.string(from: date)
    }
}

/// Widget appearance and display toggles.
public struct WidgetConfiguration: Codable, Hashable {
    public var is24Hour: Bool
    public var showSeconds: Bool
    public var showAnalog: Bool
    public var showUtcOffset: Bool
    public var showDate: Bool
    public var showDifferenceFromLocal: Bool
    public var showDayNight: Bool
    public var themeMode: String // "system", "dark", "light"

    public init(
        is24Hour: Bool = false,
        showSeconds: Bool = false,
        showAnalog: Bool = false,
        showUtcOffset: Bool = true,
        showDate: Bool = true,
        showDifferenceFromLocal: Bool = true,
        showDayNight: Bool = true,
        themeMode: String = "system"
    ) {
        self.is24Hour = is24Hour
        self.showSeconds = showSeconds
        self.showAnalog = showAnalog
        self.showUtcOffset = showUtcOffset
        self.showDate = showDate
        self.showDifferenceFromLocal = showDifferenceFromLocal
        self.showDayNight = showDayNight
        self.themeMode = themeMode
    }

    public static let `default` = WidgetConfiguration()
}

/// Complete synchronization payload stored in App Group storage.
public struct WidgetPayload: Codable {
    public let selectedCity: WidgetCityData?
    public let multiCities: [WidgetCityData]
    public let configuration: WidgetConfiguration
    public let updatedAt: Double

    public init(
        selectedCity: WidgetCityData?,
        multiCities: [WidgetCityData],
        configuration: WidgetConfiguration,
        updatedAt: Double = Date().timeIntervalSince1970
    ) {
        self.selectedCity = selectedCity
        self.multiCities = multiCities
        self.configuration = configuration
        self.updatedAt = updatedAt
    }

    /// Sample preview payload when no user data has been configured yet.
    public static let sample: WidgetPayload = {
        let tokyo = WidgetCityData(
            id: "tokyo_jp",
            name: "Tokyo",
            country: "Japan",
            timezoneId: "Asia/Tokyo",
            flagEmoji: "🇯🇵",
            latitude: 35.6762,
            longitude: 139.6503,
            isFavorite: true
        )
        let london = WidgetCityData(
            id: "london_gb",
            name: "London",
            country: "United Kingdom",
            timezoneId: "Europe/London",
            flagEmoji: "🇬🇧",
            latitude: 51.5074,
            longitude: -0.1278,
            isFavorite: false
        )
        let newYork = WidgetCityData(
            id: "new_york_us",
            name: "New York",
            country: "United States",
            timezoneId: "America/New_York",
            flagEmoji: "🇺🇸",
            latitude: 40.7128,
            longitude: -74.0060,
            isFavorite: false
        )
        let dubai = WidgetCityData(
            id: "dubai_ae",
            name: "Dubai",
            country: "United Arab Emirates",
            timezoneId: "Asia/Dubai",
            flagEmoji: "🇦🇪",
            latitude: 25.2048,
            longitude: 55.2708,
            isFavorite: false
        )
        return WidgetPayload(
            selectedCity: tokyo,
            multiCities: [tokyo, london, newYork, dubai],
            configuration: WidgetConfiguration.default
        )
    }()
}

/// Helper for reading widget payload from App Group UserDefaults.
public enum WidgetStorageHelper {
    public static let appGroupId = "group.com.worldclock.app"
    public static let payloadKey = "world_clock_widget_data"

    /// Loads the shared payload from App Group UserDefaults, falling back to sample data.
    public static func loadPayload() -> WidgetPayload {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupId),
              let jsonString = sharedDefaults.string(forKey: payloadKey),
              let data = jsonString.data(using: .utf8) else {
            return WidgetPayload.sample
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(WidgetPayload.self, from: data)
        } catch {
            return WidgetPayload.sample
        }
    }
}
