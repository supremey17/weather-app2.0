import Testing
@testable import WeatherApp

/// A `CityCompleting` test double that records every query it receives.
@MainActor
final class FakeCompleter: CityCompleting {
    var onResults: (([(title: String, subtitle: String)]) -> Void)?
    var onError: ((Error) -> Void)?
    private(set) var queries: [String] = []
    private(set) var cancelCount = 0

    func query(_ fragment: String) {
        queries.append(fragment)
    }

    func cancel() {
        cancelCount += 1
    }

    func sendResults(_ results: [(title: String, subtitle: String)]) {
        onResults?(results)
    }
}

@MainActor
struct CitySuggesterTests {

    @Test func debounceCollapsesRapidUpdatesIntoOneQuery() async throws {
        let fake = FakeCompleter()
        let suggester = CitySuggester(completer: fake, debounce: .milliseconds(50))

        suggester.update(query: "A", saved: [])
        suggester.update(query: "Au", saved: [])
        suggester.update(query: "Aus", saved: [])

        try await Task.sleep(for: .milliseconds(150))

        #expect(fake.queries == ["Aus"])
    }

    @Test func clearEmptiesResultsAndCancelsCompleter() async throws {
        let fake = FakeCompleter()
        let suggester = CitySuggester(completer: fake, debounce: .milliseconds(10))

        suggester.update(query: "Austin", saved: ["Austin"])
        #expect(!suggester.suggestions.isEmpty)

        suggester.clear()

        #expect(suggester.suggestions.isEmpty)
        #expect(fake.cancelCount == 1)
    }

    @Test func staleResultsAfterClearAreIgnored() async throws {
        let fake = FakeCompleter()
        let suggester = CitySuggester(completer: fake, debounce: .milliseconds(10))

        suggester.update(query: "Austin", saved: [])
        suggester.clear()
        fake.sendResults([(title: "Austin", subtitle: "Texas, United States")])

        #expect(suggester.suggestions.isEmpty)
    }

    @Test func tooShortQueryNeverReachesCompleter() async throws {
        let fake = FakeCompleter()
        let suggester = CitySuggester(completer: fake, debounce: .milliseconds(10))

        suggester.update(query: "A", saved: [])
        try await Task.sleep(for: .milliseconds(50))

        #expect(fake.queries.isEmpty)
        #expect(suggester.suggestions.isEmpty)
    }
}
