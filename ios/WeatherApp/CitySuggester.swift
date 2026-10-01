import Foundation
import MapKit
import Observation

/// One row the search bar can show: a place name plus its region, from MapKit's local search completer.
struct CitySuggestion: Hashable, Identifiable {
    let title: String
    let subtitle: String
    /// What to search OpenWeatherMap for if this suggestion is picked.
    let query: String

    var id: String { query.lowercased() }
}

/// Pure logic behind autocomplete: no MapKit, no network, so it's easy to unit test.
/// Kept separate from `CitySuggester` so the matching/merging/query-building rules
/// can be checked without spinning up `MKLocalSearchCompleter`.
enum CitySuggestionLogic {
    static let minLength = 2
    static let maxQueryLength = 100
    static let maxSuggestions = 5

    /// Trims and caps the raw text typed into the search field. `nil` means "too short to search for".
    static func sanitize(_ raw: String) -> String? {
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minLength else { return nil }
        return String(trimmed.prefix(maxQueryLength))
    }

    /// Saved cities whose name starts with what's been typed so far (case-insensitive).
    static func savedMatches(query: String, saved: [String]) -> [String] {
        let needle = query.lowercased()
        return saved.filter { $0.lowercased().hasPrefix(needle) }
    }

    /// Saved cities first (no network needed), then MapKit results, de-duplicated and capped.
    static func merge(saved: [String], remote: [CitySuggestion]) -> [CitySuggestion] {
        var seen = Set(saved.map { $0.lowercased() })
        var result = saved.map { CitySuggestion(title: $0, subtitle: "Saved", query: $0) }
        for suggestion in remote {
            let key = suggestion.title.lowercased()
            guard !seen.contains(key) else { continue }
            seen.insert(key)
            result.append(suggestion)
            if result.count == maxSuggestions { break }
        }
        return Array(result.prefix(maxSuggestions))
    }

    /// Matches a free-form region/country name (e.g. a completion's subtitle) to its ISO 3166-1 alpha-2 code.
    /// Also accepts a string that's already a valid 2-letter code. Returns `nil` if nothing matches.
    static func countryCode(for name: String, locales: [Locale] = [.current, Locale(identifier: "en_US")]) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }

        if trimmed.count == 2, trimmed.uppercased().allSatisfy({ $0.isLetter }) {
            return trimmed.uppercased()
        }

        for region in Locale.Region.isoRegions {
            let code = region.identifier
            guard code.count == 2 else { continue } // skip UN M.49 numeric codes like "001"
            for locale in locales {
                if let localized = locale.localizedString(forRegionCode: code),
                   localized.compare(trimmed, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame {
                    return code
                }
            }
        }
        return nil
    }

    /// Builds the string OWM's `q=` parameter expects: "City" or "City,CC" when the subtitle's
    /// last component (usually the country) maps to a 2-letter code. Only the part of the title
    /// before its first comma is used — MapKit sometimes folds the state into the title itself
    /// (e.g. "Honolulu, HI"), and keeping the rest produces a query OWM can't parse.
    static func owmQuery(title: String, subtitle: String) -> String {
        let cleanTitle = (title.split(separator: ",").first.map(String.init) ?? title)
            .trimmingCharacters(in: .whitespaces)
        guard let lastComponent = subtitle.split(separator: ",").last else { return cleanTitle }
        guard let code = countryCode(for: String(lastComponent)) else { return cleanTitle }
        return "\(cleanTitle),\(code)"
    }
}

/// Abstracts `MKLocalSearchCompleter` so `CitySuggester` can be tested with a fake.
@MainActor
protocol CityCompleting: AnyObject {
    var onResults: (([(title: String, subtitle: String)]) -> Void)? { get set }
    var onError: ((Error) -> Void)? { get set }
    func query(_ fragment: String)
    func cancel()
}

/// Wraps `MKLocalSearchCompleter`, restricted to addresses (cities) with points of interest excluded.
/// Nothing here needs an API key or touches the network quota `RequestGate` protects.
@MainActor
final class MapKitCityCompleter: NSObject, CityCompleting {
    var onResults: (([(title: String, subtitle: String)]) -> Void)?
    var onError: ((Error) -> Void)?

    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.resultTypes = .address
        completer.pointOfInterestFilter = .excludingAll
        if #available(iOS 18, *) {
            completer.addressFilter = MKAddressFilter(including: [.locality, .administrativeArea, .country])
        }
        completer.delegate = self
    }

    func query(_ fragment: String) {
        completer.queryFragment = fragment
    }

    func cancel() {
        completer.cancel()
    }
}

extension MapKitCityCompleter: MKLocalSearchCompleterDelegate {
    nonisolated func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        MainActor.assumeIsolated {
            onResults?(completer.results.map { ($0.title, $0.subtitle) })
        }
    }

    nonisolated func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        MainActor.assumeIsolated {
            onError?(error)
        }
    }
}

/// Drives the search bar's autocomplete: debounces typing, merges saved cities with MapKit
/// results, and never logs or persists what's been typed (only a completed search is remembered,
/// via `WeatherViewModel`/`Preferences` as before).
@MainActor
@Observable
final class CitySuggester {
    var suggestions: [CitySuggestion] = []

    private let completer: CityCompleting
    private let debounce: Duration
    private var debounceTask: Task<Void, Never>?
    private var latestQuery: String?
    private var matchedSavedCities: [String] = []

    convenience init(debounce: Duration = .milliseconds(250)) {
        self.init(completer: MapKitCityCompleter(), debounce: debounce)
    }

    init(completer: CityCompleting, debounce: Duration = .milliseconds(250)) {
        self.completer = completer
        self.debounce = debounce
        self.completer.onResults = { [weak self] results in
            self?.handle(results: results)
        }
        self.completer.onError = { [weak self] _ in
            // Silently clear rather than surface a MapKit error; this is just a convenience list.
            self?.suggestions = []
        }
    }

    /// Call on every keystroke. Shows matching saved cities immediately, then asks MapKit after
    /// a short pause so fast typing doesn't fire a lookup per character.
    func update(query raw: String, saved: [String]) {
        guard let query = CitySuggestionLogic.sanitize(raw) else {
            clear()
            return
        }
        latestQuery = query
        matchedSavedCities = CitySuggestionLogic.savedMatches(query: query, saved: saved)
        suggestions = CitySuggestionLogic.merge(saved: matchedSavedCities, remote: [])

        debounceTask?.cancel()
        debounceTask = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            self?.completer.query(query)
        }
    }

    func clear() {
        debounceTask?.cancel()
        debounceTask = nil
        latestQuery = nil
        matchedSavedCities = []
        completer.cancel()
        suggestions = []
    }

    private func handle(results: [(title: String, subtitle: String)]) {
        // Drop results for a query that's no longer current (user kept typing).
        guard latestQuery != nil else { return }
        let remote = results.map {
            CitySuggestion(title: $0.title, subtitle: $0.subtitle, query: CitySuggestionLogic.owmQuery(title: $0.title, subtitle: $0.subtitle))
        }
        suggestions = CitySuggestionLogic.merge(saved: matchedSavedCities, remote: remote)
    }
}
