import Foundation

/// Sits in front of every OpenWeatherMap call so one phone can't burn through the shared key's quota.
/// - Caches successful responses for `ttl` (OWM only refreshes current conditions about every 10 minutes).
/// - Joins identical requests that are already in flight instead of sending a second one.
/// - Caps real network calls at `maxRequests` per `window`. Cache hits don't count.
///
/// This only limits a single device. Every install shares the same key, so protecting the
/// key across all users would need a server-side proxy.
actor RequestGate {
    static let shared = RequestGate()

    private let ttl: TimeInterval
    private let maxRequests: Int
    private let window: TimeInterval
    private let now: @Sendable () -> Date

    private var cache: [String: (date: Date, data: Data)] = [:]
    private var inFlight: [String: Task<Data, Error>] = [:]
    private var recentRequests: [Date] = []

    init(
        ttl: TimeInterval = 600,
        maxRequests: Int = 20,
        window: TimeInterval = 60,
        now: @escaping @Sendable () -> Date = { Date() }
    ) {
        self.ttl = ttl
        self.maxRequests = maxRequests
        self.window = window
        self.now = now
    }

    /// Returns cached data for `key` if it's still fresh, otherwise runs `fetch` (at most once at a time per key).
    /// Only successful fetches are cached; errors are passed through and never stored.
    func data(for key: String, fetch: @escaping @Sendable () async throws -> Data) async throws -> Data {
        let current = now()
        if let entry = cache[key], current.timeIntervalSince(entry.date) < ttl {
            return entry.data
        }
        if let task = inFlight[key] {
            return try await task.value
        }

        // Sliding window: forget requests older than `window`, then check what's left.
        recentRequests.removeAll { current.timeIntervalSince($0) >= window }
        guard recentRequests.count < maxRequests else {
            throw WeatherError.rateLimited
        }
        recentRequests.append(current)

        let task = Task { try await fetch() }
        inFlight[key] = task
        defer { inFlight[key] = nil }

        let data = try await task.value
        let finished = now()
        cache = cache.filter { finished.timeIntervalSince($0.value.date) < ttl }
        cache[key] = (finished, data)
        return data
    }
}
