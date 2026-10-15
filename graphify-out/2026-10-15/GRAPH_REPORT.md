# Graph Report - weather-app2.0  (2026-10-14)

## Corpus Check
- 106 files · ~184,842 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 9 file(s) not represented in the graph (top: .ttf 3, (none) 2, .xcconfig 1)

## Summary
- 996 nodes · 2203 edges · 49 communities (30 shown, 19 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 249 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `8738c66a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- App.java
- Preferences
- CitySuggester
- PixelBackground
- WeatherModels.swift
- WeatherAPI.java
- Units
- RequestGate
- PixelSpriteKind
- Foundation
- LocationService
- View
- com.weatherapp:weather-app
- BodyPoseLandmarks
- PixelBackgroundTests
- PreferencesService
- WeatherViewModel
- Avatar accessories (scaffold)
- PixelWeatherTheme
- PixelGrid
- .textColor
- PixelPanel
- AvatarPhotoStore
- Role
- AvatarImageProcessing
- AvatarAccessory
- PixelWeatherTheme.swift
- CodingKeys
- com.fasterxml.jackson.annotation.JsonIgnoreProperties
- .make
- .isForeground
- WeatherDetailsTests
- AvatarPhotoPickerView
- DetailItem
- .makeModel
- .makeModel
- list
- WeatherParticleConfig
- AirSample
- .draw
- AvatarView.java
- AvatarImageProcessingTests
- PixelSpriteKindSFSymbolMappingTests
- .removeSavedCities
- AccessorySlotRow
- AvatarPhotoStoreTests
- WeatherApp

## God Nodes (most connected - your core abstractions)
1. `PixelWeatherTheme` - 68 edges
2. `PixelSpriteKind` - 64 edges
3. `WeatherViewModel` - 45 edges
4. `PixelPanel` - 27 edges
5. `PixelGrid` - 26 edges
6. `RequestGate` - 25 edges
7. `Preferences` - 24 edges
8. `AvatarAccessory` - 22 edges
9. `PixelBackground` - 22 edges
10. `CodingKeys` - 22 edges

## Surprising Connections (you probably didn't know these)
- `Coordinate mapping` --references--> `AvatarAccessoryGeometry`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarView.swift
- `Search autocomplete` --references--> `RequestGate`  [INFERRED]
  ios/README.md → ios/WeatherApp/RequestGate.swift
- `Persistence` --references--> `AvatarPhotoStore`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarPhotoStore.swift
- `Detection` --references--> `BodyPoseDetector`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/BodyPoseDetector.swift
- `.body` --calls--> `ContentView`  [INFERRED]
  ios/WeatherApp/WeatherApp.swift → ios/WeatherApp/ContentView.swift

## Import Cycles
- None detected.

## Communities (49 total, 19 thin omitted)

### Community 0 - "App.java"
Cohesion: 0.12
Nodes (3): App, SettingsWindow, CityNotFoundException

### Community 1 - "Preferences"
Cohesion: 0.18
Nodes (8): Preferences, .defaultUnits, .homeCity, .isAccessoriesEnabled, .isAdviceEnabled, .isAvatarEnabled, .lastCity, .selectedBackground

### Community 2 - "CitySuggester"
Cohesion: 0.06
Nodes (13): CityCompleting, CitySuggester, CitySuggestion, .id, CitySuggestionLogic, MapKitCityCompleter, ContentView, .ambientClockActive (+5 more)

### Community 3 - "PixelBackground"
Cohesion: 0.17
Nodes (11): PixelBackground, .assetName, beach, cherryBlossom, .displayName, .id, mountains, ocean (+3 more)

### Community 4 - "WeatherModels.swift"
Cohesion: 0.22
Nodes (14): Clouds, Coord, CurrentBlock, ForecastCity, ForecastItem, ForecastMain, ForecastResponse, MainInfo (+6 more)

### Community 5 - "WeatherAPI.java"
Cohesion: 0.20
Nodes (3): IpLocation, LocationService, WeatherAPI

### Community 6 - "Units"
Cohesion: 0.20
Nodes (8): WeatherDetails, Units, .id, imperial, .label, metric, .symbol, .toggled

### Community 7 - "RequestGate"
Cohesion: 0.07
Nodes (20): API usage limits, Avatar photo, Full weather details, Java to Swift map, Run it, Search autocomplete, Tests, Weather App (iOS) (+12 more)

### Community 8 - "PixelSpriteKind"
Cohesion: 0.04
Nodes (48): PixelSpriteKind, accessoryBeanie, accessoryCap, accessoryCigarette, accessoryLollipop, accessoryMonocle, accessoryPartyHat, accessoryPipe (+40 more)

### Community 9 - "Foundation"
Cohesion: 0.06
Nodes (15): CoreGraphics, CoreImage, CoreImage.CIFilterBuiltins, Foundation, ClothingAdvisor, contrastRatio(), PixelSpriteKindGridTests, PixelWeatherThemeContrastTests (+7 more)

### Community 10 - "LocationService"
Cohesion: 0.21
Nodes (4): CoreLocation, LocationError, denied, LocationService

### Community 11 - "View"
Cohesion: 0.15
Nodes (18): PixelSprite, AirQualitySection, .aqiLevel, .aqiNormalizedLevel, .body, .pollutants, CurrentMetricsSection, .body (+10 more)

### Community 14 - "BodyPoseLandmarks"
Cohesion: 0.27
Nodes (3): BodyPoseLandmarks, PoseGuidance, PoseGuidanceTests

### Community 17 - "WeatherViewModel"
Cohesion: 0.11
Nodes (18): .body, PixelSearchBar, .body, SavedCitiesView, .body, BackdropRow, PixelToggleStyle, SettingsSectionTitle (+10 more)

### Community 18 - "Avatar accessories (scaffold)"
Cohesion: 0.12
Nodes (11): Art spec, Avatar accessories (scaffold), Default silhouette, Detection, Goal & privacy boundary, Open questions, Slots, Still to build (+3 more)

### Community 19 - "PixelWeatherTheme"
Cohesion: 0.10
Nodes (24): .body, PixelSuggestionMenu, .body, PixelPalette, PixelWeatherTheme, .accentColor, .appliesNightModifier, clearDay (+16 more)

### Community 20 - "PixelGrid"
Cohesion: 0.17
Nodes (9): Color, PixelBackgroundLayer, .base, .body, .weatherWash, PixelGrid, PixelSceneCanvas, .body (+1 more)

### Community 21 - ".textColor"
Cohesion: 0.13
Nodes (11): GarageCard, .avatarStage, .body, .gearCheck, WeatherHero, .foreground, .fill, PixelStatBar (+3 more)

### Community 22 - "PixelPanel"
Cohesion: 0.13
Nodes (10): PixelBevelShape, PixelPanel, .body, .borderColor, PixelPanelStyle, hud, showroom, standard (+2 more)

### Community 23 - "AvatarPhotoStore"
Cohesion: 0.18
Nodes (3): Persistence, AvatarPhotoStore, .exists

### Community 24 - "Role"
Cohesion: 0.20
Nodes (9): PixelFont, Role, body, caption, display, headline, label, number (+1 more)

### Community 26 - "AvatarAccessory"
Cohesion: 0.06
Nodes (19): Coordinate mapping, AccessorySlot, eyes, head, mouth, AvatarAccessory, .sprite, AvatarAccessoryGeometry (+11 more)

### Community 27 - "PixelWeatherTheme.swift"
Cohesion: 0.16
Nodes (15): Color, Kind, icon, primary, secondary, PixelButtonStyle, .background, PixelHillLayer (+7 more)

### Community 28 - "CodingKeys"
Cohesion: 0.11
Nodes (17): CodingKeys, co, feelsLike, grndLevel, humidity, no2, o3, oneHour (+9 more)

### Community 29 - "com.fasterxml.jackson.annotation.JsonIgnoreProperties"
Cohesion: 0.25
Nodes (6): Coord, CurrentBlock, MainInfo, OneCallResponse, WeatherInfo, WeatherResponse

### Community 33 - "AvatarPhotoPickerView"
Cohesion: 0.20
Nodes (5): AvatarPhotoPickerView, .body, .preview, .statusMessage, PhotosUI

### Community 34 - "DetailItem"
Cohesion: 0.27
Nodes (6): Comparable, DailyForecast, DetailItem, .id, HourlyForecast, WeatherDetailsResult

### Community 38 - "WeatherParticleConfig"
Cohesion: 0.07
Nodes (22): PrecipitationIntensity, heavy, light, normal, EnvironmentValues, .weatherColliderStore, Kind, rain (+14 more)

### Community 39 - "AirSample"
Cohesion: 0.39
Nodes (5): AirQualitySummary, AirComponents, AirMain, AirPollutionResponse, AirSample

### Community 45 - "AccessorySlotRow"
Cohesion: 0.38
Nodes (5): AccessorySlotRow, .body, .currentID, .currentName, .slotName

## Knowledge Gaps
- **168 isolated node(s):** `head`, `eyes`, `mouth`, `.sprite`, `PhotosUI` (+163 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 305 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **19 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeatherViewModel` connect `WeatherViewModel` to `AvatarPhotoPickerView`, `CitySuggester`, `PixelBackground`, `Preferences`, `DetailItem`, `WeatherParticleConfig`, `Units`, `RequestGate`, `Foundation`, `LocationService`, `.makeModel`, `.removeSavedCities`, `.makeModel`, `PixelBackgroundTests`, `PixelWeatherTheme`, `AvatarPhotoStore`, `AvatarAccessory`?**
  _High betweenness centrality (0.343) - this node is a cross-community bridge._
- **Why does `PixelWeatherTheme` connect `PixelWeatherTheme` to `WeatherParticleConfig`, `PixelSpriteKind`, `View`, `AccessorySlotRow`, `WeatherViewModel`, `PixelGrid`, `.textColor`, `PixelPanel`, `AvatarAccessory`, `PixelWeatherTheme.swift`?**
  _High betweenness centrality (0.191) - this node is a cross-community bridge._
- **Why does `WeatherApp` connect `WeatherApp` to `App.java`?**
  _High betweenness centrality (0.184) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `PixelWeatherTheme` (e.g. with `.body` and `.makeBody()`) actually correct?**
  _`PixelWeatherTheme` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PixelSpriteKind` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelSpriteKind` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `WeatherViewModel` (e.g. with `ContentView` and `.body`) actually correct?**
  _`WeatherViewModel` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 15 inferred relationships involving `PixelPanel` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelPanel` has 15 INFERRED edges - model-reasoned connections that need verification._