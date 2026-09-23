import AppIntents
import WidgetKit
import SwiftUI

// MARK: - City App Entity for Widget Configuration
@available(macOS 14.0, *)
public struct CityAppEntity: AppEntity, Identifiable, Hashable {
    public let id: String
    public let name: String
    public let country: String
    public let timezoneId: String
    public let flagEmoji: String

    public init(id: String, name: String, country: String, timezoneId: String, flagEmoji: String) {
        self.id = id
        self.name = name
        self.country = country
        self.timezoneId = timezoneId
        self.flagEmoji = flagEmoji
    }

    public init(from cityData: WidgetCityData) {
        self.id = cityData.id
        self.name = cityData.name
        self.country = cityData.country
        self.timezoneId = cityData.timezoneId
        self.flagEmoji = cityData.flagEmoji
    }

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "World City")
    }

    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(country) (\(timezoneId))"
        )
    }

    public static var defaultQuery = CityEntityQuery()
}

// MARK: - Dynamic Query for City App Entity
@available(macOS 14.0, *)
public struct CityEntityQuery: EntityQuery, EntityStringQuery {
    public init() {}

    public func entities(for identifiers: [String]) async throws -> [CityAppEntity] {
        let allCities = WidgetStorageHelper.loadAllCities()
        return allCities
            .filter { identifiers.contains($0.id) || identifiers.contains($0.timezoneId) }
            .map { CityAppEntity(from: $0) }
    }

    public func suggestedEntities() async throws -> [CityAppEntity] {
        let allCities = WidgetStorageHelper.loadAllCities()
        return allCities.map { CityAppEntity(from: $0) }
    }

    public func entities(matching string: String) async throws -> [CityAppEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let allCities = WidgetStorageHelper.loadAllCities()
        if query.isEmpty {
            return allCities.map { CityAppEntity(from: $0) }
        }
        return allCities
            .filter {
                $0.name.lowercased().contains(query) ||
                $0.country.lowercased().contains(query) ||
                $0.timezoneId.lowercased().contains(query)
            }
            .map { CityAppEntity(from: $0) }
    }
}

// MARK: - Time Format Enum
@available(macOS 14.0, *)
public enum TimeFormatAppEnum: String, AppEnum {
    case twelveHour = "12-Hour"
    case twentyFourHour = "24-Hour"

    public static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Time Format")
    }

    public static var caseDisplayRepresentations: [TimeFormatAppEnum: DisplayRepresentation] {
        [
            .twelveHour: DisplayRepresentation(title: "12-Hour (AM/PM)"),
            .twentyFourHour: DisplayRepresentation(title: "24-Hour")
        ]
    }
}

// MARK: - Widget Configuration Intent
@available(macOS 14.0, *)
public struct SelectCityIntent: WidgetConfigurationIntent {
    public static var title: LocalizedStringResource = "Configure World Clock"
    public static var description: IntentDescription = IntentDescription("Choose a world city and customize clock display options.")

    @Parameter(title: "City")
    public var city: CityAppEntity?

    @Parameter(title: "Time Format", default: .twelveHour)
    public var timeFormat: TimeFormatAppEnum

    @Parameter(title: "Show Seconds", default: false)
    public var showSeconds: Bool

    @Parameter(title: "Show Date", default: true)
    public var showDate: Bool

    @Parameter(title: "Show UTC Offset", default: true)
    public var showUtcOffset: Bool

    @Parameter(title: "Analog Clock Dial", default: false)
    public var showAnalog: Bool

    public init() {
        self.timeFormat = .twelveHour
        self.showSeconds = false
        self.showDate = true
        self.showUtcOffset = true
        self.showAnalog = false
    }

    public init(
        city: CityAppEntity? = nil,
        timeFormat: TimeFormatAppEnum = .twelveHour,
        showSeconds: Bool = false,
        showDate: Bool = true,
        showUtcOffset: Bool = true,
        showAnalog: Bool = false
    ) {
        self.city = city
        self.timeFormat = timeFormat
        self.showSeconds = showSeconds
        self.showDate = showDate
        self.showUtcOffset = showUtcOffset
        self.showAnalog = showAnalog
    }
}
