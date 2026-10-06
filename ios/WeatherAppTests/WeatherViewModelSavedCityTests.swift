import Foundation
import Testing
@testable import WeatherApp

@MainActor
struct WeatherViewModelSavedCityTests {

    /// Each test gets its own throwaway UserDefaults suite and avatar photo directory so tests
    /// can't interfere with each other or touch real storage.
    private func makeModel() -> WeatherViewModel {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let prefs = Preferences(defaults: defaults)
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let avatarStore = AvatarPhotoStore(directory: dir)
        return WeatherViewModel(prefs: prefs, avatarStore: avatarStore)
    }

    @Test func togglingSavesAnUnsavedCity() {
        let model = makeModel()
        model.cityInput = "Austin"
        model.toggleCurrentCitySaved()
        #expect(model.isCurrentCitySaved)
        #expect(model.savedCities.contains("Austin"))
    }

    @Test func togglingTwiceRemovesTheSavedCity() {
        let model = makeModel()
        model.cityInput = "Austin"
        model.toggleCurrentCitySaved()
        model.toggleCurrentCitySaved()
        #expect(!model.isCurrentCitySaved)
        #expect(!model.savedCities.contains("Austin"))
    }

    @Test func togglingWithBlankCityInputIsANoOp() {
        let model = makeModel()
        model.cityInput = "   "
        model.toggleCurrentCitySaved()
        #expect(model.savedCities.isEmpty)
    }
}
