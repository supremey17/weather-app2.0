# Graph Report - weather-app2.0  (2026-10-06)

## Corpus Check
- 61 files · ~59,246 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 9 file(s) not represented in the graph (top: .ttf 3, (none) 2, .xcconfig 1)

## Summary
- 822 nodes · 1719 edges · 44 communities (31 shown, 13 thin omitted)
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 220 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `81cc3206`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- App.java
- WeatherViewModel
- CitySuggester
- RequestGate
- WeatherModels.swift
- WeatherAPI.java
- Units
- WeatherService
- PixelSpriteKind
- Foundation
- LocationService
- PixelPanel
- com.weatherapp:weather-app
- BodyPoseLandmarks
- .targetSize
- PreferencesService
- .body
- .setAvatarPhoto
- PixelWeatherTheme
- AvatarView
- AccessorySlotRow
- .textColor
- PixelBevelShape
- Role
- PixelStatBar
- AvatarAccessory
- View
- CodingKeys
- com.fasterxml.jackson.annotation.JsonIgnoreProperties
- AvatarPhotoStore
- .isForeground
- WeatherDetailsTests
- AccessorySlot
- DetailItem
- AvatarPhotoPickerView
- AvatarImageProcessing
- list
- FaceAnchors
- AirSample
- PixelSprite
- AvatarView.java
- AvatarPhotoStoreTests
- PixelSpriteKindSFSymbolMappingTests

## God Nodes (most connected - your core abstractions)
1. `PixelSpriteKind` - 62 edges
2. `PixelWeatherTheme` - 61 edges
3. `WeatherViewModel` - 41 edges
4. `RequestGate` - 25 edges
5. `PixelPanel` - 24 edges
6. `AvatarAccessory` - 22 edges
7. `CodingKeys` - 22 edges
8. `Units` - 22 edges
9. `Preferences` - 21 edges
10. `AvatarAccessoryTests` - 21 edges

## Surprising Connections (you probably didn't know these)
- `Still to build` --references--> `PixelSprite`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/PixelSprites.swift
- `Search autocomplete` --references--> `RequestGate`  [INFERRED]
  ios/README.md → ios/WeatherApp/RequestGate.swift
- `Coordinate mapping` --references--> `AvatarAccessoryGeometry`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarView.swift
- `Detection` --references--> `BodyPoseDetector`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/BodyPoseDetector.swift
- `Avatar photo` --references--> `RequestGate`  [INFERRED]
  ios/README.md → ios/WeatherApp/RequestGate.swift

## Import Cycles
- None detected.

## Communities (44 total, 13 thin omitted)

### Community 0 - "App.java"
Cohesion: 0.12
Nodes (3): App, SettingsWindow, CityNotFoundException

### Community 1 - "WeatherViewModel"
Cohesion: 0.06
Nodes (17): ClothingAdvisor, .body, Preferences, .defaultUnits, .homeCity, .isAccessoriesEnabled, .isAdviceEnabled, .isAvatarEnabled (+9 more)

### Community 2 - "CitySuggester"
Cohesion: 0.06
Nodes (10): CityCompleting, CitySuggester, CitySuggestion, .id, CitySuggestionLogic, MapKitCityCompleter, CitySuggesterTests, FakeCompleter (+2 more)

### Community 3 - "RequestGate"
Cohesion: 0.16
Nodes (6): RequestGate, FetchCounter, .count, RequestGateTests, TestClock, .now

### Community 4 - "WeatherModels.swift"
Cohesion: 0.22
Nodes (14): Clouds, Coord, CurrentBlock, ForecastCity, ForecastItem, ForecastMain, ForecastResponse, MainInfo (+6 more)

### Community 5 - "WeatherAPI.java"
Cohesion: 0.20
Nodes (3): IpLocation, LocationService, WeatherAPI

### Community 6 - "Units"
Cohesion: 0.20
Nodes (8): WeatherDetails, Units, .id, imperial, .label, metric, .symbol, .toggled

### Community 7 - "WeatherService"
Cohesion: 0.11
Nodes (14): API usage limits, Avatar photo, Full weather details, Java to Swift map, Run it, Search autocomplete, Tests, Weather App (iOS) (+6 more)

### Community 8 - "PixelSpriteKind"
Cohesion: 0.04
Nodes (47): PixelSpriteKind, accessoryBeaniePlaceholder, accessoryCapPlaceholder, accessoryCigarettePlaceholder, accessoryGlassesPlaceholder, accessoryHatPlaceholder, accessoryLollipopPlaceholder, accessoryMonoclePlaceholder (+39 more)

### Community 9 - "Foundation"
Cohesion: 0.07
Nodes (14): CoreGraphics, CoreImage, CoreImage.CIFilterBuiltins, Foundation, BodyPoseDetector, contrastRatio(), PixelSpriteKindGridTests, PixelWeatherThemeContrastTests (+6 more)

### Community 10 - "LocationService"
Cohesion: 0.21
Nodes (4): CoreLocation, LocationError, denied, LocationService

### Community 11 - "PixelPanel"
Cohesion: 0.13
Nodes (17): PixelPanel, .borderColor, AirQualitySection, .aqiLevel, .aqiNormalizedLevel, .body, .pollutants, CurrentMetricsSection (+9 more)

### Community 14 - "BodyPoseLandmarks"
Cohesion: 0.27
Nodes (3): BodyPoseLandmarks, PoseGuidance, PoseGuidanceTests

### Community 17 - ".body"
Cohesion: 0.12
Nodes (12): ContentView, .body, GarageCard, .body, WeatherHero, PixelSearchBar, PixelSuggestionMenu, .body (+4 more)

### Community 18 - ".setAvatarPhoto"
Cohesion: 0.18
Nodes (9): Art spec, Avatar accessories (scaffold), Default silhouette, Detection, Goal & privacy boundary, Open questions, Slots, Still to build (+1 more)

### Community 19 - "PixelWeatherTheme"
Cohesion: 0.10
Nodes (24): .body, PixelPalette, PixelParallaxScene, .shouldAnimate, PixelTextButtonStyle, PixelWeatherTheme, .accentColor, clearDay (+16 more)

### Community 20 - "AvatarView"
Cohesion: 0.14
Nodes (9): Coordinate mapping, AvatarAccessoryGeometry, AvatarView, .accessoryOverlay, .avatarImage, .body, .resolvedAnchors, .underlyingImageSize (+1 more)

### Community 21 - "AccessorySlotRow"
Cohesion: 0.19
Nodes (11): AccessorySlotRow, .body, .currentID, .currentName, .slotName, PixelToggleStyle, SettingsSectionTitle, .body (+3 more)

### Community 22 - ".textColor"
Cohesion: 0.23
Nodes (6): PixelPanelStyle, hud, showroom, standard, wood, .panelTextColor

### Community 24 - "Role"
Cohesion: 0.20
Nodes (9): PixelFont, Role, body, caption, display, headline, label, number (+1 more)

### Community 25 - "PixelStatBar"
Cohesion: 0.16
Nodes (11): .gearCheck, PixelHillLayer, .body, .fill, .body, PixelStatBar, .body, .filledCount (+3 more)

### Community 26 - "AvatarAccessory"
Cohesion: 0.15
Nodes (3): AvatarAccessory, .placeholderSprite, AvatarAccessoryTests

### Community 27 - "View"
Cohesion: 0.18
Nodes (11): Kind, icon, primary, secondary, PixelButtonStyle, .background, .foreground, PixelIconButtonStyle (+3 more)

### Community 28 - "CodingKeys"
Cohesion: 0.11
Nodes (17): CodingKeys, co, feelsLike, grndLevel, humidity, no2, o3, oneHour (+9 more)

### Community 29 - "com.fasterxml.jackson.annotation.JsonIgnoreProperties"
Cohesion: 0.25
Nodes (6): Coord, CurrentBlock, MainInfo, OneCallResponse, WeatherInfo, WeatherResponse

### Community 30 - "AvatarPhotoStore"
Cohesion: 0.22
Nodes (3): Persistence, AvatarPhotoStore, .exists

### Community 33 - "AccessorySlot"
Cohesion: 0.21
Nodes (7): AccessorySlot, eyes, head, mouth, .selectedAccessoryIDs, .previewAccessories, .activeAccessories

### Community 34 - "DetailItem"
Cohesion: 0.27
Nodes (6): Comparable, DailyForecast, DetailItem, .id, HourlyForecast, WeatherDetailsResult

### Community 35 - "AvatarPhotoPickerView"
Cohesion: 0.20
Nodes (5): AvatarPhotoPickerView, .body, .preview, .statusMessage, PhotosUI

### Community 39 - "AirSample"
Cohesion: 0.39
Nodes (5): AirQualitySummary, AirComponents, AirMain, AirPollutionResponse, AirSample

### Community 40 - "PixelSprite"
Cohesion: 0.36
Nodes (3): PixelSprite, .body, .body

## Knowledge Gaps
- **147 isolated node(s):** `head`, `eyes`, `mouth`, `.placeholderSprite`, `PhotosUI` (+142 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 266 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **13 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeatherViewModel` connect `WeatherViewModel` to `AccessorySlot`, `DetailItem`, `AvatarPhotoPickerView`, `FaceAnchors`, `Units`, `WeatherService`, `Foundation`, `LocationService`, `.body`, `.setAvatarPhoto`, `PixelWeatherTheme`, `AccessorySlotRow`, `AvatarAccessory`, `View`, `AvatarPhotoStore`?**
  _High betweenness centrality (0.362) - this node is a cross-community bridge._
- **Why does `WeatherApp` connect `.body` to `App.java`?**
  _High betweenness centrality (0.218) - this node is a cross-community bridge._
- **Why does `App` connect `App.java` to `PreferencesService`, `.body`, `WeatherAPI.java`, `list`?**
  _High betweenness centrality (0.217) - this node is a cross-community bridge._
- **Are the 7 inferred relationships involving `PixelSpriteKind` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelSpriteKind` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `PixelWeatherTheme` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelWeatherTheme` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `WeatherViewModel` (e.g. with `ContentView` and `.body`) actually correct?**
  _`WeatherViewModel` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `RequestGate` (e.g. with `Avatar photo` and `Full weather details`) actually correct?**
  _`RequestGate` has 10 INFERRED edges - model-reasoned connections that need verification._