# Weather App (iOS)

SwiftUI port of the JavaFX app in `src/main/java`.

## Run it

1. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` and put your OpenWeatherMap key in it.
2. Open `WeatherApp.xcodeproj` in Xcode 16 or newer.
3. Pick an iPhone simulator and press Run. To run on your own phone, choose your team under Signing & Capabilities.

Requires iOS 17. No third-party packages.

## Java to Swift map

| Java | Swift |
|---|---|
| `App.java` | `WeatherApp.swift`, `ContentView.swift`, `WeatherViewModel.swift` |
| `WeatherAPI.java` | `WeatherService.swift` (URLSession + Decodable) |
| records (`WeatherResponse`, `MainInfo`, ...) | `WeatherModels.swift` |
| `ClothingAdvisor.java` | `ClothingAdvisor.swift` |
| `AvatarView.java` | `AvatarView.swift` (ZStack of images in `Assets.xcassets`) |
| `PreferencesService.java` | `Preferences.swift` (UserDefaults) |
| `LocationService.java` (ip-api.com) | `LocationService.swift` (CoreLocation) |
| `SettingsWindow.java` | `SettingsView.swift` (sheet) |
| `SavedCitiesWindow.java` | `SavedCitiesView.swift` (sheet, swipe to delete) |

`SlangService.java` is commented out in Java and not ported yet.

The UV index comes from One Call API 4.0, which needs its own OpenWeatherMap subscription. Without it the app still shows the weather, just without UV advice.
