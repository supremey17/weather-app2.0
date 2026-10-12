import Foundation
import Testing
@testable import WeatherApp

@MainActor
struct PixelSkyEffectsTests {

    // MARK: - Lightning

    /// Every strike found over a long stretch, sampled at the particle layer's 20 fps.
    private func strikes(over seconds: Double) -> [(time: Double, strike: LightningSchedule.Strike)] {
        stride(from: 0.0, to: seconds, by: 0.05).compactMap { offset in
            let time = 800_000_000 + offset
            return LightningSchedule.strike(at: time).map { (time: time, strike: $0) }
        }
    }

    @Test func lightningStrikesSometimesButNotMostOfTheTime() {
        let samples = strikes(over: 140)
        let litFraction = Double(samples.count) / (140 / 0.05)
        #expect(!samples.isEmpty)
        #expect(litFraction < 0.1)
    }

    @Test func lightningIsDeterministicAndStaysInsideItsWindow() {
        for (time, strike) in strikes(over: 70) {
            #expect(LightningSchedule.strike(at: time) == strike)
            #expect(strike.elapsed >= 0)
            #expect(strike.elapsed < LightningSchedule.duration)
        }
    }

    @Test func atMostOneStrikePerPeriod() {
        var cycles: [Int: Int] = [:]
        var previousCycle: Int?
        for (_, strike) in strikes(over: 140) where strike.cycle != previousCycle {
            cycles[strike.cycle, default: 0] += 1
            previousCycle = strike.cycle
        }
        #expect(cycles.values.allSatisfy { $0 == 1 })
    }

    @Test func flashIsBrightFirstThenGone() {
        #expect(LightningSchedule.flashStrength(elapsed: 0) == 1)
        #expect(LightningSchedule.flashStrength(elapsed: 0.15) < LightningSchedule.flashStrength(elapsed: 0.25))
        #expect(LightningSchedule.flashStrength(elapsed: 0.5) == 0)
        #expect(LightningSchedule.flashStrength(elapsed: -1) == 0)
    }

    @Test func boltHasOneCellPerRowAndOnlyJogsOneCellAtATime() {
        for cycle in 0..<50 {
            let bolt = LightningSchedule.bolt(cycle: cycle, rows: 30)
            #expect(bolt.columnOffsets.count == 30)
            #expect(bolt.startFraction >= 0 && bolt.startFraction < 1)
            for (above, below) in zip(bolt.columnOffsets, bolt.columnOffsets.dropFirst()) {
                #expect(abs(above - below) <= 1)
            }
            #expect(LightningSchedule.bolt(cycle: cycle, rows: 30) == bolt)
        }
        #expect(LightningSchedule.bolt(cycle: 3, rows: 0).columnOffsets.isEmpty)
    }

    // MARK: - Clouds

    @Test func cloudCountMatchesTheWeather() {
        #expect(PixelCloudLayer.cloudCount(for: .clearNight) == 0)
        #expect(PixelCloudLayer.cloudCount(for: .clearDay) < PixelCloudLayer.cloudCount(for: .stormy))
        for theme in [PixelWeatherTheme.cloudy, .rainy, .stormy, .snowy, .clearDay, .misty, .neutral] {
            #expect(PixelCloudLayer.cloudCount(for: theme) <= PixelCloudLayer.puffs.count)
        }
    }

    @Test func cloudSpriteRowsAreAllTheSameWidth() {
        let widths = Set(PixelCloudLayer.shape.map(\.count))
        #expect(widths.count == 1)
    }

    // MARK: - Snow caps

    @Test func snowCapsGetDeeperWithHeavierSnow() {
        #expect(PixelSnowCap.height(for: .light) < PixelSnowCap.height(for: .normal))
        #expect(PixelSnowCap.height(for: .normal) < PixelSnowCap.height(for: .heavy))
    }

    @Test func snowCapColumnsStayWithinTheCapHeight() {
        for intensity in PrecipitationIntensity.allCases {
            let maxRows = Int(PixelSnowCap.height(for: intensity) / PixelSnowCap.cell)
            for column in 0..<40 {
                let rows = PixelSnowCap.rows(column: column, columns: 40, intensity: intensity)
                #expect(rows >= 1 && rows <= maxRows)
            }
            // Tapered ends sit lower than the base depth allows in the middle.
            #expect(PixelSnowCap.rows(column: 0, columns: 40, intensity: intensity) <= PixelSnowCap.baseRows(for: intensity))
        }
    }
}
