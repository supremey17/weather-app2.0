import Foundation
import Testing
@testable import WeatherApp

struct PixelBackgroundTests {

    // MARK: - PixelBackground.cycled

    @Test func cyclingForwardFromLastCaseWrapsToFirstCase() {
        #expect(PixelBackground.cycled(from: .beach, forward: true) == .weather)
    }

    @Test func cyclingBackwardFromFirstCaseWrapsToLastCase() {
        #expect(PixelBackground.cycled(from: .weather, forward: false) == .beach)
    }

    @Test func cyclingForwardSevenTimesFromAnyStartReturnsToThatStart() {
        for start in PixelBackground.allCases {
            var current = start
            for _ in 0..<PixelBackground.allCases.count {
                current = PixelBackground.cycled(from: current, forward: true)
            }
            #expect(current == start)
        }
    }

    // MARK: - Preferences.selectedBackground

    @Test func selectedBackgroundRoundTripsAValidValue() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)

        prefs.selectedBackground = .ocean
        #expect(prefs.selectedBackground == .ocean)

        prefs.selectedBackground = .mountains
        #expect(prefs.selectedBackground == .mountains)
    }

    @Test func selectedBackgroundDefaultsToWeatherWhenNothingStored() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)

        #expect(prefs.selectedBackground == .weather)
    }

    @Test func selectedBackgroundFallsBackToWeatherOnBogusStoredValue() throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)

        defaults.set("not-a-real-background", forKey: "selected_background")
        #expect(prefs.selectedBackground == .weather)
    }

    // MARK: - WeatherViewModel.saveSettings persists background

    @MainActor
    private func makeModel(prefs: Preferences) -> WeatherViewModel {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let avatarStore = AvatarPhotoStore(directory: dir)
        return WeatherViewModel(prefs: prefs, avatarStore: avatarStore)
    }

    @MainActor
    @Test func saveSettingsPersistsTheGivenBackground() async throws {
        let defaults = try #require(UserDefaults(suiteName: UUID().uuidString))
        let prefs = Preferences(defaults: defaults)
        let model = makeModel(prefs: prefs)

        await model.saveSettings(
            defaultUnits: model.defaultUnits,
            homeCity: model.homeCity,
            adviceEnabled: model.adviceEnabled,
            avatarEnabled: model.avatarEnabled,
            accessoriesEnabled: model.accessoriesEnabled,
            accessoryIDs: model.selectedAccessoryIDs,
            background: .river
        )

        #expect(model.selectedBackground == .river)
        #expect(prefs.selectedBackground == .river)
    }
}
