import Foundation
import Testing
@testable import WeatherApp

struct WidgetSnapshotTests {
    private func makeStore() -> (WidgetSnapshotStore, UserDefaults) {
        let suite = "WidgetSnapshotTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return (WidgetSnapshotStore(defaults: defaults), defaults)
    }

    @Test func roundTripsThroughTheStore() {
        let (store, _) = makeStore()
        #expect(store.load() == nil)
        store.save(.sample)
        #expect(store.load() == WidgetSnapshot.sample.sanitized())
    }

    @Test func corruptDataLoadsAsNil() {
        let (store, defaults) = makeStore()
        defaults.set(Data("not json".utf8), forKey: "widget_snapshot_v1")
        #expect(store.load() == nil)
    }

    @Test func sanitizeBoundsStringsNumbersAndEnums() {
        var snapshot = WidgetSnapshot.sample
        snapshot.city = String(repeating: "x", count: 500)
        snapshot.temp = .infinity
        snapshot.high = 9_999
        snapshot.theme = "hacked"
        snapshot.units = "kelvin"
        snapshot.advice = Array(repeating: String(repeating: "a", count: 500), count: 10)
        snapshot.hourly = Array(repeating: WidgetSnapshot.sample.hourly[0], count: 50)
        snapshot.hourly[0].chanceOfRain = 400
        snapshot.hourly[1].chanceOfRain = -3

        let clean = snapshot.sanitized()
        #expect(clean.city.count == WidgetSnapshot.maxCityLength)
        #expect(clean.temp == 0)
        #expect(clean.high == 200)
        #expect(clean.weatherTheme == .neutral)
        #expect(clean.unitsValue == .imperial)
        #expect(clean.advice.count == WidgetSnapshot.maxAdviceCount)
        #expect(clean.advice.allSatisfy { $0.count == WidgetSnapshot.maxAdviceLength })
        #expect(clean.hourly.count == WidgetSnapshot.maxHours)
        #expect(clean.hourly[0].chanceOfRain == 100)
        #expect(clean.hourly[1].chanceOfRain == 0)
    }

    @Test func saveOnlyAsksForReloadWhenTheWeatherChanges() {
        let (store, _) = makeStore()
        #expect(store.save(.sample))

        var refreshed = WidgetSnapshot.sample
        refreshed.updatedAt += 600
        #expect(!store.save(refreshed), "same weather, newer timestamp: no reload")
        #expect(store.load()?.updatedAt == refreshed.updatedAt, "but the timestamp is still stored")

        var changed = refreshed
        changed.temp += 1
        #expect(store.save(changed))
    }

    @Test func saveReloadsWhenTheStoredCopyHadGoneStale() {
        let (store, _) = makeStore()
        store.save(.sample)
        var later = WidgetSnapshot.sample
        later.updatedAt += WidgetSnapshot.staleAfter + 1
        #expect(store.save(later))
    }

    @Test func staleAfterThreeHours() {
        let snapshot = WidgetSnapshot.sample
        #expect(!snapshot.isStale(at: snapshot.updatedAt + WidgetSnapshot.staleAfter))
        #expect(snapshot.isStale(at: snapshot.updatedAt + WidgetSnapshot.staleAfter + 1))
    }

    @Test func timelineHasAnEntryForNowEachFutureHourAndStaleness() {
        let snapshot = WidgetSnapshot.sample
        let now = Date(timeIntervalSince1970: TimeInterval(snapshot.hourly[1].epoch))
        let dates = SnapshotProvider.entryDates(for: snapshot, now: now)

        #expect(dates.first == now)
        #expect(dates == dates.sorted())
        // Hours 2...5 are after `now`; plus the stale moment (updatedAt + 3h == hour 3, deduped).
        #expect(dates.count == 1 + 4)
        #expect(dates.count <= WidgetSnapshot.maxHours + 2)
    }

    @Test func timelineWithoutSnapshotIsJustNow() {
        let now = Date()
        #expect(SnapshotProvider.entryDates(for: nil, now: now) == [now])
    }
}
