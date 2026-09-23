import SwiftUI
import WidgetKit

// MARK: - Glass Widget Background Modifier
struct GlassWidgetBackground: ViewModifier {
    @Environment(\.colorScheme) var colorScheme

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Deep ambient gradient
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.06, green: 0.08, blue: 0.12), Color(red: 0.04, green: 0.05, blue: 0.08)]
                            : [Color(red: 0.95, green: 0.96, blue: 0.98), Color(red: 0.88, green: 0.90, blue: 0.94)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    // Translucent system material
                    Rectangle()
                        .fill(.ultraThinMaterial)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(colorScheme == .dark ? 0.22 : 0.40),
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
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(red: 0.85, green: 0.90, blue: 1.0))
                .frame(width: 1.8, height: size * 0.40)
                .offset(y: -size * 0.20)
                .rotationEffect(.degrees(minuteAngle))

            // Center Pin
            Circle()
                .fill(Color(red: 0.20, green: 0.51, blue: 0.98))
                .frame(width: 4.5, height: 4.5)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Small Widget View
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
        let timeStr = city.formatTime(for: date, is24Hour: config.is24Hour, showSeconds: config.showSeconds)
        let dateStr = city.formatDate(for: date, full: false)
        let offsetStr = city.utcOffsetString(for: date)

        VStack(alignment: .leading, spacing: 0) {
            // Header Row: Flag + City Name + Day/Night Icon
            HStack(spacing: 5) {
                Text(city.flagEmoji)
                    .font(.system(size: 14))
                Text(city.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
                if config.showDayNight {
                    Image(systemName: isDay ? "sun.max.fill" : "moon.stars.fill")
                        .font(.system(size: 11))
                        .foregroundColor(isDay ? Color(red: 0.96, green: 0.62, blue: 0.18) : Color(red: 0.45, green: 0.55, blue: 1.0))
                }
            }

            Text(city.country)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .padding(.top, 1)

            Spacer()

            if config.showAnalog {
                HStack {
                    Spacer()
                    AnalogClockWidgetView(date: date, timeZone: city.timeZone, size: 52, isDay: isDay)
                    Spacer()
                }
                Spacer()
            }

            // Large Readable Digital Time
            Text(timeStr)
                .font(.system(size: config.showAnalog ? 16 : 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .minimumScaleFactor(0.75)
                .lineLimit(1)

            // Date & Offset
            if config.showDate {
                Text(dateStr)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.secondary)
                    .padding(.top, 2)
            }

            if config.showUtcOffset {
                HStack(spacing: 4) {
                    Text(offsetStr)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(Color(red: 0.20, green: 0.51, blue: 0.98))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.20, green: 0.51, blue: 0.98).opacity(0.15))
                        .cornerRadius(4)
                }
                .padding(.top, 4)
            }
        }
        .padding(14)
        .widgetURL(URL(string: "worldclock://city/\(city.id)"))
    }
}

// MARK: - Medium Widget View
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
        let timeStr = city.formatTime(for: date, is24Hour: config.is24Hour, showSeconds: config.showSeconds)
        let dateStr = city.formatDate(for: date, full: true)
        let offsetStr = city.utcOffsetString(for: date)
        let diffStr = city.differenceFromLocalString(for: date)

        HStack(alignment: .center, spacing: 16) {
            // Left Column: City info, date, UTC offset, difference
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(city.flagEmoji)
                        .font(.system(size: 16))
                    Text(city.name)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.primary)
                    if config.showDayNight {
                        Image(systemName: isDay ? "sun.max.fill" : "moon.stars.fill")
                            .font(.system(size: 12))
                            .foregroundColor(isDay ? Color(red: 0.96, green: 0.62, blue: 0.18) : Color(red: 0.45, green: 0.55, blue: 1.0))
                    }
                }

                Text(city.country)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.secondary)

                Spacer()

                if config.showDate {
                    Text(dateStr)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 6) {
                    if config.showUtcOffset {
                        Text(offsetStr)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(Color(red: 0.20, green: 0.51, blue: 0.98))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color(red: 0.20, green: 0.51, blue: 0.98).opacity(0.15))
                            .cornerRadius(4)
                    }

                    if config.showDifferenceFromLocal {
                        Text(diffStr)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
            }

            Spacer()

            // Right Column: Analog clock or large digital time
            VStack(alignment: .trailing, spacing: 6) {
                if config.showAnalog {
                    AnalogClockWidgetView(date: date, timeZone: city.timeZone, size: 68, isDay: isDay)
                }

                Text(timeStr)
                    .font(.system(size: config.showAnalog ? 18 : 28, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
        }
        .padding(16)
        .widgetURL(URL(string: "worldclock://city/\(city.id)"))
    }
}

// MARK: - Large Widget View (Multi-Clock List)
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
        VStack(alignment: .leading, spacing: 10) {
            // Widget Header
            HStack {
                Image(systemName: "globe.americas.fill")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 0.20, green: 0.51, blue: 0.98))
                Text("WORLD CLOCK")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.secondary)
                    .tracking(1.0)
                Spacer()
                Text("\(cities.count) CITIES")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.20, green: 0.51, blue: 0.98))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(red: 0.20, green: 0.51, blue: 0.98).opacity(0.12))
                    .cornerRadius(4)
            }
            .padding(.bottom, 2)

            Divider()
                .background(Color.white.opacity(0.1))

            // Clocks List
            let displayCities = Array(cities.prefix(6))
            ForEach(displayCities) { city in
                let isDay = city.isDaytime(at: date)
                let timeStr = city.formatTime(for: date, is24Hour: config.is24Hour, showSeconds: false)
                let offsetStr = city.utcOffsetString(for: date)

                Link(destination: URL(string: "worldclock://city/\(city.id)")!) {
                    HStack(spacing: 8) {
                        Text(city.flagEmoji)
                            .font(.system(size: 16))

                        VStack(alignment: .leading, spacing: 1) {
                            Text(city.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.primary)
                            Text("\(city.country) • \(offsetStr)")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if config.showDayNight {
                            Image(systemName: isDay ? "sun.max.fill" : "moon.stars.fill")
                                .font(.system(size: 11))
                                .foregroundColor(isDay ? Color(red: 0.96, green: 0.62, blue: 0.18) : Color(red: 0.45, green: 0.55, blue: 1.0))
                                .padding(.trailing, 4)
                        }

                        Text(timeStr)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.vertical, 4)
                    .padding(.horizontal, 6)
                    .background(Color.white.opacity(0.03))
                    .cornerRadius(8)
                }
            }

            Spacer()
        }
        .padding(16)
    }
}
