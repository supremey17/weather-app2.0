import SwiftUI

/// How a full-page rain/snow particle sweep should look and behave for a given theme/intensity/
/// time of day. `nil` from `make` means "don't show particles at all" (e.g. clear skies, cloudy
/// with no actual precipitation, misty/neutral).
struct WeatherParticleConfig: Equatable {
    enum Kind: Equatable { case rain, snow }
    let kind: Kind
    let count: Int
    let speed: Double          // points per tick, vertical fall speed
    let length: Double         // rain streak length / snow dot size, points
    let width: Double
    let baseOpacity: Double
    let splashChance: Double   // 0...1, probability a given particle CAN splash on collision
    /// Horizontal points per tick: the wind slant on rain. Wraps around the screen edges.
    var drift: Double = 0
    /// Side-to-side sway amplitude in points (snow only); applied around the particle's `x`.
    var sway: Double = 0
    /// Share of particles on the dim, slower back layer, which never splashes on panels.
    var farFraction: Double = 0

    /// Simulation rate of the particle layer. Speeds above are "per tick" at this rate.
    static let ticksPerSecond: Double = 20
    /// The pixel grid every particle is snapped to when drawn, in points.
    static let pixel: Double = 3
    /// Back-layer particles fall at this fraction of `speed`/`drift`.
    static let farSpeedFactor: Double = 0.55

    /// `nil` unless `theme` is `.rainy`, `.stormy`, or `.snowy` (the only themes with actual
    /// falling precipitation — cloudy/misty/neutral/clear never show particles, which is a
    /// deliberate change from the old behavior where "cloudy" showed faint rain streaks with no
    /// actual rain).
    static func make(theme: PixelWeatherTheme, intensity: PrecipitationIntensity, isNight: Bool) -> WeatherParticleConfig? {
        let opacityScale = theme.particleOpacityScale(isNight: isNight)

        switch theme {
        case .rainy:
            return rainConfig(intensity: intensity, opacityScale: opacityScale)
        case .stormy:
            return rainConfig(intensity: stormIntensity(from: intensity), opacityScale: opacityScale)
        case .snowy:
            return snowConfig(intensity: intensity, opacityScale: opacityScale)
        case .clearDay, .clearNight, .cloudy, .misty, .neutral:
            return nil
        }
    }

    /// The draw color for this particle kind against this theme: white for snow, `theme.palette`'s
    /// `neon` field for rain (a panel-family color that — per `PixelPalette.nightAdjusted()` — does
    /// NOT change at night, so the drops' own color stays consistent, only their opacity dims).
    /// Storms use a cool lavender instead, since their neon is lightning yellow.
    func color(theme: PixelWeatherTheme) -> Color {
        switch (kind, theme) {
        case (.snow, _): .white
        case (.rain, .stormy): Color(red: 0.70, green: 0.74, blue: 0.96)
        case (.rain, _): theme.palette.neon
        }
    }

    /// How many ticks a splash stays on screen before its particle respawns.
    static func splashTicks(for kind: Kind) -> Int {
        kind == .snow ? 8 : 6
    }

    /// `.stormy` uses the rain row one level up from the given intensity (light->normal,
    /// normal->heavy, heavy->heavy) — storms are never dainty.
    private static func stormIntensity(from intensity: PrecipitationIntensity) -> PrecipitationIntensity {
        switch intensity {
        case .light: return .normal
        case .normal: return .heavy
        case .heavy: return .heavy
        }
    }

    private static func rainConfig(intensity: PrecipitationIntensity, opacityScale: Double) -> WeatherParticleConfig {
        switch intensity {
        case .light:
            return WeatherParticleConfig(
                kind: .rain, count: 36, speed: 12, length: 9, width: 3,
                baseOpacity: 0.60 * opacityScale, splashChance: 0.3,
                drift: 1.5, farFraction: 0.45
            )
        case .normal:
            return WeatherParticleConfig(
                kind: .rain, count: 70, speed: 18, length: 12, width: 3,
                baseOpacity: 0.75 * opacityScale, splashChance: 0.5,
                drift: 3, farFraction: 0.45
            )
        case .heavy:
            return WeatherParticleConfig(
                kind: .rain, count: 120, speed: 26, length: 18, width: 3,
                baseOpacity: 0.85 * opacityScale, splashChance: 0.8,
                drift: 6, farFraction: 0.4
            )
        }
    }

    private static func snowConfig(intensity: PrecipitationIntensity, opacityScale: Double) -> WeatherParticleConfig {
        switch intensity {
        case .light:
            return WeatherParticleConfig(
                kind: .snow, count: 30, speed: 2, length: 3, width: 3,
                baseOpacity: 0.90 * opacityScale, splashChance: 0.25,
                drift: 0.3, sway: 6, farFraction: 0.4
            )
        case .normal:
            return WeatherParticleConfig(
                kind: .snow, count: 54, speed: 3, length: 3, width: 3,
                baseOpacity: 0.90 * opacityScale, splashChance: 0.40,
                drift: 0.5, sway: 7, farFraction: 0.4
            )
        case .heavy:
            return WeatherParticleConfig(
                kind: .snow, count: 90, speed: 4.5, length: 3, width: 3,
                baseOpacity: 0.90 * opacityScale, splashChance: 0.60,
                drift: 1.2, sway: 8, farFraction: 0.35
            )
        }
    }
}

/// Rounds a coordinate down onto the particle pixel grid, so every drop and flake lands on whole
/// "game pixels" instead of sliding smoothly between them.
func pixelSnapped(_ value: Double, grid: Double = WeatherParticleConfig.pixel) -> Double {
    guard grid > 0, value.isFinite else { return value }
    return (value / grid).rounded(.down) * grid
}

/// Seeded, deterministic PRNG so particle motion/spawn decisions are reproducible in tests.
struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64
    init(seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

/// Collects the on-screen rects of UI panels that falling particles can splash against, in a
/// single shared coordinate space. A PLAIN class (NOT `@Observable`/`@Published`) — writes here
/// must never trigger a SwiftUI view re-render; the particle engine polls it only during its own
/// tick, which is the entire point of keeping this outside the Observation system.
final class PanelColliderStore {
    private var contentRects: [String: CGRect] = [:]
    /// The scrollable content's own origin Y in the shared "weatherPage" coordinate space —
    /// effectively the current scroll offset. Written by `ContentView`.
    var contentOriginY: CGFloat = 0
    /// The particle canvas's own origin Y in "weatherPage" (usually 0, but don't assume — measure
    /// it, since the canvas typically `.ignoresSafeArea()` while the scroll content doesn't).
    var canvasOriginY: CGFloat = 0

    func update(id: String, rect: CGRect) {
        contentRects[id] = rect
    }

    func remove(id: String) {
        contentRects.removeValue(forKey: id)
    }

    /// Every registered panel rect, translated from content space into the particle canvas's own
    /// coordinate space, sorted by `minY` ascending (the engine relies on this order to find the
    /// *first* collider a falling particle would hit).
    func collidersInCanvasSpace() -> [CGRect] {
        let offset = contentOriginY - canvasOriginY
        return contentRects.values
            .map { $0.offsetBy(dx: 0, dy: offset) }
            .sorted { $0.minY < $1.minY }
    }
}

private struct WeatherColliderStoreKey: EnvironmentKey {
    static let defaultValue: PanelColliderStore? = nil
}

private struct WeatherSnowCoverKey: EnvironmentKey {
    static let defaultValue: PrecipitationIntensity? = nil
}

extension EnvironmentValues {
    var weatherColliderStore: PanelColliderStore? {
        get { self[WeatherColliderStoreKey.self] }
        set { self[WeatherColliderStoreKey.self] = newValue }
    }

    /// How hard it's snowing, or `nil` when it isn't. Every `weatherCollider` panel wears a
    /// matching pixel snow cap while this is set.
    var weatherSnowCover: PrecipitationIntensity? {
        get { self[WeatherSnowCoverKey.self] }
        set { self[WeatherSnowCoverKey.self] = newValue }
    }
}

extension View {
    /// Tags this view as a surface falling rain/snow can splash against (and, while it's snowing,
    /// gives it a pixel snow cap — see `weatherSnowCover`). Reads the ambient
    /// `weatherColliderStore` from the environment; if it's `nil` (e.g. this view is reused on a
    /// screen with no particle layer, like Settings), this is a no-op — never crashes, never
    /// requires the caller to check anything.
    func weatherCollider(_ id: String) -> some View {
        modifier(WeatherColliderModifier(id: id))
    }
}

private struct WeatherColliderModifier: ViewModifier {
    let id: String
    @Environment(\.weatherColliderStore) private var store: PanelColliderStore?
    @Environment(\.weatherSnowCover) private var snowCover: PrecipitationIntensity?

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let snowCover {
                    PixelSnowCap(intensity: snowCover)
                        .offset(y: PixelSnowCap.overlap - PixelSnowCap.height(for: snowCover))
                }
            }
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("weatherContent"))
            } action: { rect in
                store?.update(id: id, rect: rect)
            }
            .onDisappear {
                store?.remove(id: id)
            }
    }
}

/// One falling drop/flake. `willSplash` is decided ONCE at spawn (not re-rolled every tick) so a
/// given drop's behavior doesn't flicker — either it's a drop that can splash this fall, or it
/// isn't, decided before it starts falling.
struct WeatherParticle: Equatable {
    var x: Double
    var y: Double
    var willSplash: Bool
    var splash: Splash?
    /// 1 = front layer (full speed, can splash on panels), 0 = dim back layer for depth.
    var depth: Int = 1
    /// Snow flake shape on the front layer: 0 = 2x2 block, 1 = plus, 2 = cross. Unused for rain.
    var variant: Int = 0
    /// Sway phase in radians, advanced every tick (only matters when `config.sway` is non-zero).
    var phase: Double = 0

    struct Splash: Equatable {
        var x: Double
        var y: Double
        var ticksRemaining: Int
    }

    /// Where this particle is drawn and collides horizontally: `x` plus the snow sway offset.
    func displayX(config: WeatherParticleConfig) -> Double {
        config.sway == 0 ? x : x + sin(phase) * config.sway
    }
}

/// Stateful, per-tick particle simulation — pure enough to unit test directly (see
/// `tick(_:colliders:config:width:height:collisionsEnabled:rng:)`), with a thin stateful wrapper
/// (`advance`) that the SwiftUI layer drives once per tick.
final class WeatherParticleEngine {
    private(set) var particles: [WeatherParticle] = []
    private var rng: SplitMix64
    private var lastStep: Int?
    private var lastConfig: WeatherParticleConfig?
    private var lastSize: CGSize = .zero
    private var lastContentOriginY: CGFloat = 0

    init(seed: UInt64 = 0xA11CE) {
        rng = SplitMix64(seed: seed)
    }

    /// Whether `particles` is a live simulation for this exact config and canvas size, so a paused
    /// layer can keep showing it frozen instead of jumping to `staticScatter`.
    func isSimulating(config: WeatherParticleConfig, size: CGSize) -> Bool {
        !particles.isEmpty && lastConfig == config && lastSize == size
    }

    /// Advances the simulation to `step`, mutating `particles` in place. Idempotent per step: if
    /// `step == lastStep`, does nothing (so re-evaluating the view for unrelated reasons never
    /// double-advances). Reseeds (randomizes every particle's position/x fresh, no catch-up burst)
    /// when `config`/`size` changed, this is the first call, or the step delta is outside `1...4`
    /// (e.g. resuming after the app was backgrounded for a while).
    func advance(
        to step: Int,
        size: CGSize,
        colliders: [CGRect],
        contentOriginY: CGFloat,
        config: WeatherParticleConfig
    ) {
        if step == lastStep {
            return
        }

        let delta = lastStep.map { step - $0 }
        let needsReseed = config != lastConfig || size != lastSize || delta == nil || !(1...4).contains(delta ?? 0)

        var effectiveDelta = delta ?? 1
        if needsReseed {
            let width = Double(size.width)
            let height = Double(size.height)
            particles = (0..<max(config.count, 0)).map { _ in
                var particle = WeatherParticle(
                    x: Double.random(in: 0..<max(width, 1), using: &rng),
                    y: Double.random(in: 0..<max(height, 1), using: &rng),
                    willSplash: false,
                    splash: nil
                )
                WeatherParticleEngine.rollTraits(&particle, config: config, rng: &rng)
                return particle
            }
            effectiveDelta = 1
        }

        let collisionsEnabled = abs(contentOriginY - lastContentOriginY) <= 1

        let width = Double(size.width)
        let height = Double(size.height)
        let tickCount = min(max(effectiveDelta, 1), 4)

        for index in particles.indices {
            for _ in 0..<tickCount {
                WeatherParticleEngine.tick(
                    &particles[index],
                    colliders: colliders,
                    config: config,
                    width: width,
                    height: height,
                    collisionsEnabled: collisionsEnabled,
                    rng: &rng
                )
            }
        }

        lastStep = step
        lastConfig = config
        lastSize = size
        lastContentOriginY = contentOriginY
    }

    /// Pure per-tick state transition for one particle — this is what the tests exercise directly,
    /// with no view, no engine state, no clock involved.
    ///   - A splashing particle counts its splash down and respawns above the top when it ends.
    ///   - Otherwise it falls by `config.speed` (scaled down on the back layer) and drifts sideways
    ///     by `config.drift`, wrapping around the screen edges. A front-layer particle that
    ///     `willSplash` stops at the FIRST collider (sorted by `minY`) whose top edge its bottom
    ///     crosses this tick, within that collider's x-range, and splashes right at `rect.minY`.
    ///   - Falling past `height` respawns it above the top.
    static func tick(
        _ particle: inout WeatherParticle,
        colliders: [CGRect],
        config: WeatherParticleConfig,
        width: Double,
        height: Double,
        collisionsEnabled: Bool,
        rng: inout SplitMix64
    ) {
        if var splash = particle.splash {
            splash.ticksRemaining -= 1
            if splash.ticksRemaining <= 0 {
                respawn(&particle, width: width, height: height, config: config, rng: &rng)
            } else {
                particle.splash = splash
            }
            return
        }

        let factor = particle.depth == 0 ? WeatherParticleConfig.farSpeedFactor : 1
        let previousY = particle.y
        let movedY = previousY + config.speed * factor

        if collisionsEnabled && particle.willSplash && particle.depth == 1 {
            let hitX = particle.displayX(config: config)
            let bottomBefore = previousY + config.length
            let bottomAfter = movedY + config.length
            for rect in colliders {
                guard rect.minX <= hitX, hitX <= rect.maxX else { continue }
                if bottomBefore < rect.minY && bottomAfter >= rect.minY {
                    particle.splash = WeatherParticle.Splash(
                        x: hitX,
                        y: rect.minY,
                        ticksRemaining: WeatherParticleConfig.splashTicks(for: config.kind)
                    )
                    return
                }
            }
        }

        particle.y = movedY
        particle.x = wrapped(particle.x + config.drift * factor, width: width)
        if config.sway != 0 {
            particle.phase += 0.15 * factor
        }

        if particle.y > height {
            respawn(&particle, width: width, height: height, config: config, rng: &rng)
        }
    }

    /// Keeps `x` inside `0..<width`, so wind-blown particles leaving one edge come back on the other.
    static func wrapped(_ x: Double, width: Double) -> Double {
        guard width > 0, x.isFinite else { return x }
        let remainder = x.truncatingRemainder(dividingBy: width)
        return remainder < 0 ? remainder + width : remainder
    }

    private static func respawn(
        _ particle: inout WeatherParticle,
        width: Double,
        height: Double,
        config: WeatherParticleConfig,
        rng: inout SplitMix64
    ) {
        particle.x = Double.random(in: 0..<max(width, 1), using: &rng)
        particle.y = -Double.random(in: 0...max(height * 0.25, 0), using: &rng)
        particle.splash = nil
        rollTraits(&particle, config: config, rng: &rng)
    }

    /// Picks a particle's layer, whether it can splash, its flake shape, and its sway phase.
    /// Back-layer particles never splash: they're "behind" the panels.
    private static func rollTraits(_ particle: inout WeatherParticle, config: WeatherParticleConfig, rng: inout SplitMix64) {
        let layerRoll = Double.random(in: 0..<1, using: &rng)
        let splashRoll = Double.random(in: 0..<1, using: &rng)
        let shapeRoll = Int.random(in: 0..<10, using: &rng)
        particle.depth = layerRoll < config.farFraction ? 0 : 1
        particle.willSplash = particle.depth == 1 && splashRoll < config.splashChance
        particle.variant = particle.depth == 0 ? 0 : (shapeRoll < 4 ? 0 : (shapeRoll < 8 ? 1 : 2))
        particle.phase = Double.random(in: 0..<(2 * Double.pi), using: &rng)
    }

    /// For reduce-motion / backgrounded / clock-not-running: a static, deterministic scatter of
    /// half as many particles, no splashes, computed fresh each call (never mutates `particles`,
    /// since there's no simulation running) from a FIXED seed independent of the live `rng` —
    /// same visual every time reduce-motion is on.
    static func staticScatter(config: WeatherParticleConfig, size: CGSize) -> [WeatherParticle] {
        var localRNG = SplitMix64(seed: 0x5CA77E12)
        let count = max(config.count / 2, 0)
        return (0..<count).map { _ in
            var particle = WeatherParticle(
                x: Double.random(in: 0..<max(size.width, 1), using: &localRNG),
                y: Double.random(in: 0..<max(size.height, 1), using: &localRNG),
                willSplash: false,
                splash: nil
            )
            rollTraits(&particle, config: config, rng: &localRNG)
            particle.willSplash = false
            return particle
        }
    }

    /// Cells of a splash sprite at `elapsed` ticks into it, as (column, row) offsets in pixel-grid
    /// units from the impact point; rows count upward. Rain throws a little crown that widens and
    /// thins out; snow puffs up and settles.
    static func splashCells(kind: WeatherParticleConfig.Kind, elapsed: Int) -> [(column: Int, row: Int)] {
        switch kind {
        case .rain:
            switch elapsed {
            case ..<2: return [(-1, 0), (1, 0)]
            case 2..<4: return [(-1, 0), (1, 0), (-2, 1), (2, 1)]
            default: return [(-3, 0), (3, 0), (-2, 2), (2, 2)]
            }
        case .snow:
            switch elapsed {
            case ..<3: return [(-1, 0), (0, 0), (1, 0)]
            case 3..<6: return [(-1, 0), (1, 0), (-2, 1), (0, 1), (2, 1)]
            default: return [(-3, 0), (3, 0), (0, 2)]
            }
        }
    }
}

/// The full-page falling rain/snow layer. Draws via a single `Canvas` (not a `ForEach` of
/// `Rectangle` views — at up to 120 particles redrawing 20x/second, a `ForEach` would mean SwiftUI
/// diffing view identity every tick; a `Canvas` is one view doing immediate-mode drawing, which is
/// far cheaper). Every particle is snapped to a `WeatherParticleConfig.pixel` grid, so it moves in
/// whole game pixels. Non-interactive and hidden from accessibility — it's pure decoration
/// layered over real content.
struct WeatherParticleLayer: View {
    let theme: PixelWeatherTheme
    let intensity: PrecipitationIntensity
    let isNight: Bool
    var animate: Bool = true
    let engine: WeatherParticleEngine
    let colliderStore: PanelColliderStore

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool {
        animate && !reduceMotion && scenePhase == .active
    }

    var body: some View {
        Group {
            if let config = WeatherParticleConfig.make(theme: theme, intensity: intensity, isNight: isNight) {
                // Its own 20 fps timeline rather than the shared 4 fps `PixelClock`: rain at 4 fps
                // reads as streaks teleporting down the screen, not falling.
                TimelineView(.animation(minimumInterval: 1 / WeatherParticleConfig.ticksPerSecond, paused: !shouldAnimate)) { timeline in
                    let time = timeline.date.timeIntervalSinceReferenceDate
                    Canvas { context, size in
                        drawParticles(config: config, time: time, context: context, size: size)
                    }
                }
                .onGeometryChange(for: CGFloat.self) {
                    $0.frame(in: .named("weatherPage")).minY
                } action: { newValue in
                    colliderStore.canvasOriginY = newValue
                }
            } else {
                Color.clear
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawParticles(config: WeatherParticleConfig, time: TimeInterval, context: GraphicsContext, size: CGSize) {
        let colliders = colliderStore.collidersInCanvasSpace()
        let particlesToDraw: [WeatherParticle]
        if shouldAnimate {
            let step = Int((time * WeatherParticleConfig.ticksPerSecond).rounded(.down))
            engine.advance(
                to: step,
                size: size,
                colliders: colliders,
                contentOriginY: colliderStore.contentOriginY,
                config: config
            )
            particlesToDraw = engine.particles
        } else if engine.isSimulating(config: config, size: size) {
            particlesToDraw = engine.particles
        } else {
            particlesToDraw = WeatherParticleEngine.staticScatter(config: config, size: size)
        }

        // Batched into a few paths so the whole layer is a handful of fills per frame.
        var far = Path()
        var near = Path()
        var dimmed = Path()
        var glints = Path()
        var splashes = Path()

        for particle in particlesToDraw {
            if let splash = particle.splash {
                addSplash(splash, config: config, to: &splashes)
                continue
            }

            let overlapsCollider = particle.depth == 1 && colliders.contains { rect in
                let x = particle.displayX(config: config)
                return x >= rect.minX && x <= rect.maxX && particle.y + config.length >= rect.minY && particle.y <= rect.maxY
            }

            switch config.kind {
            case .rain:
                let cells = rainDropCells(particle, config: config)
                if particle.depth == 0 {
                    cells.forEach { far.addRect($0) }
                } else if overlapsCollider {
                    cells.forEach { dimmed.addRect($0) }
                } else {
                    // The head (bottom) cell gets a white glint on the front layer.
                    glints.addRect(cells[0])
                    cells.dropFirst().forEach { near.addRect($0) }
                }
            case .snow:
                if particle.depth == 0 {
                    addFlake(particle, config: config, to: &far)
                } else if overlapsCollider {
                    addFlake(particle, config: config, to: &dimmed)
                } else {
                    addFlake(particle, config: config, to: &near)
                }
            }
        }

        let color = config.color(theme: theme)
        context.fill(far, with: .color(color.opacity(config.baseOpacity * 0.45)))
        context.fill(dimmed, with: .color(color.opacity(config.baseOpacity * 0.35)))
        context.fill(near, with: .color(color.opacity(config.baseOpacity)))
        context.fill(glints, with: .color(.white.opacity(config.baseOpacity)))
        context.fill(splashes, with: .color(color.opacity(config.baseOpacity)))

        if theme == .stormy, shouldAnimate, let strike = LightningSchedule.strike(at: time) {
            let strength = LightningSchedule.flashStrength(elapsed: strike.elapsed)
            if strength > 0 {
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.white.opacity(0.18 * strength)))
            }
        }
    }

    /// A slanted, stair-stepped streak of whole pixels: the head (bottom) cell first, then each
    /// cell above it stepping back against the wind. Never empty.
    private func rainDropCells(_ particle: WeatherParticle, config: WeatherParticleConfig) -> [CGRect] {
        let px = WeatherParticleConfig.pixel
        let factor = particle.depth == 0 ? WeatherParticleConfig.farSpeedFactor : 1
        let count = max(Int((config.length * factor / px).rounded()), 1)
        let slope = config.speed > 0 ? config.drift / config.speed : 0
        let headX = pixelSnapped(particle.x)
        let headY = pixelSnapped(particle.y + config.length * factor - px)

        return (0..<count).map { index in
            let rise = Double(index) * px
            return CGRect(x: pixelSnapped(headX - slope * rise), y: headY - rise, width: px, height: px)
        }
    }

    /// A chunky pixel flake: one cell on the back layer, and a 2x2 block, plus, or cross up front.
    private func addFlake(_ particle: WeatherParticle, config: WeatherParticleConfig, to path: inout Path) {
        let px = WeatherParticleConfig.pixel
        let centerX = pixelSnapped(particle.displayX(config: config))
        let centerY = pixelSnapped(particle.y)
        let offsets: [(Int, Int)]
        if particle.depth == 0 {
            offsets = [(0, 0)]
        } else {
            switch particle.variant {
            case 1: offsets = [(0, 0), (-1, 0), (1, 0), (0, -1), (0, 1)]
            case 2: offsets = [(0, 0), (-1, -1), (1, -1), (-1, 1), (1, 1)]
            default: offsets = [(0, 0), (1, 0), (0, 1), (1, 1)]
            }
        }
        for (column, row) in offsets {
            path.addRect(CGRect(x: centerX + Double(column) * px, y: centerY + Double(row) * px, width: px, height: px))
        }
    }

    private func addSplash(_ splash: WeatherParticle.Splash, config: WeatherParticleConfig, to path: inout Path) {
        let px = WeatherParticleConfig.pixel
        let elapsed = WeatherParticleConfig.splashTicks(for: config.kind) - splash.ticksRemaining
        let originX = pixelSnapped(splash.x)
        for cell in WeatherParticleEngine.splashCells(kind: config.kind, elapsed: elapsed) {
            path.addRect(CGRect(
                x: originX + Double(cell.column) * px,
                y: splash.y - Double(cell.row + 1) * px,
                width: px,
                height: px
            ))
        }
    }
}
