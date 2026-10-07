import CoreGraphics
import Foundation
import Testing
@testable import WeatherApp

/// Direct, deterministic coverage of the rain/snow particle simulation — everything here exercises
/// `WeatherParticleEngine.tick`/`advance` and `WeatherParticleConfig.make` directly, with no SwiftUI
/// view hosting, so it's fast and reproducible.
struct WeatherParticleEngineTests {

    // MARK: - Helpers

    private func makeConfig(
        kind: WeatherParticleConfig.Kind = .rain,
        count: Int = 1,
        speed: Double = 10,
        length: Double = 5,
        width: Double = 2,
        baseOpacity: Double = 0.7,
        splashChance: Double = 1.0
    ) -> WeatherParticleConfig {
        WeatherParticleConfig(
            kind: kind, count: count, speed: speed, length: length, width: width,
            baseOpacity: baseOpacity, splashChance: splashChance
        )
    }

    // MARK: - 1. Splashing on collision

    @Test func particleCrossingColliderTopEdgeWithinXRangeSplashesAtTheColliderTop() {
        var particle = WeatherParticle(x: 50, y: 90, willSplash: true, splash: nil)
        let collider = CGRect(x: 0, y: 100, width: 100, height: 20)
        var rng = SplitMix64(seed: 1)
        let config = makeConfig(speed: 10, length: 5)

        WeatherParticleEngine.tick(
            &particle, colliders: [collider], config: config,
            width: 200, height: 400, collisionsEnabled: true, rng: &rng
        )

        #expect(particle.splash != nil)
        #expect(particle.splash?.y == Double(collider.minY))
    }

    // MARK: - 2. Non-splashing particle passes through

    @Test func particleWithoutWillSplashPassesThroughTheSameColliderUnaffected() {
        var particle = WeatherParticle(x: 50, y: 90, willSplash: false, splash: nil)
        let collider = CGRect(x: 0, y: 100, width: 100, height: 20)
        var rng = SplitMix64(seed: 1)
        let config = makeConfig(speed: 10, length: 5)

        WeatherParticleEngine.tick(
            &particle, colliders: [collider], config: config,
            width: 200, height: 400, collisionsEnabled: true, rng: &rng
        )

        #expect(particle.splash == nil)
        #expect(particle.y == 100)
    }

    // MARK: - 3. Splash-eligible particle outside the collider's x-range passes through

    @Test func particleOutsideEveryColliderXRangePassesThroughWithoutSplashing() {
        var particle = WeatherParticle(x: 500, y: 90, willSplash: true, splash: nil)
        let collider = CGRect(x: 0, y: 100, width: 100, height: 20)
        var rng = SplitMix64(seed: 1)
        let config = makeConfig(speed: 10, length: 5)

        WeatherParticleEngine.tick(
            &particle, colliders: [collider], config: config,
            width: 1000, height: 400, collisionsEnabled: true, rng: &rng
        )

        #expect(particle.splash == nil)
    }

    // MARK: - 4. Splash expiry respawns above the top

    @Test func splashExpiryClearsSplashAndRespawnsAboveTheTop() {
        var particle = WeatherParticle(
            x: 50, y: 100, willSplash: true,
            splash: WeatherParticle.Splash(x: 50, y: 100, ticksRemaining: 1)
        )
        var rng = SplitMix64(seed: 42)
        let config = makeConfig()

        WeatherParticleEngine.tick(
            &particle, colliders: [], config: config,
            width: 200, height: 400, collisionsEnabled: true, rng: &rng
        )

        #expect(particle.splash == nil)
        #expect(particle.y <= 0)
    }

    // MARK: - 5. Big step jumps reseed instead of catching up

    @Test func advanceReseedsInsteadOfCatchingUpAcrossABigStepJump() {
        let size = CGSize(width: 100, height: 100)
        // speed 0 so sequential ticking never moves a particle after its initial reseed — any
        // difference in final state must come from a second reseed, not accumulated motion.
        let config = makeConfig(count: 5, speed: 0, length: 1, splashChance: 0)

        let sequential = WeatherParticleEngine(seed: 123)
        for step in 0...5 {
            sequential.advance(to: step, size: size, colliders: [], contentOriginY: 0, config: config)
        }

        let jumped = WeatherParticleEngine(seed: 123)
        jumped.advance(to: 0, size: size, colliders: [], contentOriginY: 0, config: config)
        jumped.advance(to: 5, size: size, colliders: [], contentOriginY: 0, config: config)

        #expect(jumped.particles.count == config.count)
        #expect(jumped.particles != sequential.particles)
    }

    // MARK: - 6. Same-step calls are idempotent

    @Test func advanceWithTheSameStepTwiceIsANoOp() {
        let size = CGSize(width: 100, height: 100)
        let config = makeConfig(count: 4)
        let engine = WeatherParticleEngine(seed: 7)

        engine.advance(to: 5, size: size, colliders: [], contentOriginY: 0, config: config)
        let afterFirstCall = engine.particles

        engine.advance(to: 5, size: size, colliders: [], contentOriginY: 0, config: config)

        #expect(engine.particles == afterFirstCall)
    }

    // MARK: - 7. Scrolling suspends collisions for that tick

    @Test func contentScrollingSuspendsCollisionsForThatTick() {
        let size = CGSize(width: 200, height: 1000)
        let config = makeConfig(count: 1, speed: 50, length: 5, splashChance: 1.0)

        let notScrolling = WeatherParticleEngine(seed: 0xBEEF)
        notScrolling.advance(to: 0, size: size, colliders: [], contentOriginY: 0, config: config)
        let baselineY = notScrolling.particles.first?.y ?? 0
        // minY strictly between (baselineY + length) and (baselineY + length + speed), so the
        // particle's bottom edge crosses it on the very next tick.
        let collider = CGRect(x: 0, y: baselineY + 30, width: size.width, height: 20)

        notScrolling.advance(to: 1, size: size, colliders: [collider], contentOriginY: 0, config: config)
        #expect(notScrolling.particles.first?.splash != nil)
        #expect(notScrolling.particles.first?.splash?.y == Double(collider.minY))

        let scrolling = WeatherParticleEngine(seed: 0xBEEF)
        scrolling.advance(to: 0, size: size, colliders: [], contentOriginY: 0, config: config)
        // Same seed and same first call reproduce the same baselineY/collider placement.
        scrolling.advance(to: 1, size: size, colliders: [collider], contentOriginY: 50, config: config)
        #expect(scrolling.particles.first?.splash == nil)
    }

    // MARK: - 8. Heavy > normal > light for count and speed

    @Test func rainAndSnowConfigsOrderCountAndSpeedStrictlyByIntensity() throws {
        for theme in [PixelWeatherTheme.rainy, .snowy] {
            let light = try #require(WeatherParticleConfig.make(theme: theme, intensity: .light, isNight: false))
            let normal = try #require(WeatherParticleConfig.make(theme: theme, intensity: .normal, isNight: false))
            let heavy = try #require(WeatherParticleConfig.make(theme: theme, intensity: .heavy, isNight: false))

            #expect(heavy.count > normal.count, "\(theme) heavy.count should exceed normal.count")
            #expect(normal.count > light.count, "\(theme) normal.count should exceed light.count")
            #expect(heavy.speed > normal.speed, "\(theme) heavy.speed should exceed normal.speed")
            #expect(normal.speed > light.speed, "\(theme) normal.speed should exceed light.speed")
        }
    }

    // MARK: - 9. No particles for non-precipitation themes

    @Test func makeReturnsNilForEveryNonPrecipitationTheme() {
        let nonPrecipitatingThemes: [PixelWeatherTheme] = [.clearDay, .clearNight, .cloudy, .misty, .neutral]
        for theme in nonPrecipitatingThemes {
            for intensity in PrecipitationIntensity.allCases {
                #expect(
                    WeatherParticleConfig.make(theme: theme, intensity: intensity, isNight: false) == nil,
                    "\(theme)/\(intensity) should have no particle config"
                )
            }
        }
    }

    // MARK: - 10. Storms are never gentler than rain a level up

    @Test func stormyConfigIsAtOrAboveRainAtTheNextIntensityLevelUp() throws {
        let stormyLight = try #require(WeatherParticleConfig.make(theme: .stormy, intensity: .light, isNight: false))
        let rainyNormal = try #require(WeatherParticleConfig.make(theme: .rainy, intensity: .normal, isNight: false))
        #expect(stormyLight.count >= rainyNormal.count)

        let stormyNormal = try #require(WeatherParticleConfig.make(theme: .stormy, intensity: .normal, isNight: false))
        let rainyHeavy = try #require(WeatherParticleConfig.make(theme: .rainy, intensity: .heavy, isNight: false))
        #expect(stormyNormal.count >= rainyHeavy.count)
    }

    // MARK: - 11. Night dims particle opacity

    @Test func nightReducesBaseOpacityForTheSameThemeAndIntensity() throws {
        for theme in [PixelWeatherTheme.rainy, .snowy, .stormy] {
            let day = try #require(WeatherParticleConfig.make(theme: theme, intensity: .normal, isNight: false))
            let night = try #require(WeatherParticleConfig.make(theme: theme, intensity: .normal, isNight: true))
            #expect(night.baseOpacity < day.baseOpacity, "\(theme) night opacity should be dimmer than day")
        }
    }
}
