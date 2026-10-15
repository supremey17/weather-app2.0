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

    /// - Parameters:
    ///   - forecast: OWM's 3-hourly /forecast. Only used as a fallback when `openMeteo` has no data.
    ///   - openMeteo: Open-Meteo hourly/daily data, the preferred source for the forecast sections
    ///     and today's Low / High. `nil` when that request failed.
    ///   - now: Injected so tests are deterministic.
    static func build(
        weather: WeatherResponse,
        uvi: Double,
        air: AirSample?,
        forecast: ForecastResponse?,
        openMeteo: OpenMeteoResponse? = nil,
        units: Units,
        now: Date = Date()
    ) -> WeatherDetailsResult {
        // Prefer Open-Meteo's IANA zone (DST-aware across the 5 days); otherwise OWM's fixed offset.
        let timeZone = openMeteo?.timezone.flatMap { TimeZone(identifier: $0) }
            ?? TimeZone(secondsFromGMT: weather.timezone ?? 0)
            ?? .current
        let nowEpoch = Int(now.timeIntervalSince1970)

        var current: [DetailItem] = []
        current.append(DetailItem(symbol: "thermometer.variable", label: "Feels like", value: "\(Int(weather.main.feelsLike.rounded()))\(units.symbol)"))
        // Deliberately not /weather's temp_min/temp_max: that's the spread across the metro area
        // right now, not today's range.
        if let range = todayRange(currentTemp: weather.main.temp, openMeteo: openMeteo, forecast: forecast, nowEpoch: nowEpoch, timeZone: timeZone) {
            current.append(DetailItem(symbol: "arrow.up.arrow.down", label: "Low / High", value: "\(Int(range.low.rounded()))° / \(Int(range.high.rounded()))\(units.symbol)"))
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

        var hourly: [HourlyForecast] = openMeteo?.hourly.map {
            hourlyForecasts(from: $0, nowEpoch: nowEpoch, timeZone: timeZone, units: units)
        } ?? []
        if hourly.isEmpty {
            // Fallback: OWM's free forecast is 3-hourly, so 8 entries cover the next 24 hours.
            hourly = (forecast?.list ?? []).prefix(8).map { item in
                HourlyForecast(
                    id: item.dt,
                    time: timeText(epochSeconds: item.dt, timeZone: timeZone),
                    symbol: symbolName(for: item.weather.first?.main ?? "", epochSeconds: item.dt, timeZone: timeZone),
                    temp: "\(Int(item.main.temp.rounded()))\(units.symbol)"
                )
            }
        }

        var daily: [DailyForecast] = openMeteo?.daily.map {
            dailyForecasts(from: $0, nowEpoch: nowEpoch, timeZone: timeZone, units: units)
        } ?? []
        if daily.isEmpty {
            daily = forecast.map { dailyForecasts(from: $0, timeZone: timeZone, units: units) } ?? []
        }

        return WeatherDetailsResult(current: current, air: airSummary, hourly: hourly, daily: daily)
    }

    // MARK: Today's range

    /// Today's low/high, widened to include the current reading. Prefers Open-Meteo's daily
    /// min/max for today; falls back to today's OWM 3-hour forecast samples. `nil` when neither
    /// has anything for today.
    static func todayRange(
        currentTemp: Double,
        openMeteo: OpenMeteoResponse?,
        forecast: ForecastResponse?,
        nowEpoch: Int,
        timeZone: TimeZone
    ) -> (low: Double, high: Double)? {
        if let daily = openMeteo?.daily,
           let index = dayIndex(containing: nowEpoch, in: daily.time),
           let low = daily.temperatureMin[safe: index] ?? nil,
           let high = daily.temperatureMax[safe: index] ?? nil {
            return (min(low, currentTemp), max(high, currentTemp))
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let today = Date(timeIntervalSince1970: TimeInterval(nowEpoch))
        let temps = (forecast?.list ?? [])
            .filter { calendar.isDate(Date(timeIntervalSince1970: TimeInterval($0.dt)), inSameDayAs: today) }
            .map(\.main.temp)
        guard let low = temps.min(), let high = temps.max() else { return nil }
        return (min(low, currentTemp), max(high, currentTemp))
    }

    // MARK: Open-Meteo

    /// The next 24 one-hour slots, starting with the hour that contains `nowEpoch`.
    static func hourlyForecasts(from hourly: OpenMeteoHourly, nowEpoch: Int, timeZone: TimeZone, units: Units) -> [HourlyForecast] {
        guard let start = hourly.time.firstIndex(where: { $0 + 3600 > nowEpoch }) else { return [] }
        return hourly.time.indices[start...].prefix(24).compactMap { index -> HourlyForecast? in
            guard let temp = hourly.temperature[safe: index] ?? nil else { return nil }
            let epoch = hourly.time[index]
            let word = condition(forWMOCode: hourly.weatherCode[safe: index] ?? nil)
            let isNight: Bool
            if let isDay = hourly.isDay[safe: index] ?? nil {
                isNight = isDay == 0
            } else {
                isNight = isNighttime(epochSeconds: epoch, timeZone: timeZone)
            }
            return HourlyForecast(
                id: epoch,
                time: timeText(epochSeconds: epoch, timeZone: timeZone),
                symbol: symbolName(for: word, isNight: isNight),
                temp: "\(Int(temp.rounded()))\(units.symbol)"
            )
        }
    }

    /// 5 days starting today, from Open-Meteo's daily min/max and max chance of precipitation.
    /// Icons always use the daytime symbol: a row summarizes the day, not its midnight.
    static func dailyForecasts(from daily: OpenMeteoDaily, nowEpoch: Int, timeZone: TimeZone, units: Units) -> [DailyForecast] {
        guard let start = dayIndex(containing: nowEpoch, in: daily.time)
            ?? daily.time.firstIndex(where: { $0 > nowEpoch }) else { return [] }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let style = Date.FormatStyle(locale: Locale(identifier: "en_US_POSIX"), calendar: calendar, timeZone: timeZone)
            .weekday(.abbreviated)

        return daily.time.indices[start...].prefix(5).compactMap { index -> DailyForecast? in
            guard let low = daily.temperatureMin[safe: index] ?? nil,
                  let high = daily.temperatureMax[safe: index] ?? nil else { return nil }
            let epoch = daily.time[index]
            // `epoch` is local midnight; label from local noon so a DST shift can't move it a day.
            let dayLabel = Date(timeIntervalSince1970: TimeInterval(epoch + 12 * 3600)).formatted(style)
            let chance: Double = (daily.precipitationProbabilityMax[safe: index] ?? nil) ?? 0
            return DailyForecast(
                id: epoch,
                day: dayLabel,
                symbol: symbolName(for: condition(forWMOCode: daily.weatherCode[safe: index] ?? nil), isNight: false),
                low: "\(Int(low.rounded()))°",
                high: "\(Int(high.rounded()))\(units.symbol)",
                chanceOfRain: Int(chance.clamped(to: 0...100).rounded())
            )
        }
    }

    /// Index of the day (given as local-midnight epochs) that contains `epoch`. Uses the next day's
    /// start as the end when there is one, so 23/25-hour DST days are handled.
    private static func dayIndex(containing epoch: Int, in days: [Int]) -> Int? {
        days.indices.first { index in
            let end = index + 1 < days.count ? days[index + 1] : days[index] + 86400
            return days[index] <= epoch && epoch < end
        }
    }

    /// Maps a WMO weather interpretation code (what Open-Meteo returns) to the OWM condition words
    /// `symbolName` already understands.
    static func condition(forWMOCode code: Int?) -> String {
        guard let code = code else { return "" }
        switch code {
        case 0: return "Clear"
        case 1...3: return "Clouds"
        case 45, 48: return "Fog"
        case 51...57: return "Drizzle"
        case 61...67, 80...82: return "Rain"
        case 71...77, 85, 86: return "Snow"
        case 95...99: return "Thunderstorm"
        default: return ""
        }
    }

    // MARK: Grouping (OWM fallback)

    /// Buckets 3-hourly forecast entries by the city's local calendar day, then takes each day's
    /// min/max, its most common condition, and its highest chance of rain. Capped at 5 days.
    /// Only used when Open-Meteo is unavailable.
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

            let style = Date.FormatStyle(locale: Locale(identifier: "en_US_POSIX"), calendar: calendar, timeZone: timeZone)
                .weekday(.abbreviated)
            let dayLabel = day.formatted(style)
            let epoch = Int(day.timeIntervalSince1970)

            return DailyForecast(
                id: epoch,
                day: dayLabel,
                // Always the daytime symbol. `epoch` is local midnight, so judging day/night from
                // it made every day show a moon.
                symbol: symbolName(for: condition, isNight: false),
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
        let style = Date.FormatStyle(locale: Locale(identifier: "en_US_POSIX"), calendar: Calendar(identifier: .gregorian), timeZone: timeZone)
            .hour().minute()
        return date.formatted(style)
    }

    /// Maps an OWM condition word to a local SF Symbol. Deliberately not using OWM's icon URLs:
    /// that would be another network call per icon, a third-party request leaking the user's
    /// searched location, and wouldn't work offline from the cache.
    static func symbolName(for condition: String, epochSeconds: Int, timeZone: TimeZone) -> String {
        symbolName(for: condition, isNight: isNighttime(epochSeconds: epochSeconds, timeZone: timeZone))
    }

    static func symbolName(for condition: String, isNight: Bool) -> String {
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

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
