import Foundation
import Testing
@testable import WeatherApp

struct CitySuggestionLogicTests {

    // MARK: sanitize

    @Test func sanitizeTrimsWhitespace() {
        #expect(CitySuggestionLogic.sanitize("  Austin  ") == "Austin")
    }

    @Test func sanitizeRejectsTooShort() {
        #expect(CitySuggestionLogic.sanitize("A") == nil)
        #expect(CitySuggestionLogic.sanitize(" ") == nil)
        #expect(CitySuggestionLogic.sanitize("") == nil)
    }

    @Test func sanitizeCapsLength() {
        let huge = String(repeating: "a", count: 500)
        #expect(CitySuggestionLogic.sanitize(huge)?.count == CitySuggestionLogic.maxQueryLength)
    }

    // MARK: savedMatches

    @Test func savedMatchesIsCaseInsensitivePrefix() {
        let saved = ["Austin", "Austria", "Boston"]
        #expect(CitySuggestionLogic.savedMatches(query: "aus", saved: saved) == ["Austin", "Austria"])
        #expect(CitySuggestionLogic.savedMatches(query: "AUS", saved: saved) == ["Austin", "Austria"])
        #expect(CitySuggestionLogic.savedMatches(query: "bos", saved: saved) == ["Boston"])
        #expect(CitySuggestionLogic.savedMatches(query: "zzz", saved: saved).isEmpty)
    }

    // MARK: merge

    @Test func mergePutsSavedCitiesFirstAndDeduplicates() {
        let remote = [
            CitySuggestion(title: "Austin", subtitle: "Texas, United States", query: "Austin,US"),
            CitySuggestion(title: "Boston", subtitle: "Massachusetts, United States", query: "Boston,US"),
        ]
        let merged = CitySuggestionLogic.merge(saved: ["Austin"], remote: remote)
        #expect(merged.map(\.title) == ["Austin", "Boston"])
        #expect(merged.first?.subtitle == "Saved")
    }

    @Test func mergeCapsAtFive() {
        let remote = (1...10).map {
            CitySuggestion(title: "City\($0)", subtitle: "Country", query: "City\($0)")
        }
        let merged = CitySuggestionLogic.merge(saved: [], remote: remote)
        #expect(merged.count == CitySuggestionLogic.maxSuggestions)
    }

    // MARK: countryCode

    @Test func countryCodeMatchesKnownCountryName() {
        #expect(CitySuggestionLogic.countryCode(for: "United States", locales: [Locale(identifier: "en_US")]) == "US")
    }

    @Test func countryCodeReturnsNilForUnknownName() {
        #expect(CitySuggestionLogic.countryCode(for: "Narnia", locales: [Locale(identifier: "en_US")]) == nil)
    }

    @Test func countryCodeAcceptsBareTwoLetterCode() {
        #expect(CitySuggestionLogic.countryCode(for: "us", locales: [Locale(identifier: "en_US")]) == "US")
    }

    @Test func countryCodeHandlesEmptyString() {
        #expect(CitySuggestionLogic.countryCode(for: "", locales: [Locale(identifier: "en_US")]) == nil)
    }

    // MARK: owmQuery

    @Test func owmQueryAppendsCountryCodeFromLastSubtitleComponent() {
        #expect(CitySuggestionLogic.owmQuery(title: "Austin", subtitle: "TX, United States") == "Austin,US")
    }

    @Test func owmQueryFallsBackToTitleWhenSubtitleIsEmpty() {
        #expect(CitySuggestionLogic.owmQuery(title: "Austin", subtitle: "") == "Austin")
    }

    @Test func owmQueryFallsBackToTitleWhenCountryUnrecognized() {
        #expect(CitySuggestionLogic.owmQuery(title: "Narnia City", subtitle: "Narnia") == "Narnia City")
    }

    @Test func owmQueryDropsStateFoldedIntoTitle() {
        // MapKit sometimes puts the state in the title rather than the subtitle.
        #expect(CitySuggestionLogic.owmQuery(title: "Austin, TX", subtitle: "United States") == "Austin,US")
    }

    /// Regression test: picking the Honolulu suggestion used to search for "Honolulu HI,US",
    /// which OWM couldn't find, because the state ended up jammed into the city name.
    @Test func owmQueryHandlesHonoluluWhereMapKitFoldsStateIntoTitle() {
        #expect(CitySuggestionLogic.owmQuery(title: "Honolulu, HI", subtitle: "United States") == "Honolulu,US")
    }
}
