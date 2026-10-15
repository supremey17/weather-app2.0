import Testing
@testable import WeatherApp

struct PixelRainDropGaugeTests {
    @Test func zeroChanceLeavesTheDropEmpty() {
        #expect(PixelRainDropGauge.filledRows(chance: 0) == 0)
        #expect(PixelRainDropGauge.filledRows(chance: -5) == 0)
    }

    @Test func anyChanceShowsAtLeastOneRow() {
        #expect(PixelRainDropGauge.filledRows(chance: 1) == 1)
    }

    @Test func onlyAFullChanceFillsTheTip() {
        let rows = PixelRainDropGauge.rows
        #expect(PixelRainDropGauge.filledRows(chance: 99) == rows - 1)
        #expect(PixelRainDropGauge.filledRows(chance: 100) == rows)
        #expect(PixelRainDropGauge.filledRows(chance: 140) == rows)
    }

    @Test func fillGrowsWithChance() {
        let levels = stride(from: 0, through: 100, by: 10).map(PixelRainDropGauge.filledRows(chance:))
        #expect(levels == levels.sorted())
        #expect(PixelRainDropGauge.filledRows(chance: 50) == PixelRainDropGauge.rows / 2)
    }

    @Test func maskRowsAreAllTheSameWidth() {
        #expect(PixelRainDropGauge.mask.allSatisfy { $0.count == PixelRainDropGauge.columns })
    }
}
