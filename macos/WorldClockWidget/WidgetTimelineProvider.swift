import WidgetKit
import SwiftUI

/// Timeline Entry passed to SwiftUI widget views.
public struct WorldClockEntry: TimelineEntry {
    public let date: Date
    public let payload: WidgetPayload

    public init(date: Date, payload: WidgetPayload) {
        self.date = date
        self.payload = payload
    }
}

/// WidgetKit Timeline Provider generating battery-friendly timeline entries.
public struct WorldClockTimelineProvider: TimelineProvider {
    public typealias Entry = WorldClockEntry

    public init() {}

    public func placeholder(in context: Context) -> WorldClockEntry {
        WorldClockEntry(date: Date(), payload: WidgetPayload.sample)
    }

    public func getSnapshot(in context: Context, completion: @escaping (WorldClockEntry) -> Void) {
        let payload = WidgetStorageHelper.loadPayload()
        let entry = WorldClockEntry(date: Date(), payload: payload)
        completion(entry)
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<WorldClockEntry>) -> Void) {
        let payload = WidgetStorageHelper.loadPayload()
        let currentDate = Date()
        var entries: [WorldClockEntry] = []

        // Generate 1-minute steps for the next 15 minutes to guarantee minute-level accuracy
        // while respecting macOS WidgetKit timeline execution budgets.
        for minuteOffset in 0..<15 {
            if let entryDate = Calendar.current.date(byAdding: .minute, value: minuteOffset, to: currentDate) {
                entries.append(WorldClockEntry(date: entryDate, payload: payload))
            }
        }

        // Request a refresh after 15 minutes or when the app notifies WidgetCenter
        let refreshDate = Calendar.current.date(byAdding: .minute, value: 15, to: currentDate) ?? currentDate.addingTimeInterval(900)
        let timeline = Timeline(entries: entries, policy: .after(refreshDate))
        completion(timeline)
    }
}
