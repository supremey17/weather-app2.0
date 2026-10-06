import SwiftUI
import Testing
import UIKit
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

// MARK: - PixelSpriteKind grid shape and content

struct PixelSpriteKindGridTests {
    @Test func everyGridHasExactlySixteenRows() {
        for kind in PixelSpriteKind.allCases {
            #expect(kind.grid.count == 16, "\(kind) grid has \(kind.grid.count) rows, expected 16")
        }
    }

    @Test func everyRowHasExactlySixteenCharacters() {
        for kind in PixelSpriteKind.allCases {
            for (index, row) in kind.grid.enumerated() {
                #expect(row.count == 16, "\(kind) row \(index) has \(row.count) chars, expected 16")
            }
        }
    }

    @Test func everyCharacterIsAKnownPaletteCharacter() {
        let allowed: Set<Character> = [".", "K", "W", "A", "S"]
        for kind in PixelSpriteKind.allCases {
            for (index, row) in kind.grid.enumerated() {
                for char in row {
                    #expect(allowed.contains(char), "\(kind) row \(index) has unexpected character '\(char)'")
                }
            }
        }
    }
}

// MARK: - PixelSpriteKind(sfSymbol:) mapping

struct PixelSpriteKindSFSymbolMappingTests {
    @Test func mapsEachKnownSFSymbolNameToExpectedCase() {
        let expectedMapping: [String: PixelSpriteKind] = [
            "sun.max.fill": .sun,
            "sun.max": .sun,
            "moon.stars.fill": .moon,
            "moon.stars": .moon,
            "cloud.fill": .cloud,
            "cloud": .cloud,
            "cloud.sun.fill": .cloudSun,
            "cloud.sun": .cloudSun,
            "cloud.moon.fill": .cloudMoon,
            "cloud.moon": .cloudMoon,
            "cloud.rain.fill": .rain,
            "cloud.rain": .rain,
            "cloud.bolt.rain.fill": .storm,
            "cloud.bolt.rain": .storm,
            "snowflake": .snow,
            "cloud.snow": .snow,
            "cloud.fog.fill": .fog,
            "cloud.fog": .fog,
            "magnifyingglass": .search,
            "star": .star,
            "star.fill": .starFilled,
            "map": .map,
            "gearshape": .gear,
            "location": .location,
            "backpack": .backpack,
            "checkmark.square.fill": .check,
            "flag.checkered": .flag,
            "trash": .trash,
            "drop.fill": .drop,
            "wind": .wind,
            "thermometer": .thermometer,
            "thermometer.variable": .thermometerVariable,
            "arrow.up.arrow.down": .tempRange,
            "humidity": .humidity,
            "gauge": .gauge,
            "gauge.with.dots.needle.67percent": .gaugeAQI,
            "aqi.medium": .gaugeAQI,
            "eye": .eye,
            "sunrise": .sunrise,
            "sunrise.fill": .sunrise,
            "sunset": .sunset,
            "sunset.fill": .sunset,
            "clock": .clock,
            "calendar": .calendar,
            "house": .house,
            "slider.horizontal.3": .sliders,
            "arrow.triangle.2.circlepath": .refresh,
        ]

        for (symbol, expected) in expectedMapping {
            #expect(PixelSpriteKind(sfSymbol: symbol) == expected, "\(symbol) should map to \(expected)")
        }
    }

    @Test func mapsUnknownSFSymbolNameToCloudDefault() {
        #expect(PixelSpriteKind(sfSymbol: "bogus.symbol") == .cloud)
    }
}

// Note: PixelStatBar's segment-clamping logic (`filledCount`) is a private computed property on
// a SwiftUI View with no public accessor, so it isn't testable through the public API without
// adding a test-only hook. Per instructions, no such hook was added, so that behavior is left
// unverified here and would need UI-hosting or a refactor (e.g. exposing a pure helper function)
// to cover.

// MARK: - Contrast helpers (deliberately independent of PixelWeatherTheme's own math)

/// WCAG 2.1 relative luminance of a `Color`, resolved through `UIColor` the same way the
/// production code does, but with the luminance/contrast arithmetic re-derived from scratch
/// here rather than calling into `PixelWeatherTheme`'s private helpers, so this is a genuine
/// independent check rather than the production formula checking itself.
private func relativeLuminance(of color: Color) -> Double {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
        return 0
    }
    func linearize(_ component: CGFloat) -> Double {
        let value = Double(component)
        return value <= 0.03928 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
    }
    return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
}

/// WCAG 2.1 contrast ratio between two colors, in 1...21.
private func contrastRatio(_ a: Color, _ b: Color) -> Double {
    let luminanceA = relativeLuminance(of: a)
    let luminanceB = relativeLuminance(of: b)
    let lighter = max(luminanceA, luminanceB)
    let darker = min(luminanceA, luminanceB)
    return (lighter + 0.05) / (darker + 0.05)
}

private let allPixelWeatherThemes: [PixelWeatherTheme] = [
    .clearDay, .clearNight, .cloudy, .rainy, .stormy, .snowy, .misty, .neutral,
]

private let allPixelPanelStyles: [PixelPanelStyle] = [.standard, .wood, .showroom, .hud]

// MARK: - Panel text contrast

struct PixelWeatherThemeContrastTests {
    @Test func textColorMeetsMinimumContrastForEveryThemeAndStyle() {
        for theme in allPixelWeatherThemes {
            for style in allPixelPanelStyles {
                let ratio = contrastRatio(theme.fill(for: style), theme.textColor(on: style))
                #expect(ratio >= 4.5, "\(theme) \(style): only \(ratio) contrast")
            }
        }
    }

    @Test func panelTextColorMatchesStandardStyleTextColor() {
        for theme in allPixelWeatherThemes {
            #expect(theme.panelTextColor == theme.textColor(on: .standard))
        }
    }

    @Test func accentTextMeetsMinimumContrastForEveryThemeAndStyle() {
        for theme in allPixelWeatherThemes {
            for style in allPixelPanelStyles {
                let ratio = contrastRatio(theme.fill(for: style), theme.accentText(on: style))
                #expect(ratio >= 4.5, "\(theme) \(style): accentText only \(ratio) contrast")
            }
        }
    }

    @Test func skyTextColorMeetsMinimumContrastAgainstSkyColorForMostThemes() {
        for theme in allPixelWeatherThemes {
            let ratio = contrastRatio(theme.skyColor, theme.skyTextColor)
            if theme == .misty {
                // `.misty`'s skyColor (0.45, 0.54, 0.60) is a mid-gray with relative luminance
                // ~0.24 — almost exactly between the two ink choices this API has (white and
                // the dark navy `panelColor`). White text on it only reaches ~3.6:1, short of
                // the 4.5:1 AA target. Flipping misty to dark ink would fix this one case but
                // isn't a universal win: skyColor luminance doesn't split cleanly around 0.5 the
                // way panel fills do (clearDay is ~0.41, right next to misty's ~0.24, yet needs
                // dark ink badly), so a generic threshold would misclassify neighboring themes.
                // This is the one documented case called out in the task: still >= 3:1 (large
                // text / incidental contrast minimum), just short of the stricter 4.5:1 bar.
                #expect(ratio >= 3.0, "misty sky text contrast regressed below 3:1: \(ratio)")
            } else {
                #expect(ratio >= 4.5, "\(theme) sky text contrast only \(ratio)")
            }
        }
    }

    @Test func skyTintMatchesSkyTextColor() {
        for theme in allPixelWeatherThemes {
            #expect(theme.skyTint == theme.skyTextColor)
        }
    }
}
