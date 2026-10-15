import SwiftUI
import Testing
@testable import WeatherApp

struct TemperatureBandTests {
    @Test func mapsFahrenheitReadingsToBandsAtTheirBoundaries() {
        #expect(TemperatureBand.make(fahrenheit: -10) == .freezing)
        #expect(TemperatureBand.make(fahrenheit: 31.9) == .freezing)
        #expect(TemperatureBand.make(fahrenheit: 32) == .cold)
        #expect(TemperatureBand.make(fahrenheit: 54.9) == .cold)
        #expect(TemperatureBand.make(fahrenheit: 55) == .mild)
        #expect(TemperatureBand.make(fahrenheit: 72.34) == .mild)
        #expect(TemperatureBand.make(fahrenheit: 75) == .warm)
        #expect(TemperatureBand.make(fahrenheit: 89.9) == .warm)
        #expect(TemperatureBand.make(fahrenheit: 90) == .hot)
        #expect(TemperatureBand.make(fahrenheit: 115) == .hot)
    }

    @Test func convertsCelsiusBeforePickingABand() {
        #expect(TemperatureBand.make(temp: -5, units: .metric) == .freezing)
        #expect(TemperatureBand.make(temp: 0, units: .metric) == .cold)
        #expect(TemperatureBand.make(temp: 20, units: .metric) == .mild)
        #expect(TemperatureBand.make(temp: 28, units: .metric) == .warm)
        #expect(TemperatureBand.make(temp: 35, units: .metric) == .hot)
        #expect(TemperatureBand.make(temp: 72, units: .imperial) == .mild)
    }

    @Test func everyBandHasItsOwnDistinctGradient() {
        let bands = TemperatureBand.allCases
        for (index, band) in bands.enumerated() {
            #expect(band.colors == band.colors)
            for other in bands[(index + 1)...] {
                #expect(band.colors != other.colors, "\(band) and \(other) share colors")
            }
        }
    }

    @Test func fillTonesDifferFromTheOutline() {
        for band in TemperatureBand.allCases {
            let colors = band.colors
            #expect(colors.highlight != TemperatureColors.outline)
            #expect(colors.base != TemperatureColors.outline)
            #expect(colors.shade != TemperatureColors.outline)
        }
    }
}

struct TemperatureReadoutFormatTests {
    @Test func roundsToAWholeNumber() {
        #expect(TemperatureReadoutFormat.number(72.34) == "72")
        #expect(TemperatureReadoutFormat.number(72.5) == "73")
        #expect(TemperatureReadoutFormat.number(-3.6) == "-4")
        #expect(TemperatureReadoutFormat.number(-0.4) == "0")
    }

    @Test func spellsOutTheUnitForVoiceOver() {
        #expect(TemperatureReadoutFormat.accessibilityLabel(temp: 72.34, units: .imperial) == "72 degrees Fahrenheit")
        #expect(TemperatureReadoutFormat.accessibilityLabel(temp: 21.7, units: .metric) == "22 degrees Celsius")
    }
}
