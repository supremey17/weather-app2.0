import Foundation

enum WeatherError: Error {
    case missingAPIKey
    case cityNotFound(String)
    case badStatus(Int)
}

/// Port of WeatherAPI.java: talks to OpenWeatherMap with URLSession + JSONDecoder.
struct WeatherService {
    private let apiKey: String
    private let session: URLSession
    private let decoder = JSONDecoder()

    /// Reads the key from Info.plist (OWMAPIKey), which is filled in from Config/Secrets.xcconfig.
    /// Phones have no environment variables, so this replaces System.getenv("OWM_API_KEY").
    init(session: URLSession = .shared) throws {
        let key = (Bundle.main.object(forInfoDictionaryKey: "OWMAPIKey") as? String)?
            .trimmingCharacters(in: .whitespaces) ?? ""
        if key.isEmpty || key.hasPrefix("$(") {
            throw WeatherError.missingAPIKey
        }
        self.apiKey = key
        self.session = session
    }

    func findByCity(_ city: String, units: Units) async throws -> WeatherResponse {
        // URLComponents does the encoding URLEncoder did, so multi-word cities work.
        let url = makeURL(path: "/data/2.5/weather", query: [
            "q": city,
            "units": units.rawValue,
        ])
        do {
            return try await get(url)
        } catch WeatherError.badStatus(404) {
            throw WeatherError.cityNotFound(city)
        }
    }

    /// Used instead of the ip-api.com lookup: the phone's own location, and OWM returns the city name.
    func findByCoordinates(lat: Double, lon: Double, units: Units) async throws -> WeatherResponse {
        let url = makeURL(path: "/data/2.5/weather", query: [
            "lat": String(lat),
            "lon": String(lon),
            "units": units.rawValue,
        ])
        return try await get(url)
    }

    func uvIndex(lat: Double, lon: Double) async throws -> Double {
        let url = makeURL(path: "/data/4.0/onecall/current", query: [
            "lat": String(lat),
            "lon": String(lon),
        ])
        let response: OneCallResponse = try await get(url)
        return response.data.first?.uvi ?? 0
    }

    private func makeURL(path: String, query: [String: String]) -> URL {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.openweathermap.org"
        components.path = path
        components.queryItems = query.map { URLQueryItem(name: $0.key, value: $0.value) }
            + [URLQueryItem(name: "appid", value: apiKey)]
        return components.url!
    }

    private func get<T: Decodable>(_ url: URL) async throws -> T {
        let (data, response) = try await session.data(from: url)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        guard status == 200 else {
            throw WeatherError.badStatus(status)
        }
        return try decoder.decode(T.self, from: data)
    }
}
