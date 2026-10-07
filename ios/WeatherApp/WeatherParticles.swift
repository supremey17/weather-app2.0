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
    /// `neon` field for rain/storm (a panel-family color that — per `PixelPalette.nightAdjusted()`
    /// — does NOT change at night, which is intentional: the drops' own color stays consistent,
    /// only their opacity dims).
    func color(theme: PixelWeatherTheme) -> Color {
        kind == .snow ? .white : theme.palette.neon
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
                kind: .rain, count: 24, speed: 60, length: 12, width: 2,
                baseOpacity: 0.55 * opacityScale, splashChance: 0.3
            )
        case .normal:
            return WeatherParticleConfig(
                kind: .rain, count: 48, speed: 90, length: 16, width: 2,
                baseOpacity: 0.70 * opacityScale, splashChance: 0.5
            )
        case .heavy:
            return WeatherParticleConfig(
                kind: .rain, count: 90, speed: 130, length: 22, width: 2,
                baseOpacity: 0.80 * opacityScale, splashChance: 0.8
            )
        }
    }

    private static func snowConfig(intensity: PrecipitationIntensity, opacityScale: Double) -> WeatherParticleConfig {
        switch intensity {
        case .light:
            return WeatherParticleConfig(
                kind: .snow, count: 20, speed: 10, length: 4, width: 4,
                baseOpacity: 0.85 * opacityScale, splashChance: 0.25
            )
        case .normal:
            return WeatherParticleConfig(
                kind: .snow, count: 36, speed: 16, length: 4, width: 4,
                baseOpacity: 0.85 * opacityScale, splashChance: 0.40
            )
        case .heavy:
            return WeatherParticleConfig(
                kind: .snow, count: 60, speed: 24, length: 4, width: 4,
                baseOpacity: 0.85 * opacityScale, splashChance: 0.60
            )
        }
    }
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

extension EnvironmentValues {
    var weatherColliderStore: PanelColliderStore? {
        get { self[WeatherColliderStoreKey.self] }
        set { self[WeatherColliderStoreKey.self] = newValue }
    }
}

extension View {
    /// Tags this view as a surface falling rain/snow can splash against. Reads the ambient
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

    func body(content: Content) -> some View {
        content
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

    struct Splash: Equatable {
        var x: Double
        var y: Double
        var ticksRemaining: Int
    }
}

/// Stateful, per-tick particle simulation — pure enough to unit test directly (see
/// `tick(_:colliders:config:height:collisionsEnabled:rng:)`), with a thin stateful wrapper
/// (`advance`) that the SwiftUI layer drives once per clock tick.
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
                WeatherParticle(
                    x: Double.random(in: 0..<max(width, 1), using: &rng),
                    y: Double.random(in: 0..<max(height, 1), using: &rng),
                    willSplash: Double.random(in: 0..<1, using: &rng) < config.splashChance,
                    splash: nil
                )
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
    ///   - If `particle.splash` is non-nil: decrement `ticksRemaining`; at 0, respawn the particle
    ///     (new random x in `0..<width`, `y = -Double.random(in: 0...(height * 0.25), using: &rng)`,
    ///     re-roll `willSplash`, clear `splash`). `width` is passed in alongside `height` for this
    ///     (add it as a parameter — `height` alone isn't enough to pick a new x).
    ///   - Else: move `particle.y += config.speed`. If `collisionsEnabled && particle.willSplash`,
    ///     scan `colliders` (already sorted by `minY` ascending) for the FIRST rect where
    ///     `rect.minX...rect.maxX` contains `particle.x` AND the particle's bottom edge
    ///     (`particle.y + config.length`) just crossed `rect.minY` this tick (i.e. it was above
    ///     `rect.minY` before this tick's move and is at/below it now). On a match, set
    ///     `particle.splash = Splash(x: particle.x, y: rect.minY, ticksRemaining: config.kind == .snow ? 4 : 2)`
    ///     and do NOT also apply the `y += speed` move that would carry it past the panel (i.e.
    ///     check for the collision using the pre-move `y` and only commit the moved `y` if no
    ///     collision occurred — implement whichever way reads cleanest to you, the requirement is
    ///     just that a splashing particle visually stops right at `rect.minY`, not inside/past it).
    ///   - If (after the above) `particle.y > height`, respawn exactly as the splash-expiry case
    ///     above (new random x/y-above-0/willSplash, no splash).
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

        let previousY = particle.y
        let movedY = previousY + config.speed

        if collisionsEnabled && particle.willSplash {
            let bottomBefore = previousY + config.length
            let bottomAfter = movedY + config.length
            for rect in colliders {
                guard rect.minX <= particle.x, particle.x <= rect.maxX else { continue }
                if bottomBefore < rect.minY && bottomAfter >= rect.minY {
                    particle.splash = WeatherParticle.Splash(
                        x: particle.x,
                        y: rect.minY,
                        ticksRemaining: config.kind == .snow ? 4 : 2
                    )
                    return
                }
            }
        }

        particle.y = movedY

        if particle.y > height {
            respawn(&particle, width: width, height: height, config: config, rng: &rng)
        }
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
        particle.willSplash = Double.random(in: 0..<1, using: &rng) < config.splashChance
        particle.splash = nil
    }

    /// For reduce-motion / backgrounded / clock-not-running: a static, deterministic scatter of
    /// half as many particles, no splashes, computed fresh each call (never mutates `particles`,
    /// since there's no simulation running) from a FIXED seed independent of the live `rng` —
    /// same visual every time reduce-motion is on, which matches today's existing "frozen but
    /// visible" particle behavior.
    static func staticScatter(config: WeatherParticleConfig, size: CGSize) -> [WeatherParticle] {
        var localRNG = SplitMix64(seed: 0x5CA77E12)
        let count = max(config.count / 2, 0)
        return (0..<count).map { _ in
            WeatherParticle(
                x: Double.random(in: 0..<max(size.width, 1), using: &localRNG),
                y: Double.random(in: 0..<max(size.height, 1), using: &localRNG),
                willSplash: false,
                splash: nil
            )
        }
    }
}

/// The full-page falling rain/snow layer. Draws via a single `Canvas` (not a `ForEach` of
/// `Rectangle` views — at up to 90 particles redrawing 4x/second, a `ForEach` would mean SwiftUI
/// diffing view identity every tick; a `Canvas` is one view doing immediate-mode drawing, which is
/// far cheaper). Non-interactive and hidden from accessibility — it's pure decoration layered over
/// real content.
struct WeatherParticleLayer: View {
    let theme: PixelWeatherTheme
    let intensity: PrecipitationIntensity
    let isNight: Bool
    var animate: Bool = true
    let engine: WeatherParticleEngine
    let colliderStore: PanelColliderStore

    @Environment(PixelClock.self) private var clock: PixelClock?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool {
        animate && !reduceMotion && scenePhase == .active
    }

    var body: some View {
        Group {
            if let config = WeatherParticleConfig.make(theme: theme, intensity: intensity, isNight: isNight) {
                GeometryReader { _ in
                    let step = shouldAnimate ? (clock?.step ?? 0) : 0
                    Canvas { context, size in
                        drawParticles(config: config, step: step, context: context, size: size)
                    }
                    .onGeometryChange(for: CGFloat.self) {
                        $0.frame(in: .named("weatherPage")).minY
                    } action: { newValue in
                        colliderStore.canvasOriginY = newValue
                    }
                }
            } else {
                Color.clear
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func drawParticles(config: WeatherParticleConfig, step: Int, context: GraphicsContext, size: CGSize) {
        let colliders = colliderStore.collidersInCanvasSpace()
        let particlesToDraw: [WeatherParticle]
        if shouldAnimate {
            engine.advance(
                to: step,
                size: size,
                colliders: colliders,
                contentOriginY: colliderStore.contentOriginY,
                config: config
            )
            particlesToDraw = engine.particles
        } else {
            particlesToDraw = WeatherParticleEngine.staticScatter(config: config, size: size)
        }

        let color = config.color(theme: theme)

        for particle in particlesToDraw {
            if let splash = particle.splash {
                drawSplash(splash, color: color, config: config, in: context)
            } else {
                drawFalling(particle, color: color, config: config, colliders: colliders, in: context)
            }
        }
    }

    private func drawFalling(
        _ particle: WeatherParticle,
        color: Color,
        config: WeatherParticleConfig,
        colliders: [CGRect],
        in context: GraphicsContext
    ) {
        let topY = particle.y
        let bottomY = particle.y + config.length
        let overlapsCollider = colliders.contains { rect in
            particle.x >= rect.minX && particle.x <= rect.maxX && bottomY >= rect.minY && topY <= rect.maxY
        }
        let opacity = overlapsCollider ? config.baseOpacity * 0.35 : config.baseOpacity

        let rect: CGRect
        if config.kind == .snow {
            rect = CGRect(
                x: particle.x - config.width / 2,
                y: particle.y - config.length / 2,
                width: config.width,
                height: config.length
            )
        } else {
            rect = CGRect(x: particle.x - config.width / 2, y: particle.y, width: config.width, height: config.length)
        }
        context.fill(Path(rect), with: .color(color.opacity(opacity)))
    }

    private func drawSplash(
        _ splash: WeatherParticle.Splash,
        color: Color,
        config: WeatherParticleConfig,
        in context: GraphicsContext
    ) {
        let maxTicks = Double(config.kind == .snow ? 4 : 2)
        let progress = maxTicks > 0 ? Double(splash.ticksRemaining) / maxTicks : 0
        let dabCount = 3
        for index in 0..<dabCount {
            let fraction = Double(index) / Double(dabCount - 1)
            let dx = (fraction - 0.5) * config.length
            let dabSize = max(config.width * 0.8 * progress, 0.5)
            let dabRect = CGRect(
                x: splash.x + dx - dabSize / 2,
                y: splash.y - dabSize / 2,
                width: dabSize,
                height: dabSize
            )
            context.fill(Path(ellipseIn: dabRect), with: .color(color.opacity(config.baseOpacity * max(progress, 0.2))))
        }
    }
}
