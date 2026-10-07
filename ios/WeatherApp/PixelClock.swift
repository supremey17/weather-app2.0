import Foundation
import Observation

/// The single shared "tick" for every stepped pixel-art animation on the main page (the hero
/// scene, full-page weather particles, animated backgrounds) — replacing what used to be several
/// independent `TimelineView`s. `ContentView` owns one instance, runs it only while something is
/// actually animating (see `run()`), and injects it via `.environment(clock)`; leaf views read
/// `clock.step` in their own `body` so only they — not the whole page — re-render on each tick.
@MainActor
@Observable
final class PixelClock {
    /// Whole 250ms ticks since the reference date. Kept as the same formula the old per-view
    /// `TimelineView`s used (`timeIntervalSinceReferenceDate / 0.25`), so parallax/particle motion
    /// doesn't visibly jump when a view switches from its own timeline to this shared one.
    private(set) var step = 0

    static let interval: Duration = .milliseconds(250)

    /// Runs until the surrounding `Task` is cancelled. Callers are expected to run this inside a
    /// `.task(id:)` keyed to "should anything be animating right now" (reduce motion, scene phase,
    /// no sheet open, at least one animated thing on screen) — see `ContentView` — so the clock
    /// simply doesn't run at all when nothing needs it, rather than ticking an idle 60s timer the
    /// way the old `TimelineView`s did.
    func run() async {
        while !Task.isCancelled {
            step = Int(Date.now.timeIntervalSinceReferenceDate / 0.25)
            do {
                try await Task.sleep(for: Self.interval)
            } catch {
                return
            }
        }
    }
}
