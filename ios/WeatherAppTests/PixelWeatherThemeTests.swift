import Testing
@testable import WeatherApp

struct PixelWeatherThemeTests {
    @Test func mapsKnownConditionsToExpectedThemes() {
        #expect(PixelWeatherTheme.make(condition: "Rain", epochSeconds: nil, timeZoneOffset: nil) == .rainy)
        #expect(PixelWeatherTheme.make(condition: "Thunderstorm", epochSeconds: nil, timeZoneOffset: nil) == .stormy)
        #expect(PixelWeatherTheme.make(condition: "Snow", epochSeconds: nil, timeZoneOffset: nil) == .snowy)
        #expect(PixelWeatherTheme.make(condition: "Fog", epochSeconds: nil, timeZoneOffset: nil) == .misty)
    }

    @Test func mapsClearWeatherByLocalTime() {
        #expect(PixelWeatherTheme.make(condition: "Clear", epochSeconds: 43_200, timeZoneOffset: 0) == .clearDay)
        #expect(PixelWeatherTheme.make(condition: "Clear", epochSeconds: 3_600, timeZoneOffset: 0) == .clearNight)
    }

    @Test func treatsOnlyWeatherWithParticlesAsAnimated() {
        #expect(PixelWeatherTheme.rainy.supportsAmbientMotion)
        #expect(PixelWeatherTheme.snowy.supportsAmbientMotion)
        #expect(!PixelWeatherTheme.clearDay.supportsAmbientMotion)
    }
}
