import CoreLocation
import Foundation
import Observation
import UIKit

/// Holds the dashboard state and coordinates local persistence, location access, and weather loading.
@MainActor
@Observable
final class WeatherViewModel {
    var cityInput = ""
    var units: Units
    var resultText = ""
    var advice: [String] = []
    var details: WeatherDetailsResult?
    var isLoading = false
    var savedCities: [String]
    var adviceEnabled: Bool
    var avatarEnabled: Bool
    var avatarImage: UIImage?
    var weatherTheme: PixelWeatherTheme = .neutral
    var conditionTitle = "Weather briefing"

    private let prefs: Preferences
    private let advisor = ClothingAdvisor()
    private let locationService = LocationService()
    private let avatarStore: AvatarPhotoStore
    private var service: WeatherService?

    init(prefs: Preferences = Preferences(), avatarStore: AvatarPhotoStore = AvatarPhotoStore()) {
        self.prefs = prefs
        self.avatarStore = avatarStore
        units = prefs.defaultUnits
        savedCities = prefs.savedCities
        adviceEnabled = prefs.isAdviceEnabled
        avatarEnabled = prefs.isAvatarEnabled
        service = try? WeatherService()
        if let data = avatarStore.load() {
            avatarImage = UIImage(data: data)
        }
    }

    var hasAvatarPhoto: Bool { avatarImage != nil }

    func setAvatarPhoto(_ image: UIImage) async {
        let processed = await Task.detached(priority: .userInitiated) {
            AvatarImageProcessing.makeAvatar(from: image)
        }.value
        avatarImage = processed
        guard let data = processed.pngData() else {
            resultText = "Your avatar could not be saved. Please try another photo."
            return
        }
        do {
            try avatarStore.save(data)
        } catch {
            resultText = "Your avatar could not be saved. Please try another photo."
        }
    }

    func removeAvatarPhoto() {
        avatarImage = nil
        avatarStore.delete()
    }

    /// Starts from an explicitly chosen city. Location is requested only from the dashboard action.
    func start() async {
        guard service != nil else {
            resultText = "Weather service setup is incomplete."
            return
        }
        if let home = prefs.homeCity, !home.trimmingCharacters(in: .whitespaces).isEmpty {
            cityInput = home
        } else if let last = prefs.lastCity {
            cityInput = last
        } else {
            resultText = "Choose a city or use your approximate location."
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

    /// Requests a single approximate location only after the person selects the dashboard action.
    func useCurrentLocation() async {
        guard let service else { return }
        let coordinate: CLLocationCoordinate2D
        do {
            coordinate = try await locationService.currentLocation().coordinate
        } catch {
            resultText = "Location is unavailable. Search for a city instead."
            return
        }
        await load(city: nil) {
            try await service.findByCoordinates(lat: coordinate.latitude, lon: coordinate.longitude, units: self.units)
        }
    }

    func toggleUnits() async {
        guard !isLoading else { return }
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

    private func load(city: String?, fetch: () async throws -> WeatherResponse) async {
        guard let service, !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        do {
            let weather = try await fetch()
            async let uviResult = service.uvIndex(lat: weather.coord.lat, lon: weather.coord.lon)
            async let airResult = service.airQuality(lat: weather.coord.lat, lon: weather.coord.lon)
            async let forecastResult = service.forecast(lat: weather.coord.lat, lon: weather.coord.lon, units: units)
            let uvi = (try? await uviResult) ?? 0
            let air = (try? await airResult) ?? nil
            let forecast = (try? await forecastResult) ?? nil

            let condition = weather.weather.first?.main ?? ""
            let description = weather.weather.first?.description ?? ""
            let tempF = units == .metric ? weather.main.temp * 9 / 5 + 32 : weather.main.temp

            resultText = "\(weather.name): \(weather.main.temp)\(units.symbol), \(description)"
            conditionTitle = description.isEmpty ? "Weather briefing" : description
            weatherTheme = PixelWeatherTheme.make(
                condition: condition,
                epochSeconds: weather.dt,
                timeZoneOffset: weather.timezone
            )
            advice = advisor.advice(tempF: tempF, humidity: weather.main.humidity, condition: condition, uvi: uvi)
            details = WeatherDetails.build(weather: weather, uvi: uvi, air: air, forecast: forecast, units: units)

            let searched = city ?? weather.name
            cityInput = searched
            prefs.lastCity = searched
        } catch WeatherError.cityNotFound(let name) {
            resultText = "We couldn't find \(name). Check the spelling and try again."
            advice = []
            details = nil
        } catch WeatherError.rateLimited {
            resultText = "Weather requests are temporarily limited. Try again in a minute."
            advice = []
            details = nil
        } catch is CancellationError {
            resultText = "Weather loading was cancelled. Please try again."
            advice = []
            details = nil
        } catch {
            resultText = "Weather is unavailable right now. Please try again."
            advice = []
            details = nil
        }
    }
}
