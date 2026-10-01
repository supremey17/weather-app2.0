import Testing
@testable import WeatherApp

/// Thread-safe counter for fetch invocations (iOS 17 has no `Mutex`, so a lock-backed class stands in).
final class FetchCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var _count = 0
    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return _count
    }
    func increment() {
        lock.lock(); defer { lock.unlock() }
        _count += 1
    }
}

/// A mutable "now" the tests can move forward without waiting on a real clock.
final class TestClock: @unchecked Sendable {
    private let lock = NSLock()
    private var _now: Date
    init(_ date: Date = Date(timeIntervalSince1970: 0)) { _now = date }
    var now: Date {
        lock.lock(); defer { lock.unlock() }
        return _now
    }
    func advance(by seconds: TimeInterval) {
        lock.lock(); defer { lock.unlock() }
        _now = _now.addingTimeInterval(seconds)
    }
}

struct RequestGateTests {

    @Test func cacheHitWithinTTLReturnsCachedDataAndFetchesOnce() async throws {
        let clock = TestClock()
        let counter = FetchCounter()
        let gate = RequestGate(ttl: 600, maxRequests: 20, window: 60, now: { clock.now })
        let fetch: @Sendable () async throws -> Data = {
            counter.increment()
            return Data("ok".utf8)
        }

        _ = try await gate.data(for: "a", fetch: fetch)
        _ = try await gate.data(for: "a", fetch: fetch)

        #expect(counter.count == 1)
    }

    @Test func refetchesAfterTTLExpires() async throws {
        let clock = TestClock()
        let counter = FetchCounter()
        let gate = RequestGate(ttl: 600, maxRequests: 20, window: 60, now: { clock.now })
        let fetch: @Sendable () async throws -> Data = {
            counter.increment()
            return Data("ok".utf8)
        }

        _ = try await gate.data(for: "a", fetch: fetch)
        clock.advance(by: 601)
        _ = try await gate.data(for: "a", fetch: fetch)

        #expect(counter.count == 2)
    }

    @Test func concurrentIdenticalRequestsJoinIntoOneFetch() async throws {
        let clock = TestClock()
        let counter = FetchCounter()
        let gate = RequestGate(ttl: 600, maxRequests: 20, window: 60, now: { clock.now })
        let fetch: @Sendable () async throws -> Data = {
            counter.increment()
            try await Task.sleep(for: .milliseconds(50))
            return Data("ok".utf8)
        }

        async let first = gate.data(for: "b", fetch: fetch)
        async let second = gate.data(for: "b", fetch: fetch)
        _ = try await (first, second)

        #expect(counter.count == 1)
    }

    @Test func exceedingMaxRequestsThrowsRateLimited() async throws {
        let clock = TestClock()
        let counter = FetchCounter()
        let gate = RequestGate(ttl: 600, maxRequests: 3, window: 60, now: { clock.now })
        let fetch: @Sendable () async throws -> Data = {
            counter.increment()
            return Data("ok".utf8)
        }

        _ = try await gate.data(for: "a", fetch: fetch)
        _ = try await gate.data(for: "b", fetch: fetch)
        _ = try await gate.data(for: "c", fetch: fetch)

        await #expect(throws: WeatherError.self) {
            _ = try await gate.data(for: "d", fetch: fetch)
        }
    }

    @Test func cacheHitsDontCountTowardTheLimit() async throws {
        let clock = TestClock()
        let counter = FetchCounter()
        let gate = RequestGate(ttl: 600, maxRequests: 1, window: 60, now: { clock.now })
        let fetch: @Sendable () async throws -> Data = {
            counter.increment()
            return Data("ok".utf8)
        }

        _ = try await gate.data(for: "a", fetch: fetch)
        // The limit (1) is already used, but a cache hit for the same key must still succeed.
        let cached = try await gate.data(for: "a", fetch: fetch)

        #expect(cached == Data("ok".utf8))
        #expect(counter.count == 1)
    }

    @Test func windowSlidesSoRequestsAreAllowedAgainLater() async throws {
        let clock = TestClock()
        let counter = FetchCounter()
        let gate = RequestGate(ttl: 600, maxRequests: 1, window: 60, now: { clock.now })
        let fetch: @Sendable () async throws -> Data = {
            counter.increment()
            return Data("ok".utf8)
        }

        _ = try await gate.data(for: "a", fetch: fetch)
        clock.advance(by: 61)
        _ = try await gate.data(for: "b", fetch: fetch)

        #expect(counter.count == 2)
    }

    @Test func errorsAreNotCached() async throws {
        let clock = TestClock()
        let counter = FetchCounter()
        let gate = RequestGate(ttl: 600, maxRequests: 20, window: 60, now: { clock.now })

        await #expect(throws: WeatherError.self) {
            _ = try await gate.data(for: "a") {
                counter.increment()
                throw WeatherError.badStatus(500)
            }
        }
        _ = try await gate.data(for: "a") {
            counter.increment()
            return Data("ok".utf8)
        }

        #expect(counter.count == 2)
    }
}
