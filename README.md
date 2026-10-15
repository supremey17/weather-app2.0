# Weather Journey

A SwiftUI weather app, reimagined as a retro pixel-art road trip. Search any city (or use your approximate location) and the whole screen transforms: the sky, the backdrop, and a live particle layer all shift to match the current conditions — sunny, cloudy, rainy, stormy, snowy, or misty, day or night — while your avatar waits in a little garage "showroom" with a gear checklist for what to wear.

It's a full port of an earlier JavaFX desktop app (`src/main/java`), rebuilt natively for iOS with real on-device computer vision, animated weather, and a lot more weather data than the original ever showed.

## What it does

- **Search or locate.** Type a city — autocomplete suggests your saved cities first, then real places via MapKit — or tap "Use my approximate location" for weather near you.
- **Living pixel-art scenery.** The background, sky color, and a `Canvas`-based particle system (rain, snow, lightning flashes, drifting clouds) all react to the real forecast and to day/night, built on one shared animation clock so everything stays in sync.
- **Your avatar, dressed for the weather.** Upload a photo of yourself (on-device only, never uploaded anywhere) and the app cuts out the background, pixelates it to match the art style, and stands it in the garage next to a "gear check" list — a coat, an umbrella, sunglasses — generated from the day's actual conditions.
- **Full weather detail, not just a number.** Below the hero card: feels-like, humidity, pressure, wind, visibility, UV index, sunrise/sunset in the city's own local time, air quality, the next 24 hours, and a 5-day forecast.
- **Saved cities & settings.** Star a city to keep it in your list, swipe to remove it, and set a home city, default units, and whether avatar/gear-advice sections show at all.

## How it's built

| Layer | Files |
|---|---|
| Screen & navigation | `ContentView.swift`, `WeatherApp.swift` |
| Weather state & orchestration | `WeatherViewModel.swift` |
| Networking, caching & rate limiting | `WeatherService.swift`, `RequestGate.swift` |
| Weather data models | `WeatherModels.swift`, `WeatherDetails.swift` / `WeatherDetailsView.swift` |
| Pixel-art rendering | `PixelBackground.swift`, `PixelBackgroundScenes.swift`, `PixelSkyEffects.swift`, `PixelSprites.swift`, `PixelWeatherTheme.swift`, `PixelClock.swift` |
| Animated precipitation | `WeatherParticles.swift`, `PrecipitationIntensity.swift` |
| Clothing / gear advice | `ClothingAdvisor.swift` |
| Avatar pipeline | `AvatarPhotoPickerView.swift`, `AvatarPhotoStore.swift`, `AvatarImageProcessing.swift`, `AvatarBackgroundRemoval.swift`, `BodyPoseDetector.swift`, `AvatarPoseCheck.swift`, `AvatarAccessory.swift`, `AvatarView.swift` |
| City search & location | `CitySuggester.swift`, `LocationService.swift` |
| Preferences, settings & saved cities | `Preferences.swift`, `SettingsView.swift`, `SavedCitiesView.swift` |

No third-party packages — everything is URLSession, SwiftUI, Vision, Core Image, and MapKit.

## Run it

1. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` and put your OpenWeatherMap key in it.
2. Open `WeatherApp.xcodeproj` in Xcode 16 or newer.
3. Pick an iPhone simulator and press Run. To run on your own phone, choose your team under Signing & Capabilities.

Requires iOS 17.

The UV index needs its own One Call API 4.0 subscription from OpenWeatherMap — without it the app still works, just without UV advice.

## Where the data comes from

- **Current conditions** (temperature, humidity, wind, pressure, cloud cover, rain/snow, sunrise/sunset, UV) come from OpenWeatherMap's `/weather` endpoint.
- **Air quality** and the **5-day forecast** come from OWM's `/air_pollution` and `/forecast` endpoints, fetched in parallel so a search takes about as long as the slowest call, not the sum of all of them. If one fails, only that section is left out — the rest of the screen still shows.
- **"Next 24 hours," the 5-day forecast, and today's low/high** actually come from [Open-Meteo](https://open-meteo.com) (free, no key), because OWM's free tier only gives 3-hourly forecasts and a `temp_min`/`temp_max` that's really the spread across the metro area right now, not the day's range. If Open-Meteo is unreachable, it falls back to OWM's 3-hour forecast.
- Weather icons are local SF Symbols mapped from condition text, not OWM's icon URLs — so icons load from cache offline and no request (which would reveal the searched city) goes to a third party just to fetch a picture.

Every request — OWM or Open-Meteo — goes through `RequestGate.swift`, which caches responses for 10 minutes, merges identical in-flight requests into one call, and caps each device at 20 real network calls per minute. All installs share one OWM key and quota, so this only protects each phone individually; putting a small server-side proxy (e.g. a Cloudflare Worker) in front of OWM would protect the shared key across every user.

## The avatar, in more detail

Tapping the avatar opens a photo picker (no photo-library permission needed, via `PhotosPicker`). The chosen photo:

1. Is downscaled and auto-rotated to its correct orientation.
2. Has its background cut to transparent using Vision's on-device person-segmentation model (`AvatarBackgroundRemoval.swift`) — a hard confidence threshold, not a soft fade, per how it was designed.
3. Gets pixelated with Core Image to match the game's art style (purely a visual choice, not a privacy measure).
4. Is optionally checked against a suggested pose (facing the camera, arms at your sides) via Vision's body-pose detection — but this is only ever a suggestion; there's no gate that blocks using a photo, by design, for accessibility and because pose detection isn't reliable for everyone.

Everything happens on-device and off the main thread; nothing about the photo is ever sent over the network. The photo is stored as a PNG via `AvatarPhotoStore.swift`, excluded from iCloud backup.

## Search autocomplete

`CitySuggester.swift` shows matching saved cities first (no network call), then real places from MapKit's `MKLocalSearchCompleter` — never OpenWeatherMap, so typing never touches the API key or its rate limit. Lookups debounce 250ms, need 2+ characters, and cap at 5 results.

## Tests

`WeatherAppTests` uses Swift Testing (`@Test` / `#expect`). Run it from Xcode (⌘U) or with the `RunAllTests` / `RunSomeTests` Xcode tools. Coverage includes the pixel weather theme and particle engine, city suggestion logic, request gating/caching, clothing advice, the full weather-details pipeline, and the avatar pipeline (background removal, pixelation, pose guidance, storage).

## Java → Swift map

This app started as a JavaFX desktop app. Where functionality carried over:

| Java | Swift |
|---|---|
| `App.java` | `WeatherApp.swift`, `ContentView.swift`, `WeatherViewModel.swift` |
| `WeatherAPI.java` | `WeatherService.swift`, `RequestGate.swift` |
| records (`WeatherResponse`, `MainInfo`, ...) | `WeatherModels.swift` |
| `ClothingAdvisor.java` | `ClothingAdvisor.swift` |
| `AvatarView.java` | `AvatarView.swift` |
| `PreferencesService.java` | `Preferences.swift` |
| `LocationService.java` (ip-api.com) | `LocationService.swift` (CoreLocation) |
| `SettingsWindow.java` | `SettingsView.swift` |
| `SavedCitiesWindow.java` | `SavedCitiesView.swift` |
| *(new in the Swift port)* | `CitySuggester.swift`, `WeatherDetails.swift` / `WeatherDetailsView.swift`, the entire avatar pipeline, the pixel-art rendering system |

`SlangService.java` was commented out in the Java version and was never ported.
