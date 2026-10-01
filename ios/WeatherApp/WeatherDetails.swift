import Foundation

/// A single "right now" tile: an SF Symbol, a short label, and the value to show.
struct DetailItem: Identifiable, Hashable {
    let symbol: String
    let label: String
    let value: String
    var id: String { label }
}

/// OWM's 1-5 Air Quality Index, mapped to a human label. `nil` (via `AirQualitySummary.init`)
/// means the value was outside 1...5 and shouldn't be shown rather than showing something wrong.
struct AirQualitySummary {
    let label: String
    let colorName: String
    let pm25: Double
    let pm10: Double
    let o3: Double
    let no2: Double
    let so2: Double
    let co: Double

    init?(sample: AirSample) {
        switch sample.main.aqi {
        case 1: label = "Good"; colorName = "green"
        case 2: label = "Fair"; colorName = "yellow"
        case 3: label = "Moderate"; colorName = "orange"
        case 4: label = "Poor"; colorName = "red"
        case 5: label = "Very Poor"; colorName = "purple"
        default: return nil
        }
        pm25 = sample.components.pm25
        pm10 = sample.components.pm10
        o3 = sample.components.o3
        no2 = sample.components.no2
        so2 = sample.components.so2
        co = sample.components.co
    }
}

struct HourlyForecast: Identifiable, Hashable {
    let id: Int // dt
    let time: String
    let symbol: String
    let temp: String
}

struct DailyForecast: Identifiable, Hashable {
    let id: Int // start-of-day timestamp
    let day: String
    let symbol: String
    let low: String
    let high: String
    let chanceOfRain: Int // 0...100
}

/// Builds everything `WeatherDetailsView` shows, as plain values with no SwiftUI/MapKit/network
/// dependency, so it can be unit tested the same way `CitySuggestionLogic` is.
enum WeatherDetails {

    static func build(
        weather: WeatherResponse,
        uvi: Double,
        air: AirSample?,
        forecast: ForecastResponse?,
        units: Units
    ) -> WeatherDetailsResult {
        let timeZone = TimeZone(secondsFromGMT: weather.timezone ?? 0) ?? .current

        var current: [DetailItem] = []
        current.append(DetailItem(symbol: "thermometer.variable", label: "Feels like", value: "\(Int(weather.main.feelsLike.rounded()))\(units.symbol)"))
        if let min = weather.main.tempMin, let max = weather.main.tempMax {
            current.append(DetailItem(symbol: "arrow.up.arrow.down", label: "Low / High", value: "\(Int(min.rounded()))° / \(Int(max.rounded()))\(units.symbol)"))
        }
        current.append(DetailItem(symbol: "humidity", label: "Humidity", value: "\(weather.main.humidity)%"))
        if let pressure = weather.main.pressure {
            current.append(DetailItem(symbol: "gauge", label: "Pressure", value: pressureText(hPa: pressure, units: units)))
        }
        if let wind = weather.wind {
            current.append(DetailItem(symbol: "wind", label: "Wind", value: windText(wind, units: units)))
        }
        if let clouds = weather.clouds {
            current.append(DetailItem(symbol: "cloud", label: "Cloud cover", value: "\(clouds.all)%"))
        }
        if let visibility = weather.visibility {
            current.append(DetailItem(symbol: "eye", label: "Visibility", value: visibilityText(meters: visibility, units: units)))
        }
        if let rain = weather.rain?.oneHour {
            current.append(DetailItem(symbol: "cloud.rain", label: "Rain (1h)", value: "\(rain.formatted(.number.precision(.fractionLength(0...1)))) mm"))
        }
        if let snow = weather.snow?.oneHour {
            current.append(DetailItem(symbol: "cloud.snow", label: "Snow (1h)", value: "\(snow.formatted(.number.precision(.fractionLength(0...1)))) mm"))
        }
        if let sunrise = weather.sys?.sunrise {
            current.append(DetailItem(symbol: "sunrise", label: "Sunrise", value: timeText(epochSeconds: sunrise, timeZone: timeZone)))
        }
        if let sunset = weather.sys?.sunset {
            current.append(DetailItem(symbol: "sunset", label: "Sunset", value: timeText(epochSeconds: sunset, timeZone: timeZone)))
        }
        if uvi > 0 {
            current.append(DetailItem(symbol: "sun.max", label: "UV Index", value: uvi.formatted(.number.precision(.fractionLength(0...1)))))
        }

        let airSummary = air.flatMap(AirQualitySummary.init)

        let hourly: [HourlyForecast] = (forecast?.list ?? []).prefix(8).map { item in
            HourlyForecast(
                id: item.dt,
                time: timeText(epochSeconds: item.dt, timeZone: timeZone),
                symbol: symbolName(for: item.weather.first?.main ?? "", epochSeconds: item.dt, timeZone: timeZone),
                temp: "\(Int(item.main.temp.rounded()))\(units.symbol)"
            )
        }

        let daily = forecast.map { dailyForecasts(from: $0, timeZone: timeZone, units: units) } ?? []

        return WeatherDetailsResult(current: current, air: airSummary, hourly: hourly, daily: daily)
    }

    // MARK: Grouping

    /// Buckets 3-hourly forecast entries by the city's local calendar day, then takes each day's
    /// min/max, its most common condition, and its highest chance of rain. Capped at 5 days.
    static func dailyForecasts(from forecast: ForecastResponse, timeZone: TimeZone, units: Units) -> [DailyForecast] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone

        let grouped = Dictionary(grouping: forecast.list) { item in
            calendar.startOfDay(for: Date(timeIntervalSince1970: TimeInterval(item.dt)))
        }

        return grouped.keys.sorted().prefix(5).map { day in
            let items = grouped[day] ?? []
            let low = items.map(\.main.tempMin).min() ?? 0
            let high = items.map(\.main.tempMax).max() ?? 0
            let chance = items.map(\.pop).max() ?? 0
            let condition = mostCommonCondition(items)

            let dayLabel = day.formatted(.dateTime.weekday(.abbreviated).locale(Locale(identifier: "en_US_POSIX")).calendar(calendar))
            let epoch = Int(day.timeIntervalSince1970)

            return DailyForecast(
                id: epoch,
                day: dayLabel,
                symbol: symbolName(for: condition, epochSeconds: epoch, timeZone: timeZone),
                low: "\(Int(low.rounded()))°",
                high: "\(Int(high.rounded()))\(units.symbol)",
                chanceOfRain: Int((chance.clamped(to: 0...1) * 100).rounded())
            )
        }
    }

    private static func mostCommonCondition(_ items: [ForecastItem]) -> String {
        let counts = items.compactMap(\.weather.first?.main).reduce(into: [String: Int]()) { counts, condition in
            counts[condition, default: 0] += 1
        }
        return counts.max(by: { $0.value < $1.value })?.key ?? ""
    }

    // MARK: Formatting

    static func windText(_ wind: Wind, units: Units) -> String {
        let unit = units == .imperial ? "mph" : "m/s"
        var text = "\(Int(wind.speed.rounded())) \(unit)"
        if let deg = wind.deg {
            text += " \(compassDirection(forDegrees: deg))"
        }
        if let gust = wind.gust {
            text += ", gusts \(Int(gust.rounded())) \(unit)"
        }
        return text
    }

    /// 16-point compass rose. 0°/360° is North.
    static func compassDirection(forDegrees degrees: Int) -> String {
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                           "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let normalized = ((degrees % 360) + 360) % 360
        let index = Int((Double(normalized) / 22.5).rounded()) % directions.count
        return directions[index]
    }

    static func visibilityText(meters: Int, units: Units) -> String {
        if units == .imperial {
            let miles = Double(meters) / 1609.34
            return "\(miles.formatted(.number.precision(.fractionLength(0...1)))) mi"
        } else {
            let km = Double(meters) / 1000
            return "\(km.formatted(.number.precision(.fractionLength(0...1)))) km"
        }
    }

    static func pressureText(hPa: Int, units: Units) -> String {
        if units == .imperial {
            let inHg = Double(hPa) * 0.02953
            return "\(inHg.formatted(.number.precision(.fractionLength(2)))) inHg"
        } else {
            return "\(hPa) hPa"
        }
    }

    static func timeText(epochSeconds: Int, timeZone: TimeZone) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        return date.formatted(.dateTime.hour().minute().locale(Locale(identifier: "en_US_POSIX")).calendar(.init(identifier: .gregorian)).timeZone(timeZone))
    }

    /// Maps an OWM condition word to a local SF Symbol. Deliberately not using OWM's icon URLs:
    /// that would be another network call per icon, a third-party request leaking the user's
    /// searched location, and wouldn't work offline from the cache.
    static func symbolName(for condition: String, epochSeconds: Int, timeZone: TimeZone) -> String {
        let isNight = isNighttime(epochSeconds: epochSeconds, timeZone: timeZone)
        switch condition {
        case "Clear": return isNight ? "moon.stars" : "sun.max"
        case "Clouds": return isNight ? "cloud.moon" : "cloud.sun"
        case "Rain", "Drizzle": return "cloud.rain"
        case "Thunderstorm": return "cloud.bolt.rain"
        case "Snow": return "cloud.snow"
        case "Mist", "Fog", "Haze": return "cloud.fog"
        default: return "cloud"
        }
    }

    private static func isNighttime(epochSeconds: Int, timeZone: TimeZone) -> Bool {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let hour = calendar.component(.hour, from: Date(timeIntervalSince1970: TimeInterval(epochSeconds)))
        return hour < 6 || hour >= 20
    }
}

struct WeatherDetailsResult {
    let current: [DetailItem]
    let air: AirQualitySummary?
    let hourly: [HourlyForecast]
    let daily: [DailyForecast]
}

private extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
