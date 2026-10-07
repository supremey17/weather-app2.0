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
    var avatarFaceAnchors: FaceAnchors?
    /// Off by default (see `Preferences.isAccessoriesEnabled`).
    var accessoriesEnabled: Bool
    /// The selected accessory id for each slot, if any (see `Preferences.selectedAccessoryIDs`).
    var selectedAccessoryIDs: [AccessorySlot: String]
    var weatherTheme: PixelWeatherTheme = .neutral
    var conditionTitle = "Weather briefing"
    /// Whether the most recently loaded weather reading was at night, per `PixelWeatherTheme.isNight`.
    var isNight = false
    /// How hard the current precipitation (if any) is coming down — drives the full-page particle
    /// effect's density/speed (see `WeatherParticleConfig.make`).
    var precipitationIntensity: PrecipitationIntensity = .normal
    /// The selected decorative page backdrop (see `PixelBackground`).
    var selectedBackground: PixelBackground

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
        accessoriesEnabled = prefs.isAccessoriesEnabled
        selectedAccessoryIDs = prefs.selectedAccessoryIDs
        selectedBackground = prefs.selectedBackground
        service = try? WeatherService()
        if let data = avatarStore.load() {
            avatarImage = UIImage(data: data)
        }
        avatarFaceAnchors = avatarStore.loadAnchors()
    }

    var hasAvatarPhoto: Bool { avatarImage != nil }

    func setAvatarPhoto(_ image: UIImage) async {
        let (processed, anchors) = await Task.detached(priority: .userInitiated) { () -> (UIImage, FaceAnchors?) in
            // Face-landmark detection runs on the downscaled, pre-pixelation buffer alongside the
            // existing pixelation work: landmark detection is unreliable on blocky/pixelated
            // input, so it must happen before `pixelate`, not after.
            let downscaled = AvatarImageProcessing.downscale(image)
            let anchors = downscaled.cgImage.flatMap(FaceAnchorDetector.detect(in:))
            let avatar = AvatarImageProcessing.makeAvatar(from: image)
            return (avatar, anchors)
        }.value
        avatarImage = processed
        avatarFaceAnchors = anchors
        guard let data = processed.pngData() else {
            resultText = "Your avatar could not be saved. Please try another photo."
            return
        }
        do {
            try avatarStore.save(data)
        } catch {
            resultText = "Your avatar could not be saved. Please try another photo."
            return
        }
        if let anchors {
            try? avatarStore.saveAnchors(anchors)
        } else {
            avatarStore.deleteAnchors()
        }
    }

    func removeAvatarPhoto() {
        avatarImage = nil
        avatarFaceAnchors = nil
        avatarStore.delete()
        avatarStore.deleteAnchors()
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

    /// Whether the trimmed `cityInput` is currently in the saved cities list.
    var isCurrentCitySaved: Bool {
        savedCities.contains(cityInput.trimmingCharacters(in: .whitespaces))
    }

    /// Saves the current city if it isn't saved yet, or removes it if it already is.
    func toggleCurrentCitySaved() {
        let city = cityInput.trimmingCharacters(in: .whitespaces)
        guard !city.isEmpty else { return }
        if savedCities.contains(city) {
            prefs.removeSavedCity(city)
        } else {
            prefs.addSavedCity(city)
        }
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

    /// The accessories to actually draw: empty unless both `accessoriesEnabled` and
    /// `avatarEnabled` are on, otherwise one resolved accessory per slot that has a valid
    /// selection, in `AccessorySlot.allCases` order. Re-validates each selection against the
    /// current catalog (mirroring `Preferences.selectedAccessoryIDs`'s own check) so this never
    /// trusts stale state even if `selectedAccessoryIDs` was set some other way.
    var activeAccessories: [AvatarAccessory] {
        guard accessoriesEnabled, avatarEnabled else { return [] }
        return AccessorySlot.allCases.compactMap { slot in
            guard let id = selectedAccessoryIDs[slot],
                  let accessory = AvatarAccessory.accessory(id: id),
                  accessory.slot == slot else {
                return nil
            }
            return accessory
        }
    }

    func saveSettings(
        defaultUnits: Units,
        homeCity: String,
        adviceEnabled: Bool,
        avatarEnabled: Bool,
        accessoriesEnabled: Bool,
        accessoryIDs: [AccessorySlot: String],
        background: PixelBackground
    ) async {
        prefs.defaultUnits = defaultUnits
        prefs.homeCity = homeCity
        prefs.isAdviceEnabled = adviceEnabled
        prefs.isAvatarEnabled = avatarEnabled
        prefs.isAccessoriesEnabled = accessoriesEnabled
        prefs.selectedAccessoryIDs = accessoryIDs
        prefs.selectedBackground = background
        units = defaultUnits
        self.adviceEnabled = adviceEnabled
        self.avatarEnabled = avatarEnabled
        self.accessoriesEnabled = accessoriesEnabled
        self.selectedAccessoryIDs = accessoryIDs
        self.selectedBackground = background
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
            isNight = PixelWeatherTheme.isNight(epochSeconds: weather.dt, timeZoneOffset: weather.timezone)
            precipitationIntensity = PrecipitationIntensity.make(
                condition: condition,
                description: description,
                rainOneHourMillimeters: weather.rain?.oneHour,
                snowOneHourMillimeters: weather.snow?.oneHour
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
