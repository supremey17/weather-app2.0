import SwiftUI

// MARK: - Lightning

/// When a storm's lightning strikes, as a pure function of wall-clock time, so the hero scene
/// (on the 4 fps `PixelClock`) and the full-page flash (on the 20 fps particle timeline) always
/// agree on the same strike without sharing any state.
enum LightningSchedule {
    /// One strike window per period; some windows stay dark so it doesn't feel metronomic.
    static let period: TimeInterval = 7
    /// How long a strike (bolt plus flicker) stays on screen.
    static let duration: TimeInterval = 0.6

    struct Strike: Equatable {
        /// Which period this strike belongs to; seeds the bolt's shape.
        let cycle: Int
        /// Seconds since the strike started, in `0..<duration`.
        let elapsed: TimeInterval
    }

    /// The strike happening at `time`, or `nil` between strikes. At most one strike per `period`,
    /// which keeps flashes far below the three-per-second photosensitivity limit.
    static func strike(at time: TimeInterval) -> Strike? {
        guard time.isFinite else { return nil }
        let cycle = Int((time / period).rounded(.down))
        var rng = SplitMix64(seed: seed(for: cycle))
        guard rng.next() % 4 != 0 else { return nil }
        let offset = Double(rng.next() % 1000) / 1000 * (period - duration)
        let elapsed = time - Double(cycle) * period - offset
        guard elapsed >= 0, elapsed < duration else { return nil }
        return Strike(cycle: cycle, elapsed: elapsed)
    }

    /// Sky flash brightness in `0...1` for a strike `elapsed` seconds in: a bright double flicker
    /// that's over before the bolt fades.
    static func flashStrength(elapsed: TimeInterval) -> Double {
        switch elapsed {
        case ..<0: 0
        case ..<0.1: 1
        case ..<0.2: 0.2
        case ..<0.3: 0.7
        default: 0
        }
    }

    struct Bolt: Equatable {
        /// Where the bolt starts across the sky, `0..<1`.
        let startFraction: Double
        /// The bolt's column for each row, top to bottom, in grid cells from its start.
        let columnOffsets: [Int]
    }

    /// A zigzag bolt `rows` cells tall: it runs straight for a couple of rows, then jogs a cell
    /// sideways, like a hand-drawn sprite. Deterministic per `cycle`.
    static func bolt(cycle: Int, rows: Int) -> Bolt {
        var rng = SplitMix64(seed: seed(for: cycle) &+ 1)
        let startFraction = Double(rng.next() % 1000) / 1000
        var offsets: [Int] = []
        var column = 0
        var run = 0
        for _ in 0..<max(rows, 0) {
            offsets.append(column)
            run += 1
            guard run >= 2 else { continue }
            switch rng.next() % 3 {
            case 0: column -= 1; run = 0
            case 1: column += 1; run = 0
            default: break
            }
        }
        return Bolt(startFraction: startFraction, columnOffsets: offsets)
    }

    private static func seed(for cycle: Int) -> UInt64 {
        UInt64(bitPattern: Int64(cycle)) &* 0x9E3779B97F4A7C15 &+ 0x5EED
    }
}

/// The bolt sprite for one strike: a white core with a colored glow on each side, in chunky
/// cells, starting just under the clouds.
struct PixelLightningBolt: View {
    let cycle: Int
    let color: Color

    static let cell: CGFloat = 4

    var body: some View {
        Canvas { context, size in
            let cell = Self.cell
            let top = (size.height * 0.12 / cell).rounded(.down) * cell
            let rows = max(Int(size.height * 0.6 / cell), 1)
            let bolt = LightningSchedule.bolt(cycle: cycle, rows: rows)
            // Kept to the left 2/3 of the sky so it never strikes through the weather sprite.
            let startX = (size.width * (0.12 + 0.5 * bolt.startFraction) / cell).rounded(.down) * cell

            var glow = Path()
            var core = Path()
            for (row, offset) in bolt.columnOffsets.enumerated() {
                let x = startX + CGFloat(offset) * cell
                let y = top + CGFloat(row) * cell
                glow.addRect(CGRect(x: x - cell, y: y, width: cell * 3, height: cell))
                core.addRect(CGRect(x: x, y: y, width: cell, height: cell))
            }
            context.fill(glow, with: .color(color.opacity(0.8)))
            context.fill(core, with: .color(.white))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Clouds

/// Blocky pixel clouds drifting across the hero sky, one cell step at a time. White and puffy for
/// fair weather, heavy and slate-colored for rain and storms.
struct PixelCloudLayer: View {
    let theme: PixelWeatherTheme
    let isNight: Bool
    let step: Int

    static let cell: CGFloat = 4

    /// The cloud sprite, one string per row: `X` is a filled cell. The last row is drawn in the
    /// shade color to give the cloud a flat, lit-from-above underside.
    static let shape = [
        "...XXX......",
        ".XXXXXX.XX..",
        "XXXXXXXXXXXX",
        ".XXXXXXXXXX.",
    ]

    struct Puff {
        let xFraction: CGFloat
        let yFraction: CGFloat
        /// Cell multiplier: 2 draws the sprite at double size, "closer" to the viewer.
        let scale: CGFloat
        /// Points moved per clock step.
        let speed: Int
    }

    static let puffs = [
        Puff(xFraction: 0.05, yFraction: 0.08, scale: 2, speed: 2),
        Puff(xFraction: 0.55, yFraction: 0.24, scale: 1, speed: 1),
        Puff(xFraction: 0.85, yFraction: 0.04, scale: 1, speed: 1),
    ]

    /// How many of `puffs` to show: none on a clear night, a couple on fair days, a full sky
    /// when it's overcast or precipitating.
    static func cloudCount(for theme: PixelWeatherTheme) -> Int {
        switch theme {
        case .clearNight: 0
        case .clearDay, .misty, .neutral: 2
        case .cloudy, .rainy, .stormy, .snowy: 3
        }
    }

    private var colors: (body: Color, shade: Color) {
        let body: Color
        let shade: Color
        switch theme {
        case .rainy:
            body = Color(red: 0.40, green: 0.46, blue: 0.55)
            shade = Color(red: 0.28, green: 0.33, blue: 0.42)
        case .stormy:
            body = Color(red: 0.30, green: 0.26, blue: 0.42)
            shade = Color(red: 0.20, green: 0.17, blue: 0.30)
        default:
            body = Color(red: 0.97, green: 0.98, blue: 1.0)
            shade = Color(red: 0.80, green: 0.86, blue: 0.92)
        }
        guard isNight && theme.appliesNightModifier else { return (body, shade) }
        return (body.pixelNightShaded(brightness: 0.6), shade.pixelNightShaded(brightness: 0.6))
    }

    var body: some View {
        Canvas { context, size in
            let count = Self.cloudCount(for: theme)
            guard count > 0, size.width > 0 else { return }
            let tones = self.colors
            let opacity = theme == .misty ? 0.7 : 0.95

            for puff in Self.puffs.prefix(count) {
                let cell = Self.cell * puff.scale
                let cloudWidth = CGFloat(Self.shape[0].count) * cell
                let span = size.width + cloudWidth
                let travel = CGFloat(step % 1_000_000 * puff.speed)
                let rawX = (puff.xFraction * span + travel).truncatingRemainder(dividingBy: span) - cloudWidth
                let x = (rawX / cell).rounded(.down) * cell
                let y = (puff.yFraction * size.height / cell).rounded(.down) * cell

                var lit = Path()
                var shade = Path()
                for (row, line) in Self.shape.enumerated() {
                    for (column, character) in line.enumerated() where character == "X" {
                        let rect = CGRect(x: x + CGFloat(column) * cell, y: y + CGFloat(row) * cell, width: cell, height: cell)
                        if row == Self.shape.count - 1 {
                            shade.addRect(rect)
                        } else {
                            lit.addRect(rect)
                        }
                    }
                }
                context.fill(lit, with: .color(tones.body.opacity(opacity)))
                context.fill(shade, with: .color(tones.shade.opacity(opacity)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Snow caps

/// A lumpy pixel snow cap that sits on top of a panel while it's snowing. Deeper in heavier snow.
struct PixelSnowCap: View {
    let intensity: PrecipitationIntensity

    static let cell: CGFloat = 3
    /// How far the cap overlaps the panel's top border, so it reads as resting on it.
    static let overlap: CGFloat = 2
    /// Matches `PixelBevelShape`'s default notch, so the cap doesn't hang off the cut corners.
    static let cornerInset: CGFloat = 4

    static func baseRows(for intensity: PrecipitationIntensity) -> Int {
        switch intensity {
        case .light: 1
        case .normal: 2
        case .heavy: 3
        }
    }

    /// Tallest the cap can be: base depth plus one row of lumps.
    static func height(for intensity: PrecipitationIntensity) -> CGFloat {
        CGFloat(baseRows(for: intensity) + 1) * cell
    }

    /// Rows of snow in `column` out of `columns`: the base depth plus a deterministic 0/1 lump,
    /// tapered by a row at both ends so the cap drapes over the edges instead of ending square.
    static func rows(column: Int, columns: Int, intensity: PrecipitationIntensity) -> Int {
        var rng = SplitMix64(seed: UInt64(max(column, 0)) &+ 0xC0FFEE)
        let lump = Int(rng.next() % 2)
        let taper = (column < 2 || column >= columns - 2) ? 1 : 0
        return max(baseRows(for: intensity) + lump - taper, 1)
    }

    var body: some View {
        Canvas { context, size in
            let cell = Self.cell
            let columns = Int(max(size.width - Self.cornerInset * 2, 0) / cell)
            var snow = Path()
            var shade = Path()
            for column in 0..<columns {
                let rows = Self.rows(column: column, columns: columns, intensity: intensity)
                let x = Self.cornerInset + CGFloat(column) * cell
                let top = size.height - CGFloat(rows) * cell
                snow.addRect(CGRect(x: x, y: top, width: cell, height: CGFloat(rows) * cell))
                if rows > 1 {
                    shade.addRect(CGRect(x: x, y: size.height - cell, width: cell, height: cell))
                }
            }
            context.fill(snow, with: .color(.white.opacity(0.95)))
            context.fill(shade, with: .color(Color(red: 0.78, green: 0.88, blue: 0.95)))
        }
        .frame(height: Self.height(for: intensity))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}
