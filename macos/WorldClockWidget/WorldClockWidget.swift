import WidgetKit
import SwiftUI
#if canImport(AppIntents)
import AppIntents
#endif

/// Primary WorldClock Desktop Widget supporting Small, Medium, and Large sizes with AppIntent configuration
@available(macOS 14.0, *)
public struct WorldClockWidget: Widget {
    public static let kind: String = "com.dharampal.worldclock.widget"
    public let kind: String = "com.dharampal.worldclock.widget"

    public init() {}

    public var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: SelectCityIntent.self,
            provider: WorldClockAppIntentTimelineProvider()
        ) { entry in
            SingleWidgetEntryView(entry: entry)
                .glassWidgetBackground()
        }
        .configurationDisplayName("WorldClock")
        .description("World Clock and timezone information directly on your Mac desktop.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

/// Multi-City Desktop Widget (Large size) for quick multi-clock comparison
@available(macOS 11.0, *)
public struct WorldClockMultiCityWidget: Widget {
    public static let kind: String = "com.dharampal.worldclock.multi_widget"
    public let kind: String = "com.dharampal.worldclock.multi_widget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: WorldClockMultiCityTimelineProvider()
        ) { entry in
            MultiWidgetEntryView(entry: entry)
                .glassWidgetBackground()
        }
        .configurationDisplayName("WorldClock (Multi-City)")
        .description("Compare live times across multiple global cities simultaneously on your desktop.")
        .supportedFamilies([.systemLarge])
    }
}
