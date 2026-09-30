import CoreLocation
import Foundation
import Observation

/// Holds the main screen's state and does what App.runSearch() did in the Java app.
@MainActor
@Observable
final class WeatherViewModel {
    var cityInput = ""
    var units: Units
    var resultText = ""
    var advice: [String] = []
    var layers: [String] = []
    var isLoading = false
    var savedCities: [String]
    var adviceEnabled: Bool
    var avatarEnabled: Bool

    private let prefs: Preferences
    private let advisor = ClothingAdvisor()
    private let locationService = LocationService()
    private var service: WeatherService?

    init(prefs: Preferences = Preferences()) {
        self.prefs = prefs
        units = prefs.defaultUnits
        savedCities = prefs.savedCities
        adviceEnabled = prefs.isAdviceEnabled
        avatarEnabled = prefs.isAvatarEnabled
        service = try? WeatherService()
    }

    /// Same startup order as the Java app: home city, else last searched city, else current location.
    func start() async {
        guard service != nil else {
            resultText = "OWM_API_KEY has not been set aka ts not working:/ (see ios/README.md)"
            return
        }
        if let home = prefs.homeCity, !home.trimmingCharacters(in: .whitespaces).isEmpty {
            cityInput = home
        } else if let last = prefs.lastCity {
            cityInput = last
        } else {
            await searchCurrentLocation()
            return
        }
        await search()
    }

    func search() async {
        await search(city: cityInput)
    }

    func search(city: String) async {
        let city = city.trimmingCharacters(in: .whitespaces)
        guard let service, !city.isEmpty else { return }
        cityInput = city
        await load(city: city) {
            try await service.findByCity(city, units: self.units)
        }
    }

    func toggleUnits() async {
        // Re-fetch rather than convert: OWM returns different numbers per unit, like the Java app.
        units = units.toggled
        await search()
    }

    func saveCurrentCity() {
        let city = cityInput.trimmingCharacters(in: .whitespaces)
        guard !city.isEmpty else { return }
        prefs.addSavedCity(city)
        savedCities = prefs.savedCities
    }

    func removeSavedCities(at offsets: IndexSet) {
        for index in offsets {
            prefs.removeSavedCity(savedCities[index])
        }
        savedCities = prefs.savedCities
    }

    // MARK: Settings

    var homeCity: String { prefs.homeCity ?? "" }
    var defaultUnits: Units { prefs.defaultUnits }

    func saveSettings(defaultUnits: Units, homeCity: String, adviceEnabled: Bool, avatarEnabled: Bool) async {
        prefs.defaultUnits = defaultUnits
        prefs.homeCity = homeCity
        prefs.isAdviceEnabled = adviceEnabled
        prefs.isAvatarEnabled = avatarEnabled
        units = defaultUnits
        self.adviceEnabled = adviceEnabled
        self.avatarEnabled = avatarEnabled
        await search()
    }

    // MARK: Private

    private func searchCurrentLocation() async {
        guard let service else { return }
        let coordinate: CLLocationCoordinate2D
        do {
            coordinate = try await locationService.currentLocation().coordinate
        } catch {
            resultText = "Can't tell where you are. Type a city and hit Search."
            return
        }
        await load(city: nil) {
            try await service.findByCoordinates(lat: coordinate.latitude, lon: coordinate.longitude, units: self.units)
        }
    }

    private func load(city: String?, fetch: () async throws -> WeatherResponse) async {
        guard let service else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let weather = try await fetch()
            // UV is a separate endpoint; if it fails, still show the weather (the Java app showed the wifi error).
            let uvi = (try? await service.uvIndex(lat: weather.coord.lat, lon: weather.coord.lon)) ?? 0
            let condition = weather.weather.first?.main ?? ""
            let description = weather.weather.first?.description ?? ""

            resultText = "\(weather.name): \(weather.main.temp)\(units.symbol), \(description)"

            // The advisor's thresholds are Fahrenheit, so convert when showing Celsius.
            let tempF = units == .metric ? weather.main.temp * 9 / 5 + 32 : weather.main.temp
            advice = advisor.advice(tempF: tempF, humidity: weather.main.humidity, condition: condition, uvi: uvi)
            layers = advisor.outfitLayers(tempF: tempF, humidity: weather.main.humidity, condition: condition, uvi: uvi)

            let searched = city ?? weather.name
            cityInput = searched
            prefs.lastCity = searched
        } catch WeatherError.cityNotFound(let name) {
            resultText = "Yikes \"\(name)\". was speeled wrong. First day on earth? "
            advice = []
        } catch is CancellationError {
            resultText = "Please try again i need to pay bills!"
            advice = []
        } catch {
            resultText = "They're taking the wifi:("
            advice = []
        }
    }
}
