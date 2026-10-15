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

    @Test func fallbackDailyForecastUsesDaytimeSymbolNotMidnightMoon() {
        // Each day's id is local midnight; the icon used to be judged at that instant, so every
        // day showed a moon.
        let items = [
            ForecastItem(dt: 0, main: ForecastMain(temp: 50, tempMin: 40, tempMax: 55), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01n")], pop: 0, wind: nil),
            ForecastItem(dt: 86400, main: ForecastMain(temp: 50, tempMin: 40, tempMax: 55), weather: [WeatherInfo(main: "Clouds", description: "cloudy", icon: "02n")], pop: 0, wind: nil),
        ]
        let forecast = ForecastResponse(list: items, city: ForecastCity(timezone: 0))
        let days = WeatherDetails.dailyForecasts(from: forecast, timeZone: TimeZone(identifier: "UTC")!, units: .imperial)

        #expect(days.map(\.symbol) == ["sun.max", "cloud.sun"])
    }

    // MARK: Open-Meteo

    @Test func decodesOpenMeteoResponseWithNulls() throws {
        let json = """
        {
            "latitude": 30.27, "longitude": -97.74,
            "timezone": "America/Chicago", "utc_offset_seconds": -18000,
            "hourly": {
                "time": [1704067200, 1704070800],
                "temperature_2m": [50.1, null],
                "weather_code": [0, 3],
                "precipitation_probability": [0, null],
                "is_day": [0, 1]
            },
            "daily": {
                "time": [1704067200],
                "temperature_2m_max": [61.2],
                "temperature_2m_min": [44.0],
                "weather_code": [61],
                "precipitation_probability_max": [80]
            }
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
        #expect(response.timezone == "America/Chicago")
        #expect(response.utcOffsetSeconds == -18000)
        #expect(response.hourly?.time.count == 2)
        #expect(response.hourly?.temperature[1] == nil)
        #expect(response.hourly?.isDay == [0, 1])
        #expect(response.daily?.temperatureMax == [61.2])
        #expect(response.daily?.precipitationProbabilityMax == [80])
    }

    @Test func decodesOpenMeteoResponseMissingSectionsAndArrays() throws {
        let json = """
        {"timezone": "UTC", "daily": {"time": [1704067200]}}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenMeteoResponse.self, from: json)
        #expect(response.hourly == nil)
        #expect(response.daily?.time == [1704067200])
        #expect(response.daily?.temperatureMax.isEmpty == true)
    }

    @Test func wmoCodesMapToOWMConditionWords() {
        #expect(WeatherDetails.condition(forWMOCode: 0) == "Clear")
        #expect(WeatherDetails.condition(forWMOCode: 2) == "Clouds")
        #expect(WeatherDetails.condition(forWMOCode: 45) == "Fog")
        #expect(WeatherDetails.condition(forWMOCode: 53) == "Drizzle")
        #expect(WeatherDetails.condition(forWMOCode: 63) == "Rain")
        #expect(WeatherDetails.condition(forWMOCode: 81) == "Rain")
        #expect(WeatherDetails.condition(forWMOCode: 75) == "Snow")
        #expect(WeatherDetails.condition(forWMOCode: 86) == "Snow")
        #expect(WeatherDetails.condition(forWMOCode: 95) == "Thunderstorm")
        #expect(WeatherDetails.condition(forWMOCode: nil) == "")
        #expect(WeatherDetails.symbolName(for: WeatherDetails.condition(forWMOCode: 45), isNight: false) == "cloud.fog")
    }

    @Test func hourlyForecastIsTwentyFourOneHourStepsFromTheCurrentHour() {
        let openMeteo = Self.makeOpenMeteo()
        // 02:30 UTC on the first day: the current hour slot is 02:00.
        let now = Date(timeIntervalSince1970: TimeInterval(Self.base + 2 * 3600 + 1800))
        let result = WeatherDetails.build(weather: Self.makeWeather(), uvi: 0, air: nil, forecast: nil, openMeteo: openMeteo, units: .imperial, now: now)

        #expect(result.hourly.count == 24)
        #expect(result.hourly.first?.id == Self.base + 2 * 3600)
        #expect(result.hourly.last?.id == Self.base + 25 * 3600)
        let steps = zip(result.hourly.dropFirst(), result.hourly).map { $0.id - $1.id }
        #expect(steps.allSatisfy { $0 == 3600 })
        #expect(result.hourly.first?.time.contains("2:00") == true)
    }

    @Test func hourlyForecastIconsFollowIsDay() {
        let hourly = OpenMeteoHourly(
            time: [Self.base, Self.base + 3600],
            temperature: [50, 52],
            weatherCode: [0, 0],
            precipitationProbability: [0, 0],
            isDay: [0, 1]
        )
        let hours = WeatherDetails.hourlyForecasts(from: hourly, nowEpoch: Self.base, timeZone: TimeZone(identifier: "UTC")!, units: .imperial)

        #expect(hours.map(\.symbol) == ["moon.stars", "sun.max"])
        #expect(hours.map(\.temp) == ["50°F", "52°F"])
    }

    @Test func dailyForecastUsesOpenMeteoFiveDaysFromTodayWithDaytimeIcons() {
        let openMeteo = Self.makeOpenMeteo()
        // Late on the second day (Tue 2024-01-02 23:00 UTC): today is index 1.
        let now = Date(timeIntervalSince1970: TimeInterval(Self.base + 86400 + 23 * 3600))
        let result = WeatherDetails.build(weather: Self.makeWeather(), uvi: 0, air: nil, forecast: nil, openMeteo: openMeteo, units: .imperial, now: now)

        #expect(result.daily.count == 5)
        #expect(result.daily.map(\.day) == ["Tue", "Wed", "Thu", "Fri", "Sat"])
        #expect(result.daily.first?.low == "41°")
        #expect(result.daily.first?.high == "61°F")
        #expect(result.daily.first?.chanceOfRain == 20)
        #expect(result.daily.first?.symbol == "sun.max")
        #expect(result.daily.allSatisfy { !$0.symbol.contains("moon") })
    }

    @Test func lowHighComesFromOpenMeteoTodayWidenedByCurrentTemp() {
        let openMeteo = Self.makeOpenMeteo()
        let now = Date(timeIntervalSince1970: TimeInterval(Self.base + 12 * 3600))
        // makeWeather: temp 70, /weather temp_min/temp_max 65/75 (must be ignored).
        // Today's Open-Meteo range is 40...60, so the current 70 widens the high.
        let result = WeatherDetails.build(weather: Self.makeWeather(), uvi: 0, air: nil, forecast: nil, openMeteo: openMeteo, units: .imperial, now: now)
        let lowHigh = result.current.first { $0.label == "Low / High" }

        #expect(lowHigh?.value == "40° / 70°F")
    }

    @Test func lowHighFallsBackToTodaysOWMForecastEntries() {
        let items = [
            ForecastItem(dt: Self.base + 9 * 3600, main: ForecastMain(temp: 62, tempMin: 50, tempMax: 90), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")], pop: 0, wind: nil),
            ForecastItem(dt: Self.base + 15 * 3600, main: ForecastMain(temp: 78, tempMin: 50, tempMax: 90), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")], pop: 0, wind: nil),
            // Tomorrow: must not count toward today's range.
            ForecastItem(dt: Self.base + 30 * 3600, main: ForecastMain(temp: 95, tempMin: 95, tempMax: 95), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")], pop: 0, wind: nil),
        ]
        let forecast = ForecastResponse(list: items, city: ForecastCity(timezone: 0))
        let now = Date(timeIntervalSince1970: TimeInterval(Self.base + 8 * 3600))
        let result = WeatherDetails.build(weather: Self.makeWeather(timezoneOffset: 0), uvi: 0, air: nil, forecast: forecast, openMeteo: nil, units: .imperial, now: now)
        let lowHigh = result.current.first { $0.label == "Low / High" }

        #expect(lowHigh?.value == "62° / 78°F")
    }

    @Test func lowHighIsOmittedWithoutAnyForecastData() {
        let result = WeatherDetails.build(weather: Self.makeWeather(), uvi: 0, air: nil, forecast: nil, units: .imperial)
        #expect(!result.current.contains { $0.label == "Low / High" })
    }

    @Test func emptyOpenMeteoHourlyFallsBackToOWMForecast() {
        let items = (0..<20).map { i in
            ForecastItem(dt: i * 3 * 3600, main: ForecastMain(temp: 70, tempMin: 65, tempMax: 75), weather: [WeatherInfo(main: "Clear", description: "clear sky", icon: "01d")], pop: 0, wind: nil)
        }
        let forecast = ForecastResponse(list: items, city: ForecastCity(timezone: 0))
        let openMeteo = OpenMeteoResponse(timezone: "UTC", utcOffsetSeconds: 0, hourly: nil, daily: nil)
        let result = WeatherDetails.build(weather: Self.makeWeather(), uvi: 0, air: nil, forecast: forecast, openMeteo: openMeteo, units: .imperial)

        #expect(result.hourly.count == 8)
        #expect(!result.daily.isEmpty)
    }

    // MARK: Helpers

    /// 2024-01-01 00:00:00 UTC, a Monday.
    private static let base = 1704067200

    /// 48 hourly slots and 7 days from `base`, in UTC. Day i: low 40+i, high 60+i, rain chance 10*(i+1)%,
    /// always clear (WMO 0).
    private static func makeOpenMeteo() -> OpenMeteoResponse {
        let hours = 0..<48
        let days = 0..<7
        return OpenMeteoResponse(
            timezone: "UTC",
            utcOffsetSeconds: 0,
            hourly: OpenMeteoHourly(
                time: hours.map { base + $0 * 3600 },
                temperature: hours.map { Double(50 + $0 % 10) },
                weatherCode: hours.map { _ in 0 },
                precipitationProbability: hours.map { _ in 0 },
                isDay: hours.map { ($0 % 24) >= 7 && ($0 % 24) < 17 ? 1 : 0 }
            ),
            daily: OpenMeteoDaily(
                time: days.map { base + $0 * 86400 },
                temperatureMax: days.map { Double(60 + $0) },
                temperatureMin: days.map { Double(40 + $0) },
                weatherCode: days.map { _ in 0 },
                precipitationProbabilityMax: days.map { Double(10 * ($0 + 1)) }
            )
        )
    }

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
