import Foundation

// Mirrors the Java records (WeatherResponse, MainInfo, WeatherInfo, Coord, OneCallResponse, CurrentBlock).
// Decodable ignores any JSON keys we don't list, like @JsonIgnoreProperties(ignoreUnknown = true).

struct WeatherResponse: Decodable {
    let name: String
    let weather: [WeatherInfo]
    let main: MainInfo
    let coord: Coord
}

struct MainInfo: Decodable {
    let temp: Double
    let feelsLike: Double
    let humidity: Int

    enum CodingKeys: String, CodingKey {
        case temp
        case feelsLike = "feels_like"
        case humidity
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

struct OneCallResponse: Decodable {
    let data: [CurrentBlock]
}

struct CurrentBlock: Decodable {
    let uvi: Double
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
