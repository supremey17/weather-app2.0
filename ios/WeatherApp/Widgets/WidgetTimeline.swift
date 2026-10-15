import SwiftUI
import WidgetKit

struct SnapshotEntry: TimelineEntry {
    let date: Date
    /// `nil` until the app has finished its first load.
    let snapshot: WidgetSnapshot?
}

/// Shared by every widget: reads the snapshot the app last wrote. No network, no API key.
struct SnapshotProvider: TimelineProvider {
    var store = WidgetSnapshotStore()

    func placeholder(in context: Context) -> SnapshotEntry {
        SnapshotEntry(date: .now, snapshot: .sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (SnapshotEntry) -> Void) {
        completion(SnapshotEntry(date: .now, snapshot: context.isPreview ? store.load() ?? .sample : store.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SnapshotEntry>) -> Void) {
        let now = Date.now
        let snapshot = store.load()
        let dates = Self.entryDates(for: snapshot, now: now)
        let entries = dates.map { SnapshotEntry(date: $0, snapshot: snapshot) }
        // Hour-boundary entries let the forecast advance on its own; once they run out (or there
        // were none), check back in an hour. Fresh data arrives via the app's reloadAllTimelines.
        let policy: TimelineReloadPolicy = dates.count > 1 ? .atEnd : .after(now.addingTimeInterval(3600))
        completion(Timeline(entries: entries, policy: policy))
    }

    /// `now`, each upcoming forecast hour, and the moment the data turns stale, sorted and
    /// bounded by `WidgetSnapshot.maxHours + 2` entries.
    static func entryDates(for snapshot: WidgetSnapshot?, now: Date) -> [Date] {
        guard let snapshot else { return [now] }
        var dates = snapshot.hourly
            .map { Date(timeIntervalSince1970: TimeInterval($0.epoch)) }
            .filter { $0 > now }
        let staleAt = snapshot.updatedAt.addingTimeInterval(WidgetSnapshot.staleAfter)
        if staleAt > now { dates.append(staleAt) }
        return [now] + Array(Set(dates)).sorted().prefix(WidgetSnapshot.maxHours + 1)
    }
}

// MARK: - Shared widget chrome

extension View {
    /// The theme's sky as the widget's container background (required on iOS 17+).
    func pixelWidgetBackground(_ theme: PixelWeatherTheme) -> some View {
        containerBackground(for: .widget) {
            LinearGradient(colors: [theme.palette.skyTop, theme.palette.skyBottom], startPoint: .top, endPoint: .bottom)
        }
    }
}

/// Shown before the app has loaded any weather: a title-screen prompt.
struct PressStartView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("PRESS START")
                .pixelFont(.title)
            Text("Open the app to load a stage")
                .pixelFont(.caption)
                .multilineTextAlignment(.center)
        }
        .foregroundStyle(.white)
        .accessibilityElement(children: .combine)
    }
}
