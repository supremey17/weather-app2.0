import SwiftUI

/// Composes whichever backdrop is selected. Every backdrop is a stock scene drawn in chunky pixels
/// (see `PixelGrid`); only Space swaps in its custom artwork. Animals (and a UFO) wander through
/// on top of each one now and then. Decorative (non-`.weather`) scenes
/// get a theme-driven "weather wash" and (at night) a darkening scrim on top, so a chosen scene
/// still reads as rainy/cloudy/nighttime, just as a backdrop rather than the primary sky.
struct PixelBackgroundLayer: View {
    let background: PixelBackground
    let theme: PixelWeatherTheme
    let isNight: Bool
    var animate: Bool = true

    var body: some View {
        ZStack {
            base
            PixelSceneCanvas(animate: animate) { grid, step in
                grid.drawVisitors(for: background, step: step, isNight: isNight)
            }
            if background != .weather {
                weatherWash
                if isNight {
                    Color(red: 0.03, green: 0.04, blue: 0.12).opacity(0.5)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var base: some View {
        if let assetName = background.assetName, let uiImage = UIImage(named: assetName) {
            // Fills the whole screen; the square art crops at the sides on a tall phone.
            Color.black
                .overlay {
                    Image(uiImage: uiImage)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFill()
                }
                .clipped()
        } else {
            PixelSceneCanvas(animate: animate) { grid, step in
                switch background {
                case .weather: grid.drawStock(theme: theme, isNight: isNight)
                case .space: grid.drawSpace(step: step)
                case .cherryBlossom: grid.drawCherryBlossom(step: step)
                case .mountains: grid.drawMountains(step: step)
                case .river: grid.drawRiver(step: step)
                case .ocean: grid.drawOcean(step: step, isNight: isNight)
                case .beach: grid.drawBeach(step: step)
                }
            }
        }
    }

    /// A translucent wash of the active weather theme's own sky color over a decorative
    /// background, so "it's raining" or "it's foggy" still reads even when you've picked, say, the
    /// beach scene as your backdrop. Returns fully transparent for clear/neutral — nothing to wash
    /// with.
    private var weatherWash: some View {
        let (color, opacity): (Color, Double) = {
            switch theme {
            case .rainy, .stormy: return (theme.skyColor, 0.25)
            case .cloudy: return (theme.skyColor, 0.15)
            case .misty: return (.white, 0.2)
            case .snowy: return (.white, 0.1)
            case .clearDay, .clearNight, .neutral: return (.clear, 0)
            }
        }()
        return color.opacity(opacity)
    }
}

/// Hosts one scene's drawing and feeds it the shared `PixelClock` step (frozen at 0 when motion is
/// off, reduced, or the app is in the background).
private struct PixelSceneCanvas: View {
    let animate: Bool
    let draw: (PixelGrid, Int) -> Void
    @Environment(PixelClock.self) private var clock: PixelClock?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        let step = animate && !reduceMotion && scenePhase == .active ? (clock?.step ?? 0) : 0
        Canvas { context, size in
            draw(PixelGrid(context: context, size: size), step)
        }
    }
}

// MARK: - Pixel grid

/// Paints on a coarse grid of `px`-point squares, so every shape lands on whole "pixels" like an
/// old console game instead of being smoothly anti-aliased.
struct PixelGrid {
    let context: GraphicsContext
    let px: CGFloat = 4
    let cols: Int
    let rows: Int

    init(context: GraphicsContext, size: CGSize) {
        self.context = context
        cols = max(Int((size.width / 4).rounded(.up)), 1)
        rows = max(Int((size.height / 4).rounded(.up)), 1)
    }

    func fill(_ col: Int, _ row: Int, _ width: Int = 1, _ height: Int = 1, _ color: Color) {
        guard width > 0, height > 0 else { return }
        let rect = CGRect(x: CGFloat(col) * px, y: CGFloat(row) * px, width: CGFloat(width) * px, height: CGFloat(height) * px)
        context.fill(Path(rect), with: .color(color))
    }

    /// `count` flat bands blending `top` into `bottom` between rows `from` and `to`, each seam
    /// checker-dithered with the band above — the classic 16-bit sky gradient.
    func bands(_ top: Color, _ bottom: Color, from start: Int = 0, to end: Int? = nil, count: Int = 7) {
        let end = end ?? rows
        let span = max(end - start, 1)
        let color = { (index: Int) in top.blended(with: bottom, by: Double(index) / Double(max(count - 1, 1))) }
        for index in 0..<count {
            let bandTop = start + span * index / count
            let bandBottom = start + span * (index + 1) / count
            fill(0, bandTop, cols, bandBottom - bandTop, color(index))
            guard index > 0 else { continue }
            for col in stride(from: 0, to: cols, by: 2) { fill(col, bandTop, 1, 1, color(index - 1)) }
            for col in stride(from: 1, to: cols, by: 2) { fill(col, bandTop + 1, 1, 1, color(index - 1)) }
        }
    }

    /// Fills everything below a skyline whose height (in rows above `base`) is `height(col)`,
    /// optionally with a lighter `edge` pixel along the top like a grassy or lit rim.
    func ridge(base: Int, color: Color, edge: Color? = nil, height: (Int) -> Int) {
        for col in 0..<cols {
            let top = base - height(col)
            fill(col, top, 1, rows - top, color)
            if let edge { fill(col, top, 1, 1, edge) }
        }
    }

    /// A filled pixel circle.
    func disc(_ centerCol: Int, _ centerRow: Int, radius: Int, _ color: Color) {
        guard radius > 0 else { return fill(centerCol, centerRow, 1, 1, color) }
        for dy in -radius...radius {
            let half = Int(Double(radius * radius - dy * dy).squareRoot().rounded())
            fill(centerCol - half, centerRow + dy, half * 2 + 1, 1, color)
        }
    }

    /// A puffy cloud of three discs over a flat base, with a shaded underside.
    func cloud(_ col: Int, _ row: Int, size: Int, _ color: Color) {
        disc(col - size, row, radius: size, color)
        disc(col + size, row, radius: size, color)
        disc(col, row - size / 2, radius: size + 1, color)
        fill(col - size * 2, row, size * 4 + 1, size + 1, color)
        fill(col - size * 2, row + size, size * 4 + 1, 1, color.blended(with: .black, by: 0.12))
    }

    /// A pine tree `height` rows tall standing on `base`.
    func pine(_ col: Int, base: Int, height: Int, _ color: Color) {
        fill(col, base - 2, 1, 2, Color(red: 0.30, green: 0.18, blue: 0.10))
        for index in 0..<(height - 2) {
            let half = (index % 4 + index / 2) / 2
            fill(col - half, base - height + index, half * 2 + 1, 1, color)
        }
    }

    /// Smooth-but-stepped rolling terrain: two sine waves, quantized to whole rows.
    static func wave(_ col: Int, seed: Double, amplitude: Double, frequency: Double) -> Int {
        let x = Double(col) * frequency
        let value = sin(x + seed) * 0.65 + sin(x * 2.3 + seed * 1.7) * 0.35
        return Int(((value + 1) / 2 * amplitude).rounded())
    }

    /// Stable pseudo-random value in `0..<modulo` for an index, so scenes don't jump between frames.
    static func hash(_ index: Int, _ modulo: Int) -> Int {
        var x = UInt64(truncatingIfNeeded: index) &* 0x9E37_79B9_7F4A_7C15
        x ^= x >> 29
        x = x &* 0xBF58_476D_1CE4_E5B9
        x ^= x >> 32
        return Int(x % UInt64(max(modulo, 1)))
    }

    /// `count` stars over the top `untilRow` rows; a few blink off as `step` advances.
    func stars(count: Int, untilRow: Int, step: Int, color: Color = .white) {
        for index in 0..<count {
            let col = Self.hash(index * 2, cols)
            let row = Self.hash(index * 2 + 1, max(untilRow, 1))
            let blinking = (index + step) % 9 == 0
            fill(col, row, 1, 1, color.opacity(blinking ? 0.25 : 0.9))
            if index % 6 == 0 && !blinking {
                // A few bigger stars get a plus-shaped sparkle.
                fill(col - 1, row, 1, 1, color.opacity(0.4))
                fill(col + 1, row, 1, 1, color.opacity(0.4))
                fill(col, row - 1, 1, 1, color.opacity(0.4))
                fill(col, row + 1, 1, 1, color.opacity(0.4))
            }
        }
    }
}

// MARK: - Scenes

extension PixelGrid {
    /// The default backdrop: the active weather's own sky in dithered bands, stars at night, a
    /// few static clouds by day, and two layers of rolling hills along the bottom.
    func drawStock(theme: PixelWeatherTheme, isNight: Bool) {
        let palette = theme.scenePalette(isNight: isNight)
        let sky = theme.skyColor(isNight: isNight)
        let horizon = rows * 3 / 4
        bands(sky, palette.skyBottom, to: horizon + 8)
        if isNight {
            stars(count: cols / 2, untilRow: horizon - 10, step: 0)
        } else {
            let puff = palette.skyBottom.blended(with: .white, by: 0.7)
            cloud(cols / 5, rows / 6, size: 6, puff)
            cloud(cols * 7 / 10, rows / 3, size: 4, puff)
        }
        ridge(base: horizon + 4, color: palette.farHill) {
            Self.wave($0, seed: 1.2, amplitude: 14, frequency: 0.09)
        }
        ridge(base: rows - rows / 10, color: palette.nearHill, edge: palette.nearHill.blended(with: .white, by: 0.25)) {
            Self.wave($0, seed: 4.0, amplitude: 9, frequency: 0.13)
        }
        fill(0, rows - rows / 10 + 4, cols, rows, palette.ground)
    }

    func drawSpace(step: Int) {
        bands(Color(red: 0.02, green: 0.02, blue: 0.08), Color(red: 0.16, green: 0.06, blue: 0.30))
        // A faint purple nebula band across the middle.
        for col in 0..<cols {
            let row = rows / 2 + Self.wave(col, seed: 0.4, amplitude: 24, frequency: 0.07) - 12
            fill(col, row, 1, 6, Color(red: 0.55, green: 0.25, blue: 0.70).opacity(0.18))
            fill(col, row + 2, 1, 2, Color(red: 0.85, green: 0.40, blue: 0.80).opacity(0.15))
        }
        stars(count: cols, untilRow: rows, step: step)

        // Ringed planet.
        let planetCol = cols * 3 / 4, planetRow = rows / 5
        disc(planetCol, planetRow, radius: 7, Color(red: 0.86, green: 0.55, blue: 0.30))
        disc(planetCol - 2, planetRow - 2, radius: 4, Color(red: 0.96, green: 0.72, blue: 0.42))
        fill(planetCol - 7, planetRow + 2, 15, 1, Color(red: 0.62, green: 0.36, blue: 0.20))
        fill(planetCol - 12, planetRow, 25, 1, Color(red: 0.95, green: 0.86, blue: 0.62))

        // Little moon that drifts across.
        let moonCol = (cols / 5 + step / 8) % (cols + 8) - 4
        disc(moonCol, rows * 2 / 5, radius: 3, Color(red: 0.78, green: 0.78, blue: 0.84))
        fill(moonCol + 1, rows * 2 / 5 - 1, 1, 1, Color(red: 0.60, green: 0.60, blue: 0.66))

        // Shooting star every ~16 seconds.
        let streak = step % 64
        if streak < 8 {
            let startCol = Self.hash(step / 64, cols)
            for tail in 0..<4 {
                fill(startCol + streak * 3 - tail, rows / 8 + streak * 2 - tail / 2, 1, 1, Color.white.opacity(1 - Double(tail) * 0.25))
            }
        }
    }

    func drawCherryBlossom(step: Int) {
        bands(Color(red: 0.80, green: 0.76, blue: 0.96), Color(red: 1.00, green: 0.86, blue: 0.90), to: rows * 3 / 4)
        disc(cols * 3 / 4, rows / 4, radius: 6, Color(red: 1.00, green: 0.95, blue: 0.85))
        ridge(base: rows * 3 / 4, color: Color(red: 0.70, green: 0.56, blue: 0.74)) {
            Self.wave($0, seed: 2.0, amplitude: 16, frequency: 0.08)
        }
        let grass = Color(red: 0.40, green: 0.66, blue: 0.40)
        ridge(base: rows * 7 / 8, color: grass, edge: Color(red: 0.58, green: 0.80, blue: 0.50)) {
            Self.wave($0, seed: 5.0, amplitude: 6, frequency: 0.12)
        }

        // Cherry tree.
        let trunkCol = cols / 4, groundRow = rows * 7 / 8 - 2
        let bark = Color(red: 0.36, green: 0.22, blue: 0.16)
        fill(trunkCol - 2, groundRow - 34, 4, 34, bark)
        fill(trunkCol + 2, groundRow - 28, 6, 2, bark)
        fill(trunkCol - 8, groundRow - 24, 6, 2, bark)
        let blossoms = [
            Color(red: 0.93, green: 0.56, blue: 0.70),
            Color(red: 0.98, green: 0.70, blue: 0.80),
            Color(red: 1.00, green: 0.84, blue: 0.90),
        ]
        for (layer, color) in blossoms.enumerated() {
            let lift = layer * 2
            disc(trunkCol - 10, groundRow - 34 - lift, radius: 11 - layer * 3, color)
            disc(trunkCol + 10, groundRow - 37 - lift, radius: 12 - layer * 3, color)
            disc(trunkCol, groundRow - 46 - lift, radius: 13 - layer * 3, color)
        }

        // Falling petals.
        for index in 0..<24 {
            let fall = step + index * 11
            let col = (Self.hash(index, cols) + fall / 3) % cols
            let row = (Self.hash(index + 99, rows) + fall) % rows
            fill(col, row, 1, 1, blossoms[index % 3])
        }
    }

    func drawMountains(step: Int) {
        bands(Color(red: 0.16, green: 0.20, blue: 0.42), Color(red: 0.98, green: 0.70, blue: 0.52), to: rows * 2 / 3)
        let drift = step / 4
        cloud((cols / 6 + drift) % (cols + 20) - 10, rows / 7, size: 6, Color(red: 0.98, green: 0.84, blue: 0.80))
        cloud((cols * 2 / 3 + drift / 2) % (cols + 20) - 10, rows / 4, size: 4, Color(red: 0.98, green: 0.80, blue: 0.76))

        let base = rows * 3 / 4
        let peaks = [(cols / 5, 54), (cols / 2, 70), (cols * 4 / 5, 50), (cols + 6, 40)]
        let height = { (col: Int) -> Int in
            let peak = peaks.map { $0.1 - abs(col - $0.0) * 3 / 2 }.max() ?? 0
            return max(peak + Self.wave(col, seed: 3.0, amplitude: 4, frequency: 0.5), 0)
        }
        let rock = Color(red: 0.36, green: 0.36, blue: 0.52)
        ridge(base: base, color: rock, height: height)
        // Lit left faces and snow caps on top of the rock.
        for col in 0..<cols {
            let h = height(col)
            let top = base - h
            if height(col + 1) > h {
                fill(col, top, 1, h / 2, Color(red: 0.48, green: 0.46, blue: 0.62))
            }
            if h > 40 {
                fill(col, top, 1, min((h - 40) / 2 + 2, 10), Color(red: 0.95, green: 0.95, blue: 1.00))
            }
        }

        let forest = Color(red: 0.10, green: 0.30, blue: 0.24)
        ridge(base: rows * 7 / 8, color: forest) {
            Self.wave($0, seed: 0.7, amplitude: 8, frequency: 0.1)
        }
        for index in 0..<(cols / 6) {
            let col = index * 6 + Self.hash(index, 4)
            let ground = rows * 7 / 8 - Self.wave(col, seed: 0.7, amplitude: 8, frequency: 0.1)
            pine(col, base: ground + 1, height: 9 + Self.hash(index + 7, 6), Color(red: 0.06, green: 0.22, blue: 0.18))
        }
    }

    func drawRiver(step: Int) {
        bands(Color(red: 0.40, green: 0.70, blue: 0.95), Color(red: 0.84, green: 0.94, blue: 0.96), to: rows * 2 / 3)
        disc(cols * 4 / 5, rows / 6, radius: 5, Color(red: 1.00, green: 0.92, blue: 0.55))
        cloud((cols / 3 + step / 6) % (cols + 20) - 10, rows / 5, size: 6, .white)

        ridge(base: rows * 2 / 3, color: Color(red: 0.36, green: 0.56, blue: 0.62)) {
            Self.wave($0, seed: 1.0, amplitude: 14, frequency: 0.07)
        }
        let meadow = Color(red: 0.34, green: 0.64, blue: 0.30)
        ridge(base: rows * 3 / 4, color: meadow, edge: Color(red: 0.52, green: 0.78, blue: 0.40)) {
            Self.wave($0, seed: 2.5, amplitude: 6, frequency: 0.1)
        }
        for index in 0..<(cols / 8) {
            let col = index * 8 + Self.hash(index, 5)
            pine(col, base: rows * 3 / 4 - Self.wave(col, seed: 2.5, amplitude: 6, frequency: 0.1) + 1,
                 height: 8 + Self.hash(index, 5), Color(red: 0.14, green: 0.40, blue: 0.24))
        }

        // River with banks, and ripples flowing to the right.
        let riverTop = rows * 4 / 5, riverBottom = riverTop + rows / 9
        fill(0, riverTop - 1, cols, 1, Color(red: 0.62, green: 0.50, blue: 0.32))
        bands(Color(red: 0.24, green: 0.55, blue: 0.80), Color(red: 0.12, green: 0.34, blue: 0.62), from: riverTop, to: riverBottom, count: 3)
        fill(0, riverBottom, cols, 1, Color(red: 0.62, green: 0.50, blue: 0.32))
        fill(0, riverBottom + 1, cols, rows, Color(red: 0.30, green: 0.56, blue: 0.26))
        for index in 0..<12 {
            let col = (Self.hash(index, cols) + step) % (cols + 6) - 3
            let row = riverTop + 1 + Self.hash(index + 40, max(riverBottom - riverTop - 2, 1))
            fill(col, row, 3, 1, Color.white.opacity(0.6))
        }
        // Reeds along the near bank.
        for index in 0..<(cols / 5) {
            let col = index * 5 + Self.hash(index, 3)
            fill(col, riverBottom - 2, 1, 3, Color(red: 0.20, green: 0.44, blue: 0.20))
            fill(col, riverBottom - 3, 1, 1, Color(red: 0.55, green: 0.36, blue: 0.20))
        }
    }

    func drawOcean(step: Int, isNight: Bool) {
        let horizon = rows / 2
        if isNight {
            bands(Color(red: 0.02, green: 0.04, blue: 0.14), Color(red: 0.10, green: 0.16, blue: 0.36), to: horizon)
            stars(count: cols / 2, untilRow: horizon - 6, step: step)
        } else {
            bands(Color(red: 0.36, green: 0.66, blue: 0.95), Color(red: 1.00, green: 0.84, blue: 0.62), to: horizon)
            cloud(cols / 5, rows / 6, size: 6, .white)
        }
        let orb = isNight ? Color(red: 0.88, green: 0.88, blue: 0.92) : Color(red: 1.00, green: 0.80, blue: 0.36)
        disc(cols / 2, horizon - 6, radius: isNight ? 5 : 8, orb)

        bands(
            isNight ? Color(red: 0.06, green: 0.14, blue: 0.30) : Color(red: 0.16, green: 0.48, blue: 0.70),
            isNight ? Color(red: 0.02, green: 0.05, blue: 0.14) : Color(red: 0.06, green: 0.22, blue: 0.42),
            from: horizon, count: 5
        )
        // Sun/moon glitter on the water, then wave crests scrolling sideways.
        for row in stride(from: horizon + 1, to: rows, by: 3) {
            let spread = (row - horizon) / 10 + 3
            let jitter = Self.hash(row + step, 3) - 1
            fill(cols / 2 - spread / 2 + jitter, row, spread, 1, orb.opacity(0.55))
        }
        for index in 0..<(cols / 2) {
            let row = horizon + 2 + Self.hash(index + 7, rows - horizon - 2)
            let speed = 1 + (row - horizon) * 3 / max(rows - horizon, 1)
            let col = (Self.hash(index, cols) + step * speed) % (cols + 4) - 2
            fill(col, row, 2 + speed, 1, Color.white.opacity(isNight ? 0.2 : 0.35))
        }
    }

    func drawBeach(step: Int) {
        bands(Color(red: 0.34, green: 0.70, blue: 0.96), Color(red: 0.86, green: 0.96, blue: 0.98), to: rows * 3 / 5)
        disc(cols * 4 / 5, rows / 7, radius: 6, Color(red: 1.00, green: 0.90, blue: 0.40))
        cloud((cols / 4 + step / 6) % (cols + 20) - 10, rows / 5, size: 6, .white)

        let seaTop = rows * 3 / 5, sandTop = rows * 3 / 4
        bands(Color(red: 0.18, green: 0.62, blue: 0.80), Color(red: 0.24, green: 0.78, blue: 0.80), from: seaTop, to: sandTop, count: 4)
        // Waves rolling up the sand: the foam line advances and retreats.
        let surge = [0, 1, 2, 3, 3, 2, 1, 0][step % 8]
        let sand = Color(red: 0.94, green: 0.84, blue: 0.60)
        ridge(base: rows, color: sand, edge: Color.white.opacity(0.85)) { col in
            rows - sandTop - surge + Self.wave(col, seed: 0.3, amplitude: 2, frequency: 0.3)
        }
        for index in 0..<(cols * 2) {
            fill(Self.hash(index, cols), sandTop + 3 + Self.hash(index + 500, rows - sandTop), 1, 1, Color(red: 0.84, green: 0.72, blue: 0.48))
        }

        // Palm tree with a gently curving trunk and drooping fronds.
        let baseCol = cols / 5, baseRow = rows * 4 / 5
        let trunk = [Color(red: 0.52, green: 0.34, blue: 0.18), Color(red: 0.66, green: 0.46, blue: 0.24)]
        for segment in 0..<16 {
            fill(baseCol + segment * segment / 40, baseRow - segment * 2, 3, 2, trunk[segment % 2])
        }
        let crownCol = baseCol + 7, crownRow = baseRow - 32
        let leaf = Color(red: 0.20, green: 0.58, blue: 0.28)
        for direction in [-1, 1] {
            for index in 0..<12 {
                let droop = index * index / 14
                fill(crownCol + direction * index, crownRow + droop - 1, 1, 2, leaf)
                fill(crownCol + direction * index / 2, crownRow - index / 2 - 2, 1, 2, leaf.blended(with: .white, by: 0.2))
            }
        }
        disc(crownCol, crownRow + 1, radius: 1, Color(red: 0.40, green: 0.26, blue: 0.12))
    }
}

private extension Color {
    /// Linear RGB blend toward `other` (`Color.mix` needs iOS 18; the app supports 17).
    func blended(with other: Color, by fraction: Double) -> Color {
        var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
        guard UIColor(self).getRed(&r1, green: &g1, blue: &b1, alpha: &a1),
              UIColor(other).getRed(&r2, green: &g2, blue: &b2, alpha: &a2) else { return self }
        let t = CGFloat(min(max(fraction, 0), 1))
        return Color(red: r1 + (r2 - r1) * t, green: g1 + (g2 - g1) * t, blue: b1 + (b2 - b1) * t, opacity: a1 + (a2 - a1) * t)
    }
}

// MARK: - Visitors

/// Tiny sprites for the animals that wander through: one string per row, one character per pixel,
/// colors looked up per call ('.' and unknown characters stay clear). Two frames each, alternated
/// on every clock step for a flap/walk cycle.
private enum Visitor {
    static let bird = [["K...K", ".K.K.", "..K.."], [".....", "KKKKK", "..K.."]]
    static let bat = [["K.....K", "KK.K.KK", ".KKKKK.", "...K..."], [".......", ".KKKKK.", "KK.K.KK", "K..K..K"]]
    static let butterfly = [["PP.PP", "PPKPP", "PPKPP", ".P.P."], [".....", ".PKP.", ".PKP.", "..P.."]]
    static let deer = [
        ["......N.", ".....NN.", ".....NNN", "NNNNNNN.", "NNNNNN..", "N.N..N.N"],
        ["......N.", ".....NN.", ".....NNN", "NNNNNNN.", "NNNNNN..", ".N.NN.N."],
    ]
    static let duck = [["....GG..", "....GGO.", "NN.NNN..", "NNNNNN.."], ["....GG..", "....GGO.", "NNNNNN..", ".NNNNN.."]]
    static let dolphin = [["....B...", ".BBBBBB.", "BBWWWBBB", "B......."], ["....B...", ".BBBBBB.", "BBWWWBBB", ".B......"]]
    static let crab = [["K.....K", "RR...RR", ".RRRRR.", "R.R.R.R"], ["K.....K", "RR...RR", ".RRRRR.", ".R.R.R."]]
    static let ufo = [["...CCC...", "..CCCCC..", "LLLLLLLLL", ".Y.Y.Y.Y."], ["...CCC...", "..CCCCC..", "LLLLLLLLL", "Y.Y.Y.Y.Y"]]
}

extension PixelGrid {
    func sprite(_ rows: [String], _ col: Int, _ row: Int, _ colors: [Character: Color], flipped: Bool = false) {
        for (r, line) in rows.enumerated() {
            let chars = Array(line)
            for (c, char) in chars.enumerated() {
                guard let color = colors[char] else { continue }
                fill(flipped ? col + chars.count - 1 - c : col + c, row + r, 1, 1, color)
            }
        }
    }

    /// Walks/flies `frames` across the screen once every `period` steps at `speed` columns per
    /// step (right-to-left when `leftward`), and draws nothing for the rest of the period, so each
    /// visitor comes and goes. `bob` nudges the row per step for a little bounce.
    func visitor(_ frames: [[String]], step: Int, period: Int, speed: Int = 1, row: Int,
                 colors: [Character: Color], leftward: Bool = false, delay: Int = 0, bob: (Int) -> Int = { _ in 0 }) {
        let lap = (step + delay) % period
        let width = frames[0][0].count
        let travelled = lap * speed - width
        guard travelled < cols else { return }
        let col = leftward ? cols - travelled - width : travelled
        sprite(frames[step % frames.count], col, row + bob(lap), colors, flipped: leftward)
    }

    func drawVisitors(for background: PixelBackground, step: Int, isNight: Bool) {
        let ink: [Character: Color] = ["K": Color(red: 0.12, green: 0.12, blue: 0.18)]
        let gull: [Character: Color] = ["K": .white]
        let flutter = { (lap: Int) in lap / 2 % 3 == 0 ? -1 : 0 }
        switch background {
        case .weather:
            if isNight {
                visitor(Visitor.bat, step: step, period: 240, speed: 2, row: rows / 5, colors: ink, bob: flutter)
            } else {
                visitor(Visitor.bird, step: step, period: 200, speed: 2, row: rows / 6, colors: ink, bob: flutter)
                visitor(Visitor.bird, step: step, period: 200, speed: 2, row: rows / 6 + 5, colors: ink, delay: 196, bob: flutter)
            }
        case .space:
            visitor(Visitor.ufo, step: step, period: 260, speed: 2, row: rows / 3, colors: [
                "C": Color(red: 0.55, green: 0.95, blue: 0.75), "L": Color(red: 0.70, green: 0.72, blue: 0.80),
                "Y": Color(red: 1.00, green: 0.90, blue: 0.30),
            ], leftward: true) { lap in Int((sin(Double(lap) * 0.2) * 3).rounded()) }
        case .cherryBlossom:
            let wings: [Character: Color] = ["P": Color(red: 1.00, green: 0.60, blue: 0.20), "K": Color(red: 0.20, green: 0.12, blue: 0.10)]
            visitor(Visitor.butterfly, step: step, period: 220, row: rows * 3 / 5, colors: wings) { lap in
                Int((sin(Double(lap) * 0.35) * 4).rounded())
            }
        case .mountains:
            visitor(Visitor.bird, step: step, period: 180, speed: 2, row: rows / 3, colors: ink, leftward: true, bob: flutter)
            visitor(Visitor.deer, step: step, period: 320, row: rows * 7 / 8 + 4, colors: ["N": Color(red: 0.62, green: 0.40, blue: 0.22)])
        case .river:
            visitor(Visitor.duck, step: step, period: 300, row: rows * 4 / 5 + 1, colors: [
                "G": Color(red: 0.12, green: 0.50, blue: 0.24), "O": Color(red: 1.00, green: 0.62, blue: 0.10),
                "N": Color(red: 0.55, green: 0.40, blue: 0.26),
            ])
            visitor(Visitor.bird, step: step, period: 200, speed: 2, row: rows / 4, colors: ink, leftward: true, bob: flutter)
        case .ocean:
            let horizon = rows / 2
            visitor(Visitor.dolphin, step: step, period: 200, row: horizon + 10, colors: [
                "B": Color(red: 0.45, green: 0.58, blue: 0.72), "W": Color(red: 0.86, green: 0.90, blue: 0.94),
            ]) { lap in -Int((abs(sin(Double(lap) * 0.15)) * 8).rounded()) }
            visitor(Visitor.bird, step: step, period: 180, speed: 2, row: rows / 5, colors: gull, leftward: true, delay: 60, bob: flutter)
        case .beach:
            visitor(Visitor.crab, step: step, period: 360, row: rows * 7 / 8, colors: [
                "R": Color(red: 0.90, green: 0.30, blue: 0.22), "K": Color(red: 0.12, green: 0.12, blue: 0.18),
            ], leftward: true)
            visitor(Visitor.bird, step: step, period: 160, speed: 2, row: rows / 4, colors: gull, bob: flutter)
        }
    }
}
