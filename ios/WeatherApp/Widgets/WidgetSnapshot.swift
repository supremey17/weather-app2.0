import Foundation

/// The small, already-formatted slice of the last successful load that the home/lock screen
/// widgets draw. The app writes it to the shared App Group after each load; the widget extension
/// only reads it and never touches the network, so the OWM key never ships in the extension.
///
/// Deliberately holds no coordinates: the widget doesn't need them, so they stay out of the
/// shared container.
struct WidgetSnapshot: Codable, Equatable {
    struct Hour: Codable, Equatable {
        /// Start of the hour, epoch seconds.
        var epoch: Int
        /// Display time in the city's zone, e.g. "3 PM".
        var time: String
        /// SF Symbol name, mapped to art via `PixelSpriteKind(sfSymbol:)`.
        var symbol: String
        /// Display temperature, e.g. "72°F".
        var temp: String
        var chanceOfRain: Int
    }

    var city: String
    var temp: Double
    var low: Double?
    var high: Double?
    /// `Units.rawValue`.
    var units: String
    /// e.g. "light rain".
    var condition: String
    /// `PixelWeatherTheme.rawValue`.
    var theme: String
    var isNight: Bool
    var advice: [String]
    var hourly: [Hour]
    var updatedAt: Date

    static let maxCityLength = 40
    static let maxAdviceCount = 4
    static let maxAdviceLength = 80
    static let maxHours = 12
    static let maxShortTextLength = 12
    /// Older than this, widgets flag the data as stale.
    static let staleAfter: TimeInterval = 3 * 3600

    var weatherTheme: PixelWeatherTheme { PixelWeatherTheme(rawValue: theme) ?? .neutral }
    var unitsValue: Units { Units(rawValue: units) ?? .imperial }

    func isStale(at date: Date) -> Bool {
        date.timeIntervalSince(updatedAt) > Self.staleAfter
    }

    /// Stored data is untrusted (same rule as `Preferences`): bound every string and number so a
    /// corrupt or hand-edited value can't blow up a widget's layout or memory.
    func sanitized() -> WidgetSnapshot {
        var copy = self
        copy.city = String(city.prefix(Self.maxCityLength))
        copy.condition = String(condition.prefix(Self.maxCityLength))
        copy.temp = Self.clampTemp(temp) ?? 0
        copy.low = low.flatMap(Self.clampTemp)
        copy.high = high.flatMap(Self.clampTemp)
        copy.units = unitsValue.rawValue
        copy.theme = weatherTheme.rawValue
        copy.advice = advice.prefix(Self.maxAdviceCount).map { String($0.prefix(Self.maxAdviceLength)) }
        copy.hourly = hourly.prefix(Self.maxHours).map { hour in
            var hour = hour
            hour.time = String(hour.time.prefix(Self.maxShortTextLength))
            hour.temp = String(hour.temp.prefix(Self.maxShortTextLength))
            hour.symbol = String(hour.symbol.prefix(40))
            hour.chanceOfRain = min(max(hour.chanceOfRain, 0), 100)
            return hour
        }
        return copy
    }

    private static func clampTemp(_ value: Double) -> Double? {
        value.isFinite ? min(max(value, -200), 200) : nil
    }

    /// Shown in the widget gallery and as the placeholder while a real entry loads.
    static let sample = WidgetSnapshot(
        city: "Pixel Town",
        temp: 72,
        low: 61,
        high: 78,
        units: Units.imperial.rawValue,
        condition: "scattered clouds",
        theme: PixelWeatherTheme.cloudy.rawValue,
        isNight: false,
        advice: ["Grab a light jacket it's chilly", "shower imminent: bring raincoat"],
        hourly: (0..<6).map { offset in
            Hour(
                epoch: 1_800_000_000 + offset * 3600,
                time: "\((offset + 2) % 12 + 1) PM",
                symbol: offset < 3 ? "cloud.sun.fill" : "cloud.rain.fill",
                temp: "\(72 - offset)°F",
                chanceOfRain: offset * 18
            )
        },
        updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
    )
}

/// Reads and writes the snapshot in the App Group's `UserDefaults`.
struct WidgetSnapshotStore {
    static let appGroup = "group.WeatherApp1.0.shared"
    private static let key = "widget_snapshot_v1"

    private let defaults: UserDefaults?

    init(defaults: UserDefaults? = UserDefaults(suiteName: WidgetSnapshotStore.appGroup)) {
        self.defaults = defaults
    }

    func load() -> WidgetSnapshot? {
        guard let data = defaults?.data(forKey: Self.key) else { return nil }
        return (try? JSONDecoder().decode(WidgetSnapshot.self, from: data))?.sanitized()
    }

    /// Writes `snapshot` and returns whether widgets need a timeline reload: only when the
    /// weather shown changed, or the stored copy had gone stale. iOS budgets reloads, so a plain
    /// refresh with identical weather just bumps `updatedAt` silently.
    @discardableResult
    func save(_ snapshot: WidgetSnapshot) -> Bool {
        let snapshot = snapshot.sanitized()
        guard let defaults, let data = try? JSONEncoder().encode(snapshot) else { return false }
        let previous = load()
        defaults.set(data, forKey: Self.key)
        guard var previous else { return true }
        let wasStale = previous.isStale(at: snapshot.updatedAt)
        previous.updatedAt = snapshot.updatedAt
        return previous != snapshot || wasStale
    }
}
