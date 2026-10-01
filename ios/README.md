# Weather App (iOS)

SwiftUI port of the JavaFX app in `src/main/java`.

## Run it

1. Copy `Config/Secrets.example.xcconfig` to `Config/Secrets.xcconfig` and put your OpenWeatherMap key in it.
2. Open `WeatherApp.xcodeproj` in Xcode 16 or newer.
3. Pick an iPhone simulator and press Run. To run on your own phone, choose your team under Signing & Capabilities.

Requires iOS 17. No third-party packages.

## Tests

`WeatherAppTests` uses Swift Testing (`@Test`/`#expect`). Run it from Xcode (⌘U) or with the `RunAllTests`/`RunSomeTests` Xcode tools.

## Java to Swift map

| Java | Swift |
|---|---|
| `App.java` | `WeatherApp.swift`, `ContentView.swift`, `WeatherViewModel.swift` |
| `WeatherAPI.java` | `WeatherService.swift` (URLSession + Decodable), `RequestGate.swift` (cache + rate limit) |
| records (`WeatherResponse`, `MainInfo`, ...) | `WeatherModels.swift` |
| `ClothingAdvisor.java` | `ClothingAdvisor.swift` |
| `AvatarView.java` | `AvatarView.swift` (shows the user's own avatar photo, or a fallback silhouette from `Assets.xcassets`) |
| `PreferencesService.java` | `Preferences.swift` (UserDefaults) |
| `LocationService.java` (ip-api.com) | `LocationService.swift` (CoreLocation) |
| `SettingsWindow.java` | `SettingsView.swift` (sheet) |
| `SavedCitiesWindow.java` | `SavedCitiesView.swift` (sheet, swipe to delete) |
| *(new in the Swift port)* | `CitySuggester.swift` (search bar autocomplete) |
| *(new in the Swift port)* | `WeatherDetails.swift` (full weather section logic), `WeatherDetailsView.swift` (its UI) |
| *(new in the Swift port)* | `AvatarPhotoPickerView.swift` (photo upload page), `AvatarPhotoStore.swift` (local storage), `AvatarImageProcessing.swift` (pixelation), `BodyPoseDetector.swift` + `AvatarPoseCheck.swift` (pose suggestion) |

`SlangService.java` is commented out in Java and not ported yet.

The UV index comes from One Call API 4.0, which needs its own OpenWeatherMap subscription. Without it the app still shows the weather, just without UV advice.

## API usage limits

Every install calls OpenWeatherMap directly with the same key, so all users share one quota (about 60 calls/min on the free tier). Every request goes through `RequestGate.swift`, which:

- caches successful responses for 10 minutes, since OWM only refreshes current conditions about that often. Searching the same city again, or toggling back to units you already loaded, doesn't call the API. City names are matched case-insensitively. Coordinates are rounded to about 1 km.
- joins identical requests that are already in flight into one call.
- allows at most 20 real network calls per minute per device. Cache hits don't count. Past that, or if OWM answers HTTP 429, the app shows "Slow down bestie! Try again in a minute."

Search and unit-toggle taps are also ignored while a request is loading.

This only limits each phone on its own. To protect the key across all users (and keep it out of the app bundle), put a small server-side proxy in front of OWM, such as a Cloudflare Worker that holds the key and shares one cache.

## Search autocomplete

Typing a city shows matching suggestions, handled by `CitySuggester.swift`:

- Saved cities that match what's typed so far are shown first, with no network call.
- The rest come from Apple's MapKit place search (`MKLocalSearchCompleter`), not OpenWeatherMap, so typing never touches the OWM key or `RequestGate`'s limit. MapKit needs no API key of its own.
- Lookups wait until 2+ characters are typed, debounce 250ms after the last keystroke, and are capped at 5 results. Results for a query that's no longer current (the user kept typing) are discarded.
- Nothing typed is logged or persisted; only a completed search is saved, same as before. Suggestion text is rendered with `Text(verbatim:)` so it's never interpreted as markup.
- Picking a suggestion runs the normal search, so that fetch still goes through `RequestGate`. The OWM query is built as `"City,CC"` when the suggestion's region maps to an ISO country code, else just `"City"`.
- Suggestions only show while the search field is focused, and clear on submit, on picking a result, or on losing focus.

Covered by `WeatherAppTests` (`CitySuggestionLogicTests.swift`, `CitySuggesterTests.swift`).

## Full weather details

Below the avatar and clothing advice, a "Right now" / "Air quality" / "Next 24 hours" / "5-day forecast" section shows everything OWM's response gives us. Logic lives in `WeatherDetails.swift` (no SwiftUI/networking, so it's unit tested directly); the view is `WeatherDetailsView.swift`.

- **Current conditions** (feels like, low/high, humidity, pressure, wind, cloud cover, visibility, rain/snow, sunrise/sunset, UV) cost **0 extra API calls** — they're already in the `/weather` response the app fetches today; the old code just ignored most of the fields. OWM can omit several of these (rain, snow, gusts, visibility...), so they're all `Optional` — a repeat of the missing-field crash fixed in 37383cb would mean the whole weather section fails to show, not just one tile.
- **Air quality** and the **5-day forecast** are new endpoints (`/air_pollution`, `/forecast`), so each search now makes 4 calls instead of 2. They're fetched **in parallel** with UV (`async let` in `WeatherViewModel.load`), so a search takes about as long as the slowest one, not the sum. Each goes through `RequestGate` like every other call, so they're cached 10 minutes and share the 20-calls/min device limit. If one fails or is rate limited, only that section is left out — the main weather still shows.
- Air quality doesn't depend on units, so toggling °F/°C is a cache hit for it.
- Sunrise/sunset and the hourly/daily times are shown in **the searched city's own time zone** (from the response's `timezone` offset), not the phone's.
- Weather icons are local SF Symbols mapped from OWM's condition text — **not** OWM's icon URLs. That avoids a third-party request per icon (which would leak the searched location) and works from the cache offline.
- API text is rendered with `Text(verbatim:)`. Out-of-range values (e.g. an AQI outside 1-5) hide that part of the UI instead of showing something wrong.

Making 4 calls per search instead of 2 uses the shared free-tier key faster, which strengthens the case for the server-side proxy mentioned above. Covered by `WeatherAppTests/WeatherDetailsTests.swift`.

## Avatar photo

Tapping the avatar opens a page (`AvatarPhotoPickerView.swift`) to pick a photo of yourself from the photo library (`PhotosPicker`, so no photo-library permission string is needed) and use it as your avatar instead of the generic silhouette. The uploaded photo **is** the outfit now — the old per-condition clothing-layer PNGs (`coat`, `Jacket`, `hot`) and `ClothingAdvisor.outfitLayers` are gone; only the generic `casual` silhouette remains as the no-photo fallback. The clothing-advice *text* is unchanged.

- **Everything stays on the device.** The photo is never uploaded anywhere, logged, or sent through `WeatherService`/`RequestGate` — there's no reason for this feature to touch the network at all.
- It's stored as a PNG via `AvatarPhotoStore.swift` (`FileManager`, Application Support directory, excluded from iCloud backup), not `UserDefaults` — `Preferences.swift` only holds strings/bools.
- The background is cut out to transparent (`AvatarBackgroundRemoval.swift`) before pixelating. Vision's on-device `VNGeneratePersonSegmentationRequest` scores every pixel by how confident it is that pixel is part of a person — that confidence map is the "contrast" signal between avatar and background. A hard threshold (50% confidence by default) splits the image: pixels at or above it keep their original color and go fully opaque, everything else goes fully transparent. No gradient/feathering — a clean cut, per how this was asked for.
  - A plain per-pixel RGB contrast/edge threshold was considered and rejected: it has no dependable "background color" to measure against in an arbitrary photo, and fails on exactly the hard cases (dark hair against a dark background, busy backgrounds, low contrast lighting). Vision's segmentation model already solves that; the threshold is applied to its confidence map instead of raw pixels.
  - Falls back to the original photo, untouched, if no person is detected or anything in the pipeline fails — never crashes, never produces a blank/all-transparent image.
- Before storing, the photo is downscaled (longest side ~400px) and pixelated with Core Image's `CIFilter.pixellate`, matching the app's existing pixel-art look. This is a style choice, not a privacy/anonymization measure — plain pixelation is weak and often reversible, so it shouldn't be relied on to hide someone's identity. Downscaling happens first (`AvatarImageProcessing.makeAvatar`), both to keep segmentation cheap and because redrawing through `UIGraphicsImageRenderer` bakes in the photo's EXIF orientation, so Vision and Core Image downstream never have to special-case a sideways or upside-down photo.
- A pose check (`BodyPoseDetector.swift` using Vision's on-device `VNDetectHumanBodyPoseRequest`, `AvatarPoseCheck.swift` for the pass/fail logic) suggests facing the camera with arms at your sides, for the clothing-overlay-free look to read well — but it's **only ever a suggestion**. There's no device-side or app-side block: the "Use This Photo" button always works, regardless of what the pose check says. This matters for accessibility (limb differences, mobility aids, a kid who won't hold still) and because pose detection is known to read less reliably across some body types, clothing, and lighting.
- A "Remove Photo" action deletes the file and reverts to the silhouette.
- Segmentation and pixelation run off the main actor (`Task.detached`), so a large photo doesn't freeze the UI; the picker page shows "Cutting out the background…" while it works.

Covered by `WeatherAppTests` (`PoseGuidanceTests.swift`, `AvatarImageProcessingTests.swift`, `AvatarPhotoStoreTests.swift`, `AvatarBackgroundRemovalTests.swift`). Vision's actual segmentation/pose accuracy and the `PhotosPicker` UI aren't unit tested — check those by hand in the simulator/device.
