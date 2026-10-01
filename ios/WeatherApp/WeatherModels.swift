import Foundation

// Mirrors the Java records (WeatherResponse, MainInfo, WeatherInfo, Coord, OneCallResponse, CurrentBlock).
// Decodable ignores any JSON keys we don't list, like @JsonIgnoreProperties(ignoreUnknown = true).
//
// Fields OWM can omit (rain, snow, gust, visibility, sys...) are Optional. A commit earlier in this
// project (37383cb) fixed a crash from exactly this: a missing "snow" key failed the whole decode,
// so even the temperature stopped showing. Don't make these non-optional again.

struct WeatherResponse: Decodable {
    let name: String
    let weather: [WeatherInfo]
    let main: MainInfo
    let coord: Coord
    let visibility: Int?
    let wind: Wind?
    let clouds: Clouds?
    let rain: Precip?
    let snow: Precip?
    let sys: Sys?
    /// Shift from UTC in seconds, for showing sunrise/sunset in the city's own local time.
    let timezone: Int?
    let dt: Int?
}

struct MainInfo: Decodable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int
    let tempMin: Double?
    let tempMax: Double?
    let pressure: Int?
    let seaLevel: Int?
    let grndLevel: Int?

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
        case tempMin = "temp_min"
        case tempMax = "temp_max"
        case pressure
        case seaLevel = "sea_level"
        case grndLevel = "grnd_level"
    }
}

struct WeatherInfo: Decodable {
    let main: String
    let description: String
    let icon: String
}

struct Coord: Decodable {
    let lat: Double
    let lon: Double
}

struct Wind: Decodable {
    let speed: Double
    let deg: Int?
    let gust: Double?
}

struct Clouds: Decodable {
    let all: Int
}

/// Rain/snow volume in mm. OWM reports whichever window it has data for; usually just "1h".
struct Precip: Decodable {
    let oneHour: Double?
    let threeHour: Double?

    enum CodingKeys: String, CodingKey {
        case oneHour = "1h"
        case threeHour = "3h"
    }
}

struct Sys: Decodable {
    let sunrise: Int?
    let sunset: Int?
    let country: String?
}

struct OneCallResponse: Decodable {
    let data: [CurrentBlock]
}

struct CurrentBlock: Decodable {
    let uvi: Double
}

// MARK: Air quality (/data/2.5/air_pollution)

struct AirPollutionResponse: Decodable {
    let list: [AirSample]
}

struct AirSample: Decodable {
    let main: AirMain
    let components: AirComponents
}

struct AirMain: Decodable {
    /// OWM's 1-5 Air Quality Index. Anything outside that range is treated as "unknown" by the UI.
    let aqi: Int
}

struct AirComponents: Decodable {
    let pm25: Double
    let pm10: Double
    let o3: Double
    let no2: Double
    let so2: Double
    let co: Double

    enum CodingKeys: String, CodingKey {
        case pm25 = "pm2_5"
        case pm10
        case o3
        case no2
        case so2
        case co
    }
}

// MARK: Forecast (/data/2.5/forecast)

struct ForecastResponse: Decodable {
    let list: [ForecastItem]
    let city: ForecastCity
}

struct ForecastCity: Decodable {
    let timezone: Int
}

struct ForecastItem: Decodable {
    let dt: Int
    let main: ForecastMain
    let weather: [WeatherInfo]
    /// Probability of precipitation, 0...1 per the API docs; clamped when used, never trusted as-is.
    let pop: Double
    let wind: Wind?
}

struct ForecastMain: Decodable {
    let temp: Double
    let tempMin: Double
    let tempMax: Double

    enum CodingKeys: String, CodingKey {
        case temp
        case tempMin = "temp_min"
        case tempMax = "temp_max"
    }
}

/// "imperial" / "metric" are the exact values OpenWeatherMap expects in the `units` query param.
enum Units: String, CaseIterable, Identifiable {
    case imperial
    case metric

    var id: String { rawValue }
    var symbol: String { self == .imperial ? "°F" : "°C" }
    var label: String { self == .imperial ? "Fahrenheit (°F)" : "Celsius (°C)" }
    var toggled: Units { self == .imperial ? .metric : .imperial }
}
