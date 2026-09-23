import WidgetKit
import SwiftUI
import AppIntents

/// Timeline Entry passed to SwiftUI widget views.
public struct WorldClockEntry: TimelineEntry {
    public let date: Date
    public let city: WidgetCityData
    public let config: WidgetConfiguration
    public let multiCities: [WidgetCityData]

    public init(
        date: Date,
        city: WidgetCityData,
        config: WidgetConfiguration,
        multiCities: [WidgetCityData] = []
    ) {
        self.date = date
        self.city = city
        self.config = config
        self.multiCities = multiCities
    }
}

// MARK: - AppIntent Timeline Provider for Configurable Single City Widget
@available(macOS 14.0, *)
public struct WorldClockAppIntentTimelineProvider: AppIntentTimelineProvider {
    public typealias Entry = WorldClockEntry
    public typealias Intent = SelectCityIntent

    public init() {}

    public func placeholder(in context: Context) -> WorldClockEntry {
        let sample = WidgetPayload.sample
        let city = sample.selectedCity ?? WidgetPayload.fallbackCities.first!
        return WorldClockEntry(date: Date(), city: city, config: sample.configuration)
    }

    public func snapshot(for configuration: SelectCityIntent, in context: Context) async -> WorldClockEntry {
        let city = resolveCity(from: configuration)
        let config = resolveConfig(from: configuration)
        return WorldClockEntry(date: Date(), city: city, config: config)
    }

    public func timeline(for configuration: SelectCityIntent, in context: Context) async -> Timeline<WorldClockEntry> {
        let city = resolveCity(from: configuration)
        let config = resolveConfig(from: configuration)
        let currentDate = Date()
        var entries: [WorldClockEntry] = []

        // Generate 1-minute steps for the next 15 minutes to ensure accurate clock ticking
        // while respecting macOS WidgetKit timeline execution budgets.
        for minuteOffset in 0..<15 {
            if let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate) {
                entries.append(WorldClockEntry(date: entryDate, city: city, config: config))
            }
        }

        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        return Timeline(entries: entries, policy: .after(refreshDate))
    }

    private func resolveCity(from intent: SelectCityIntent) -> WidgetCityData {
        if let intentCity = intent.city,
           let found = WidgetStorageHelper.findCity(by: intentCity.id) {
            return found
        }
        let payload = WidgetStorageHelper.loadPayload()
        if let selected = payload.selectedCity {
            return selected
        }
        let all = WidgetStorageHelper.loadAllCities()
        return all.first ?? WidgetPayload.fallbackCities.first!
    }

    private func resolveConfig(from intent: SelectCityIntent) -> WidgetConfiguration {
        let base = WidgetStorageHelper.loadPayload().configuration
        var config = base
        config.is24Hour = (intent.timeFormat == .twentyFourHour)
        config.showSeconds = intent.showSeconds
        config.showDate = intent.showDate
        config.showUtcOffset = intent.showUtcOffset
        config.showAnalog = intent.showAnalog
        return config
    }
}

// MARK: - Multi-City Timeline Provider for Large Widget
public struct WorldClockMultiCityTimelineProvider: TimelineProvider {
    public typealias Entry = WorldClockEntry

    public init() {}

    public func placeholder(in context: Context) -> WorldClockEntry {
        let sample = WidgetPayload.sample
        let city = sample.selectedCity ?? WidgetPayload.fallbackCities.first!
        return WorldClockEntry(
            date: Date(),
            city: city,
            config: sample.configuration,
            multiCities: sample.multiCities
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (WorldClockEntry) -> Void) {
        let payload = WidgetStorageHelper.loadPayload()
        let city = payload.selectedCity ?? WidgetPayload.fallbackCities.first!
        let multi = payload.multiCities.isEmpty ? WidgetPayload.sample.multiCities : payload.multiCities
        let entry = WorldClockEntry(date: Date(), city: city, config: payload.configuration, multiCities: multi)
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<WorldClockEntry>) -> Void) {
        let payload = WidgetStorageHelper.loadPayload()
        let city = payload.selectedCity ?? WidgetPayload.fallbackCities.first!
        let multi = payload.multiCities.isEmpty ? WidgetPayload.sample.multiCities : payload.multiCities
        let currentDate = Date()
        var entries: [WorldClockEntry] = []

        for minuteOffset in 0..<15 {
            if let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate) {
                entries.append(WorldClockEntry(date: entryDate, city: city, config: payload.configuration, multiCities: multi))
            }
        }

        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}
