import WidgetKit
import SwiftUI
import AppIntents

/// Primary WorldClock Desktop Widget supporting Small, Medium, and Large sizes with AppIntent configuration
public struct WorldClockWidget: Widget {
    public static let kind: String = "com.dharampal.worldclock.widget"

    public init() {}

    public var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: Self.kind,
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
public struct WorldClockMultiCityWidget: Widget {
    public static let kind: String = "com.dharampal.worldclock.multi_widget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: Self.kind,
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
