import SwiftUI
import WidgetKit

// MARK: - Glass Widget Background Modifier
struct GlassWidgetBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Deep ambient dark glass gradient
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.07, green: 0.09, blue: 0.14), Color(red: 0.04, green: 0.05, blue: 0.08)]
                            : [Color(red: 0.96, green: 0.97, blue: 0.99), Color(red: 0.90, green: 0.92, blue: 0.95)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    // Translucent system ultraThin material
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.24 : 0.45),
                                Color.white.opacity(colorScheme == .dark ? 0.06 : 0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: 22))
    }
}

extension View {
    func glassWidgetBackground() -> some View {
        self.modifier(GlassWidgetBackground())
    }
}

// MARK: - Native SwiftUI Analog Clock View
public struct AnalogClockWidgetView: View {
    public let date: Date
    public let timeZone: TimeZone
    public let size: CGFloat
    public let isDay: Bool

    public init(date: Date, timeZone: TimeZone, size: CGFloat = 64, isDay: Bool = true) {
        self.date = date
        self.timeZone = timeZone
        self.size = size
        self.isDay = isDay
    }

    public var body: some View {
        var cal = Calendar.current
        cal.timeZone = timeZone
        let hour = cal.component(.hour, from: date) % 12
        let minute = cal.component(.minute, from: date)
        let second = cal.component(.second, from: date)

        let hourAngle = Double(hour) * 30.0 + Double(minute) * 0.5
        let minuteAngle = Double(minute) * 6.0 + Double(second) * 0.1

        return ZStack {
            // Dial background
            Circle()
                .fill(Color.black.opacity(0.35))
                .overlay(
                    Circle()
                        .strokeBorder(
                            isDay
                                ? Color(red: 0.96, green: 0.62, blue: 0.18).opacity(0.4)
                                : Color(red: 0.38, green: 0.45, blue: 0.98).opacity(0.3),
                            lineWidth: 1.5
                        )
                )

            // Hour Markers (12, 3, 6, 9)
            ForEach(0..<4) { i in
                Rectangle()
                    .fill(Color.white.opacity(0.6))
                    .frame(width: 1.5, height: 4)
                    .offset(y: -size / 2 + 5)
                    .rotationEffect(.degrees(Double(i) * 90))
            }

            // Hour Hand
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color.white)
                .frame(width: 2.5, height: size * 0.28)
                .offset(y: -size * 0.14)
                .rotationEffect(.degrees(hourAngle))

            // Minute Hand
            RoundedRectangle(cornerRadius: 1)
                .fill(Color.white.opacity(0.9))
                .frame(width: 1.8, height: size * 0.38)
                .offset(y: -size * 0.19)
                .rotationEffect(.degrees(minuteAngle))

            // Center Pin
            Circle()
                .fill(Color(red: 0.23, green: 0.51, blue: 0.96))
                .frame(width: 4, height: 4)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Small Widget View (170x170 pt)
public struct SmallWidgetView: View {
    public let city: WidgetCityData
    public let config: WidgetConfiguration
    public let date: Date

    public init(city: WidgetCityData, config: WidgetConfiguration, date: Date = Date()) {
        self.city = city
        self.config = config
        self.date = date
    }

    public var body: some View {
        let isDay = city.isDaytime(at: date)
        let deepLinkUrl = URL(string: "worldclock://city/\(city.id)")

        VStack(alignment: .leading, spacing: 0) {
            // Header: Flag + Name + Day/Night SF Symbol
            HStack(spacing: 5) {
                Text(city.flagEmoji)
                    .font(.system(size: 13))

                Text(city.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                Spacer(minLength: 0)

                if config.showDayNight {
                    Image(systemName: isDay ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: 12))
                        .foregroundColor(isDay ? Color(red: 0.96, green: 0.62, blue: 0.18) : Color(red: 0.45, green: 0.55, blue: 0.95))
                }
            }

            Text(city.country)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .padding(.top, 1)

            Spacer()

            // Center: Analog or Digital Clock
            if config.showAnalog {
                HStack {
                    Spacer()
                    AnalogClockWidgetView(date: date, timeZone: city.timeZone, size: 68, isDay: isDay)
                    Spacer()
                }
            } else {
                VStack(alignment: .leading, spacing: 1) {
                    Text(city.formatTime(for: date, is24Hour: config.is24Hour, showSeconds: config.showSeconds))
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .minimumScaleFactor(0.75)
                        .lineLimit(1)

                    if config.showDifferenceFromLocal {
                        Text(city.differenceFromLocalString(for: date))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(Color(red: 0.23, green: 0.51, blue: 0.96))
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // Footer: Date + UTC Offset
            HStack {
                if config.showDate {
                    Text(city.formatDate(for: date, full: false))
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 0)

                if config.showUtcOffset {
                    Text(city.utcOffsetString(for: date))
                        .font(.system(size: 9, weight: .semibold, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 2)
                        .background(Color.white.opacity(0.12))
                        .cornerRadius(4)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(14)
        .widgetURL(deepLinkUrl)
    }
}

// MARK: - Medium Widget View (364x170 pt)
public struct MediumWidgetView: View {
    public let city: WidgetCityData
    public let config: WidgetConfiguration
    public let date: Date

    public init(city: WidgetCityData, config: WidgetConfiguration, date: Date = Date()) {
        self.city = city
        self.config = config
        self.date = date
    }

    public var body: some View {
        let isDay = city.isDaytime(at: date)
        let deepLinkUrl = URL(string: "worldclock://city/\(city.id)")

        HStack(spacing: 16) {
            // Left: Analog Clock Dial
            VStack {
                Spacer()
                AnalogClockWidgetView(date: date, timeZone: city.timeZone, size: 88, isDay: isDay)
                Spacer()
            }
            .frame(width: 96)

            // Right: City details, digital time, full date, relative difference
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 6) {
                    Text(city.flagEmoji)
                        .font(.system(size: 14))

                    Text(city.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                        .lineLimit(1)

                    Text("• \(city.country)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 0)

                    if config.showDayNight {
                        Image(systemName: isDay ? "sun.max.fill" : "moon.stars.fill")
                            .font(.system(size: 13))
                            .foregroundColor(isDay ? Color(red: 0.96, green: 0.62, blue: 0.18) : Color(red: 0.45, green: 0.55, blue: 0.95))
                    }
                }

                Spacer()

                // Large Digital Time
                Text(city.formatTime(for: date, is24Hour: config.is24Hour, showSeconds: config.showSeconds))
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                if config.showDate {
                    Text(city.formatDate(for: date, full: true))
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .padding(.top, 2)
                }

                Spacer()

                // Bottom Badges
                HStack(spacing: 6) {
                    if config.showUtcOffset {
                        Text(city.utcOffsetString(for: date))
                            .font(.system(size: 9, weight: .semibold, design: .monospaced))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(4)
                            .foregroundColor(.secondary)
                    }

                    if config.showDifferenceFromLocal {
                        Text(city.differenceFromLocalString(for: date))
                            .font(.system(size: 10, weight: .semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.23, green: 0.51, blue: 0.96).opacity(0.18))
                            .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(14)
        .widgetURL(deepLinkUrl)
    }
}

// MARK: - Large Widget View (364x382 pt, Multi-Clock Grid)
public struct LargeWidgetView: View {
    public let cities: [WidgetCityData]
    public let config: WidgetConfiguration
    public let date: Date

    public init(cities: [WidgetCityData], config: WidgetConfiguration, date: Date = Date()) {
        self.cities = cities
        self.config = config
        self.date = date
    }

    public var body: some View {
        let displayCities = Array(cities.prefix(6))

        VStack(spacing: 8) {
            // Widget Title Bar
            HStack {
                Label("WORLD CLOCK", systemImage: "globe.americas.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0))

                Spacer()

                Text(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .none))
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 2)

            // Multi-City List
            ForEach(displayCities) { city in
                let isDay = city.isDaytime(at: date)
                let cellUrl = URL(string: "worldclock://city/\(city.id)")!

                Link(destination: cellUrl) {
                    HStack(spacing: 8) {
                        // Mini Analog Dial or Flag
                        AnalogClockWidgetView(date: date, timeZone: city.timeZone, size: 28, isDay: isDay)

                        VStack(alignment: .leading, spacing: 1) {
                            HStack(spacing: 4) {
                                Text(city.flagEmoji)
                                    .font(.system(size: 11))
                                Text(city.name)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.primary)
                                    .lineLimit(1)
                            }
                            Text(city.country)
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }

                        Spacer()

                        // Day/Night Symbol
                        Image(systemName: isDay ? "sun.max.fill" : "moon.stars.fill")
                            .font(.system(size: 10))
                            .foregroundColor(isDay ? Color(red: 0.96, green: 0.62, blue: 0.18) : Color(red: 0.45, green: 0.55, blue: 0.95))

                        // Time & Difference Badge
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(city.formatTime(for: date, is24Hour: config.is24Hour, showSeconds: false))
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)

                            Text(city.differenceFromLocalString(for: date))
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(Color(red: 0.35, green: 0.65, blue: 1.0))
                                .lineLimit(1)
                        }
                        .frame(minWidth: 70, alignment: .trailing)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(10)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(14)
    }
}

// MARK: - Entry Views
public struct SingleWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    public let entry: WorldClockEntry

    public init(entry: WorldClockEntry) {
        self.entry = entry
    }

    public var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(city: entry.city, config: entry.config, date: entry.date)
        case .systemMedium:
            MediumWidgetView(city: entry.city, config: entry.config, date: entry.date)
        case .systemLarge:
            let cities = entry.multiCities.isEmpty ? WidgetStorageHelper.loadAllCities() : entry.multiCities
            LargeWidgetView(cities: Array(cities.prefix(6)), config: entry.config, date: entry.date)
        default:
            SmallWidgetView(city: entry.city, config: entry.config, date: entry.date)
        }
    }
}

public struct MultiWidgetEntryView: View {
    public let entry: WorldClockEntry

    public init(entry: WorldClockEntry) {
        self.entry = entry
    }

    public var body: some View {
        let cities = entry.multiCities.isEmpty ? WidgetPayload.sample.multiCities : entry.multiCities
        LargeWidgetView(cities: cities, config: entry.config, date: entry.date)
    }
}
