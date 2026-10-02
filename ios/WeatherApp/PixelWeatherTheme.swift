import SwiftUI

/// A small, value-type palette that is derived from the weather response already in memory.
/// It deliberately contains no network image or animation state.
enum PixelWeatherTheme: String, Equatable {
    case clearDay
    case clearNight
    case cloudy
    case rainy
    case stormy
    case snowy
    case misty
    case neutral

    static func make(condition: String, epochSeconds: Int?, timeZoneOffset: Int?) -> PixelWeatherTheme {
        switch condition {
        case "Clear":
            return isNight(epochSeconds: epochSeconds, timeZoneOffset: timeZoneOffset) ? .clearNight : .clearDay
        case "Clouds":
            return .cloudy
        case "Rain", "Drizzle":
            return .rainy
        case "Thunderstorm":
            return .stormy
        case "Snow":
            return .snowy
        case "Mist", "Fog", "Haze", "Smoke", "Dust", "Sand", "Ash", "Squall", "Tornado":
            return .misty
        default:
            return .neutral
        }
    }

    var skyColor: Color {
        switch self {
        case .clearDay: .init(red: 0.26, green: 0.72, blue: 0.91)
        case .clearNight: .init(red: 0.08, green: 0.12, blue: 0.31)
        case .cloudy: .init(red: 0.34, green: 0.44, blue: 0.56)
        case .rainy: .init(red: 0.08, green: 0.31, blue: 0.49)
        case .stormy: .init(red: 0.18, green: 0.13, blue: 0.39)
        case .snowy: .init(red: 0.63, green: 0.82, blue: 0.91)
        case .misty: .init(red: 0.45, green: 0.54, blue: 0.60)
        case .neutral: .init(red: 0.20, green: 0.33, blue: 0.43)
        }
    }

    var horizonColor: Color {
        switch self {
        case .clearDay: .init(red: 0.18, green: 0.55, blue: 0.39)
        case .clearNight: .init(red: 0.11, green: 0.25, blue: 0.29)
        case .cloudy: .init(red: 0.23, green: 0.40, blue: 0.40)
        case .rainy: .init(red: 0.06, green: 0.25, blue: 0.29)
        case .stormy: .init(red: 0.13, green: 0.12, blue: 0.27)
        case .snowy: .init(red: 0.88, green: 0.94, blue: 0.96)
        case .misty: .init(red: 0.36, green: 0.47, blue: 0.46)
        case .neutral: .init(red: 0.16, green: 0.37, blue: 0.34)
        }
    }

    var panelColor: Color { .init(red: 0.05, green: 0.10, blue: 0.16) }
    var panelTextColor: Color { .white }
    var accentColor: Color {
        switch self {
        case .clearDay: .init(red: 1.0, green: 0.78, blue: 0.20)
        case .clearNight: .init(red: 0.72, green: 0.68, blue: 1.0)
        case .cloudy: .init(red: 0.72, green: 0.84, blue: 0.92)
        case .rainy: .init(red: 0.28, green: 0.82, blue: 0.94)
        case .stormy: .init(red: 0.93, green: 0.76, blue: 0.24)
        case .snowy: .init(red: 0.14, green: 0.35, blue: 0.60)
        case .misty: .init(red: 0.82, green: 0.88, blue: 0.86)
        case .neutral: .init(red: 0.41, green: 0.89, blue: 0.71)
        }
    }

    var sceneSymbol: String {
        switch self {
        case .clearDay: "sun.max.fill"
        case .clearNight: "moon.stars.fill"
        case .cloudy: "cloud.fill"
        case .rainy: "cloud.rain.fill"
        case .stormy: "cloud.bolt.rain.fill"
        case .snowy: "snowflake"
        case .misty: "cloud.fog.fill"
        case .neutral: "cloud.sun.fill"
        }
    }

    var supportsAmbientMotion: Bool {
        self == .rainy || self == .stormy || self == .snowy || self == .cloudy
    }

    private static func isNight(epochSeconds: Int?, timeZoneOffset: Int?) -> Bool {
        guard let epochSeconds else { return false }
        let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: timeZoneOffset ?? 0) ?? .current
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 20
    }
}

struct PixelPanel<Content: View>: View {
    let theme: PixelWeatherTheme
    let content: Content

    init(theme: PixelWeatherTheme, @ViewBuilder content: () -> Content) {
        self.theme = theme
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .background(theme.panelColor.opacity(0.94))
            .overlay {
                Rectangle()
                    .stroke(theme.accentColor.opacity(0.85), lineWidth: 2)
            }
            .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
            .shadow(color: .black.opacity(0.28), radius: 0, x: 3, y: 3)
    }
}
