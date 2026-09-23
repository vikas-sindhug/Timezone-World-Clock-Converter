import WidgetKit
import SwiftUI

/// Single City Desktop Widget (Small and Medium sizes)
public struct WorldClockSingleWidget: Widget {
    public let kind: String = "com.worldclock.single_widget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorldClockTimelineProvider()) { entry in
            SingleWidgetEntryView(entry: entry)
                .glassWidgetBackground()
        }
        .configurationDisplayName("World Clock")
        .description("Track the live time and solar status of your favorite global city.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

/// View switcher for Single City Widget based on widget family.
struct SingleWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: WorldClockEntry

    var body: some View {
        let city = entry.payload.selectedCity ?? entry.payload.multiCities.first ?? WidgetPayload.sample.selectedCity!
        let config = entry.payload.configuration

        switch family {
        case .systemSmall:
            SmallWidgetView(city: city, config: config, date: entry.date)
        case .systemMedium:
            MediumWidgetView(city: city, config: config, date: entry.date)
        default:
            SmallWidgetView(city: city, config: config, date: entry.date)
        }
    }
}

/// Multi-City Desktop Widget (Large size)
public struct WorldClockMultiWidget: Widget {
    public let kind: String = "com.worldclock.multi_widget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorldClockTimelineProvider()) { entry in
            MultiWidgetEntryView(entry: entry)
                .glassWidgetBackground()
        }
        .configurationDisplayName("World Clock (Multi-City)")
        .description("Compare live times across multiple global cities simultaneously.")
        .supportedFamilies([.systemLarge])
    }
}

/// View for Multi-City Widget.
struct MultiWidgetEntryView: View {
    let entry: WorldClockEntry

    var body: some View {
        let cities = entry.payload.multiCities.isEmpty ? WidgetPayload.sample.multiCities : entry.payload.multiCities
        LargeWidgetView(cities: cities, config: entry.payload.configuration, date: entry.date)
    }
}
