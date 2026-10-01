import Foundation
import Testing
@testable import WeatherApp

struct WeatherDetailsTests {

    // MARK: Decoding

    @Test func decodesFullWeatherResponse() throws {
        let json = """
        {
            "name": "Austin",
            "weather": [{"main": "Clear", "description": "clear sky", "icon": "01d"}],
            "main": {"temp": 75.0, "feels_like": 74.0, "humidity": 40, "temp_min": 68.0, "temp_max": 80.0, "pressure": 1015},
            "coord": {"lat": 30.27, "lon": -97.74},
            "visibility": 10000,
            "wind": {"speed": 8.5, "deg": 180, "gust": 12.0},
            "clouds": {"all": 5},
            "rain": {"1h": 0.5},
            "sys": {"sunrise": 1700000000, "sunset": 1700040000, "country": "US"},
            "timezone": -18000,
            "dt": 1700010000
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WeatherResponse.self, from: json)
        #expect(response.name == "Austin")
        #expect(response.wind?.gust == 12.0)
        #expect(response.rain?.oneHour == 0.5)
        #expect(response.sys?.sunrise == 1700000000)
        #expect(response.main.pressure == 1015)
    }

    @Test func decodesWeatherResponseMissingOptionalFields() throws {
        // No rain, snow, gust, visibility, sys, wind, clouds, timezone, dt -- all optional, must still decode.
        let json = """
        {
            "name": "Somewhere",
            "weather": [{"main": "Clear", "description": "clear sky", "icon": "01d"}],
            "main": {"temp": 60.0, "feels_like": 59.0, "humidity": 50},
            "coord": {"lat": 1.0, "lon": 2.0}
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(WeatherResponse.self, from: json)
        #expect(response.name == "Somewhere")
        #expect(response.wind == nil)
        #expect(response.rain == nil)
        #expect(response.sys == nil)
        #expect(response.main.pressure == nil)
    }

    @Test func decodesAirPollutionResponse() throws {
        let json = """
        {"list": [{"main": {"aqi": 2}, "components": {"co": 200.1, "no2": 10.2, "o3": 60.5, "so2": 5.1, "pm2_5": 8.3, "pm10": 12.4}}]}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(AirPollutionResponse.self, from: json)
        #expect(response.list.first?.main.aqi == 2)
        #expect(response.list.first?.components.pm25 == 8.3)
    }

    @Test func decodesForecastResponse() throws {
        let json = """
        {
            "list": [
                {"dt": 1700000000, "main": {"temp": 70.0, "temp_min": 65.0, "temp_max": 75.0}, "weather": [{"main": "Clear", "description": "clear sky", "icon": "01d"}], "pop": 0.2}
            ],
            "city": {"timezone": -18000}
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ForecastResponse.self, from: json)
        #expect(response.list.count == 1)
        #expect(response.city.timezone == -18000)
    }

    // MARK: compassDirection

    @Test func compassDirectionHandlesCardinalAndWraparoundDegrees() {
        #expect(WeatherDetails.compassDirection(forDegrees: 0) == "N")
        #expect(WeatherDetails.compassDirection(forDegrees: 22) == "NNE")
        #expect(WeatherDetails.compassDirection(forDegrees: 359) == "N")
        #expect(WeatherDetails.compassDirection(forDegrees: 180) == "S")
    }

    // MARK: visibilityText / pressureText

    @Test func visibilityTextConvertsPerUnitSystem() {
        #expect(WeatherDetails.visibilityText(meters: 16093, units: .imperial) == "10 mi")
        #expect(WeatherDetails.visibilityText(meters: 10000, units: .metric) == "10 km")
    }

    @Test func pressureTextConvertsToInHgForImperial() {
        #expect(WeatherDetails.pressureText(hPa: 1013, units: .metric) == "1013 hPa")
        // 1013 * 0.02953 = 29.9139..., rounds to 29.91.
        #expect(WeatherDetails.pressureText(hPa: 1013, units: .imperial) == "29.91 inHg")
    }

    // MARK: AirQualitySummary

    @Test func airQualitySummaryMapsKnownAQIValues() {
        let sample = AirSample(main: AirMain(aqi: 1), components: AirComponents(pm25: 1, pm10: 1, o3: 1, no2: 1, so2: 1, co: 1))
        #expect(AirQualitySummary(sample: sample)?.label == "Good")
    }

    @Test func airQualitySummaryReturnsNilForOutOfRangeAQI() {
        let zero = AirSample(main: AirMain(aqi: 0), components: AirComponents(pm25: 1, pm10: 1, o3: 1, no2: 1, so2: 1, co: 1))
        let six = AirSample(main: AirMain(aqi: 6), components: AirComponents(pm25: 1, pm10: 1, o3: 1, no2: 1, so2: 1, co: 1))
        #expect(AirQualitySummary(sample: zero) == nil)
        #expect(AirQualitySummary(sample: six) == nil)
    }

    // MARK: Hourly / daily grouping

    @Test func hourlyForecastIsLimitedToEightEntries() {
        let items = (0..<20).map { i in
            ForecastItem(dt: i * 3600, main: ForecastMain(temp: 70, tempMin: 65, tempMax: 75), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")], pop: 0, wind: nil)
        }
        let forecast = ForecastResponse(list: items, city: ForecastCity(timezone: 0))
        let weather = Self.makeWeather()
        let result = WeatherDetails.build(weather: weather, uvi: 0, air: nil, forecast: forecast, units: .imperial)
        #expect(result.hourly.count == 8)
    }

    @Test func dailyForecastGroupsAcrossMidnightInNonUTCTimeZone() {
        // America/Los_Angeles is UTC-8 (ignoring DST, which doesn't matter here since we pass the offset
        // directly as `timezone` seconds, matching what OWM returns for a given city).
        let offsetSeconds = -8 * 3600
        // 2024-01-02 07:00 UTC == 2024-01-01 23:00 PST (local day Jan 1).
        // 2024-01-02 10:00 UTC == 2024-01-02 02:00 PST (local day Jan 2, 3 hours later in UTC
        // but across the PST midnight boundary that falls at 08:00 UTC).
        let base = 1704178800 // 2024-01-02 07:00:00 UTC
        let items = [
            ForecastItem(dt: base, main: ForecastMain(temp: 50, tempMin: 45, tempMax: 55), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")], pop: 0.1, wind: nil),
            ForecastItem(dt: base + 3 * 3600, main: ForecastMain(temp: 48, tempMin: 40, tempMax: 52), weather: [WeatherInfo(main: "Clouds", description: "cloudy", icon: "02d")], pop: 0.3, wind: nil),
        ]
        let forecast = ForecastResponse(list: items, city: ForecastCity(timezone: offsetSeconds))
        let timeZone = TimeZone(secondsFromGMT: offsetSeconds)!

        let days = WeatherDetails.dailyForecasts(from: forecast, timeZone: timeZone, units: .imperial)

        // The two samples fall on different local calendar days in Los Angeles, despite being
        // only 3 hours apart in UTC, so grouping must produce 2 separate days, not 1.
        #expect(days.count == 2)
    }

    @Test func dailyForecastTakesMinMaxAndHighestChanceOfRain() {
        let items = [
            ForecastItem(dt: 0, main: ForecastMain(temp: 50, tempMin: 40, tempMax: 55), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")], pop: 0.1, wind: nil),
            ForecastItem(dt: 3 * 3600, main: ForecastMain(temp: 48, tempMin: 35, tempMax: 50), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")], pop: 0.6, wind: nil),
        ]
        let forecast = ForecastResponse(list: items, city: ForecastCity(timezone: 0))
        let days = WeatherDetails.dailyForecasts(from: forecast, timeZone: TimeZone(identifier: "UTC")!, units: .imperial)

        #expect(days.count == 1)
        #expect(days.first?.low == "35°")
        #expect(days.first?.chanceOfRain == 60)
    }

    @Test func missingExtrasProduceEmptySectionsNotACrash() {
        let weather = Self.makeWeather()
        let result = WeatherDetails.build(weather: weather, uvi: 0, air: nil, forecast: nil, units: .imperial)
        #expect(result.air == nil)
        #expect(result.hourly.isEmpty)
        #expect(result.daily.isEmpty)
        #expect(!result.current.isEmpty)
    }

    @Test func sunriseIsFormattedInTheCitysOwnTimeZone() {
        // Tokyo is UTC+9. 2024-01-01 00:00:00 UTC == 2024-01-01 09:00 JST.
        let sunriseEpoch = 1704067200
        let weather = Self.makeWeather(sunrise: sunriseEpoch, timezoneOffset: 9 * 3600)
        let result = WeatherDetails.build(weather: weather, uvi: 0, air: nil, forecast: nil, units: .metric)
        let sunriseItem = result.current.first { $0.label == "Sunrise" }
        #expect(sunriseItem?.value.contains("9:00") == true)
    }

    // MARK: Helpers

    private static func makeWeather(sunrise: Int? = nil, timezoneOffset: Int? = nil) -> WeatherResponse {
        WeatherResponse(
            name: "Test City",
            weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")],
            main: MainInfo(temp: 70, feelsLike: 69, humidity: 50, tempMin: 65, tempMax: 75, pressure: 1013, seaLevel: nil, grndLevel: nil),
            coord: Coord(lat: 0, lon: 0),
            visibility: nil,
            wind: nil,
            clouds: nil,
            rain: nil,
            snow: nil,
            sys: sunrise.map { Sys(sunrise: $0, sunset: nil, country: nil) },
            timezone: timezoneOffset,
            dt: nil
        )
    }
}
