# Graph Report - weather-app2.0  (2026-10-15)

## Corpus Check
- 123 files · ~194,949 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 13 file(s) not represented in the graph (top: (none) 3, .ttf 3, .plist 2)

## Summary
- 1295 nodes · 2985 edges · 70 communities (46 shown, 24 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 328 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `ae04dfd0`
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
- Detection
- PixelWeatherTheme
- PixelGrid
- .body
- PixelPanel
- AvatarPhotoStore
- PixelTemperatureReadout
- .setAvatarPhoto
- AvatarAccessory
- PixelWeatherTheme.swift
- CodingKeys
- com.fasterxml.jackson.annotation.JsonIgnoreProperties
- .make
- .isForeground
- .build
- AvatarPhotoPickerView
- PixelCloudLayer
- .makeModel
- .makeModel
- list
- WeatherParticleConfig
- AirSample
- .draw
- AvatarView.java
- .targetSize
- PixelSpriteKindSFSymbolMappingTests
- .visibleHours
- AccessorySlot
- AvatarPhotoStoreTests
- WeatherService
- WidgetSnapshot
- SnapshotEntry
- FaceAnchors
- PixelRainDropGauge
- LoadoutWidget
- .textColor
- .hud
- .rectangular
- ForecastItem
- PlayerHUDWidgetTests
- .point
- Weather Journey
- PixelPanelStyle
- WidgetSnapshotTests
- Avatar accessories (scaffold)
- .make
- WeatherError
- String
- WidgetTimeline.swift
- AvatarBackgroundRemoval.swift
- Kind
- WidgetSnapshotStore

## God Nodes (most connected - your core abstractions)
1. `PixelWeatherTheme` - 77 edges
2. `PixelSpriteKind` - 69 edges
3. `WeatherViewModel` - 47 edges
4. `WidgetSnapshot` - 38 edges
5. `CodingKeys` - 37 edges
6. `Units` - 30 edges
7. `PixelPanel` - 28 edges
8. `WeatherDetailsTests` - 28 edges
9. `PixelGrid` - 26 edges
10. `WeatherParticleConfig` - 25 edges

## Surprising Connections (you probably didn't know these)
- `Coordinate mapping` --references--> `AvatarAccessoryGeometry`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarView.swift
- `Persistence` --references--> `AvatarPhotoStore`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarPhotoStore.swift
- `Detection` --references--> `BodyPoseDetector`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/BodyPoseDetector.swift
- `Detection` --references--> `FaceAnchorDetector`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/FaceAnchorDetector.swift
- `Open questions` --references--> `FaceAnchorDetector`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/FaceAnchorDetector.swift

## Import Cycles
- None detected.

## Communities (70 total, 24 thin omitted)

### Community 0 - "App.java"
Cohesion: 0.12
Nodes (3): App, SettingsWindow, CityNotFoundException

### Community 1 - "Preferences"
Cohesion: 0.13
Nodes (9): Preferences, .defaultUnits, .homeCity, .isAccessoriesEnabled, .isAdviceEnabled, .isAvatarEnabled, .lastCity, .savedCities (+1 more)

### Community 2 - "CitySuggester"
Cohesion: 0.06
Nodes (14): CityCompleting, CitySuggester, CitySuggestion, .id, CitySuggestionLogic, MapKitCityCompleter, ContentView, .ambientClockActive (+6 more)

### Community 3 - "PixelBackground"
Cohesion: 0.17
Nodes (11): PixelBackground, .assetName, beach, cherryBlossom, .displayName, .id, mountains, ocean (+3 more)

### Community 4 - "WeatherModels.swift"
Cohesion: 0.19
Nodes (13): AirPollutionResponse, Clouds, Coord, CurrentBlock, MainInfo, OneCallResponse, OpenMeteoDaily, OpenMeteoHourly (+5 more)

### Community 5 - "WeatherAPI.java"
Cohesion: 0.20
Nodes (3): IpLocation, LocationService, WeatherAPI

### Community 6 - "Units"
Cohesion: 0.12
Nodes (14): Array, Comparable, DailyForecast, DetailItem, .id, HourlyForecast, WeatherDetails, Units (+6 more)

### Community 7 - "RequestGate"
Cohesion: 0.15
Nodes (6): RequestGate, FetchCounter, .count, RequestGateTests, TestClock, .now

### Community 8 - "PixelSpriteKind"
Cohesion: 0.04
Nodes (48): PixelSpriteKind, accessoryBeanie, accessoryCap, accessoryCigarette, accessoryLollipop, accessoryMonocle, accessoryPartyHat, accessoryPipe (+40 more)

### Community 9 - "Foundation"
Cohesion: 0.05
Nodes (16): CoreGraphics, Foundation, ClothingAdvisor, contrastRatio(), PixelSpriteKindGridTests, PixelWeatherThemeContrastTests, PixelWeatherThemeNightModifierTests, relativeLuminance() (+8 more)

### Community 10 - "LocationService"
Cohesion: 0.21
Nodes (4): CoreLocation, LocationError, denied, LocationService

### Community 11 - "View"
Cohesion: 0.13
Nodes (22): PixelSprite, SavedCitiesView, .body, AirQualitySection, .aqiLevel, .aqiNormalizedLevel, .body, .pollutants (+14 more)

### Community 14 - "BodyPoseLandmarks"
Cohesion: 0.27
Nodes (3): BodyPoseLandmarks, PoseGuidance, PoseGuidanceTests

### Community 17 - "WeatherViewModel"
Cohesion: 0.21
Nodes (5): WeatherViewModel, .defaultUnits, .hasAvatarPhoto, .homeCity, .isCurrentCitySaved

### Community 18 - "Detection"
Cohesion: 0.20
Nodes (5): Detection, Open questions, BodyPoseDetector, FaceAnchorDetector, Vision

### Community 19 - "PixelWeatherTheme"
Cohesion: 0.12
Nodes (21): PixelPalette, PixelWeatherTheme, .accentColor, .appliesNightModifier, clearDay, clearNight, cloudy, .horizonColor (+13 more)

### Community 20 - "PixelGrid"
Cohesion: 0.17
Nodes (9): Color, PixelBackgroundLayer, .base, .body, .weatherWash, PixelGrid, PixelSceneCanvas, .body (+1 more)

### Community 21 - ".body"
Cohesion: 0.17
Nodes (9): .body, GarageLoadoutSection, .avatarStage, .body, .gearCheck, WeatherHero, .body, .textColor (+1 more)

### Community 22 - "PixelPanel"
Cohesion: 0.10
Nodes (12): .body, PixelSearchBar, .body, .searchField, .theme, PixelSuggestionMenu, .body, PixelBevelShape (+4 more)

### Community 23 - "AvatarPhotoStore"
Cohesion: 0.19
Nodes (3): Persistence, AvatarPhotoStore, .exists

### Community 24 - "PixelTemperatureReadout"
Cohesion: 0.06
Nodes (26): PixelTemperatureReadout, .body, .colors, .readout, TemperatureBand, cold, .colors, freezing (+18 more)

### Community 26 - "AvatarAccessory"
Cohesion: 0.14
Nodes (3): AvatarAccessory, .sprite, AvatarAccessoryTests

### Community 27 - "PixelWeatherTheme.swift"
Cohesion: 0.19
Nodes (15): Color, PixelButtonStyle, .background, PixelHillLayer, .body, PixelIconButtonStyle, .fill, PixelParallaxScene (+7 more)

### Community 28 - "CodingKeys"
Cohesion: 0.07
Nodes (29): CodingKeys, co, daily, feelsLike, grndLevel, hourly, humidity, isDay (+21 more)

### Community 29 - "com.fasterxml.jackson.annotation.JsonIgnoreProperties"
Cohesion: 0.25
Nodes (6): Coord, CurrentBlock, MainInfo, OneCallResponse, WeatherInfo, WeatherResponse

### Community 33 - "AvatarPhotoPickerView"
Cohesion: 0.20
Nodes (4): AvatarPhotoPickerView, .preview, .statusMessage, PhotosUI

### Community 34 - "PixelCloudLayer"
Cohesion: 0.11
Nodes (12): Bolt, LightningSchedule, PixelCloudLayer, .body, .colors, PixelLightningBolt, .body, PixelSnowCap (+4 more)

### Community 38 - "WeatherParticleConfig"
Cohesion: 0.06
Nodes (25): PrecipitationIntensity, heavy, light, normal, EnvironmentValues, .weatherColliderStore, .weatherSnowCover, Kind (+17 more)

### Community 39 - "AirSample"
Cohesion: 0.57
Nodes (4): AirQualitySummary, AirComponents, AirMain, AirSample

### Community 44 - ".visibleHours"
Cohesion: 0.19
Nodes (5): QuestLogView, .body, QuestLogWidget, .body, QuestLogWidgetTests

### Community 45 - "AccessorySlot"
Cohesion: 0.19
Nodes (12): AccessorySlot, eyes, head, mouth, AccessorySlotRow, .body, .currentID, .currentName (+4 more)

### Community 48 - "WidgetSnapshot"
Cohesion: 0.21
Nodes (4): Hour, WidgetSnapshot, .unitsValue, .weatherTheme

### Community 49 - "SnapshotEntry"
Cohesion: 0.20
Nodes (3): .body, SnapshotEntry, SnapshotProvider

### Community 50 - "FaceAnchors"
Cohesion: 0.17
Nodes (7): AvatarView, .accessoryOverlay, .avatarImage, .body, .resolvedAnchors, .underlyingImageSize, FaceAnchors

### Community 51 - "PixelRainDropGauge"
Cohesion: 0.21
Nodes (6): PixelRainDropGauge, .body, .columns, .label, .rows, PixelRainDropGaugeTests

### Community 52 - "LoadoutWidget"
Cohesion: 0.26
Nodes (3): Item, LoadoutWidget, LoadoutWidgetTests

### Community 53 - ".textColor"
Cohesion: 0.21
Nodes (8): .foreground, .panelTextColor, BackdropRow, .body, PixelToggleStyle, SettingsSectionTitle, .body, .body

### Community 54 - ".hud"
Cohesion: 0.19
Nodes (4): HUDTemperature, PlayerHUDView, PlayerHUDWidget, .body

### Community 55 - ".rectangular"
Cohesion: 0.27
Nodes (4): LockScreenGaugesView, .body, LockScreenGaugesWidget, .body

### Community 56 - "ForecastItem"
Cohesion: 0.62
Nodes (5): ForecastCity, ForecastItem, ForecastMain, ForecastResponse, WeatherInfo

### Community 59 - "Weather Journey"
Cohesion: 0.20
Nodes (9): How it's built, Java → Swift map, Run it, Search autocomplete, Tests, The avatar, in more detail, Weather Journey, What it does (+1 more)

### Community 60 - "PixelPanelStyle"
Cohesion: 0.22
Nodes (7): PixelPanelStyle, hud, showroom, standard, wood, QuestTile, .body

### Community 62 - "Avatar accessories (scaffold)"
Cohesion: 0.29
Nodes (6): Art spec, Avatar accessories (scaffold), Default silhouette, Goal & privacy boundary, Slots, Still to build

### Community 64 - "WeatherError"
Cohesion: 0.29
Nodes (5): WeatherError, badStatus, cityNotFound, missingAPIKey, rateLimited

### Community 66 - "WidgetTimeline.swift"
Cohesion: 0.40
Nodes (4): .body, PressStartView, .body, View

### Community 68 - "Kind"
Cohesion: 0.50
Nodes (4): Kind, icon, primary, secondary

## Knowledge Gaps
- **199 isolated node(s):** `head`, `eyes`, `mouth`, `.sprite`, `PhotosUI` (+194 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 372 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **24 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeatherViewModel` connect `WeatherViewModel` to `Preferences`, `CitySuggester`, `PixelBackground`, `Units`, `Foundation`, `LocationService`, `View`, `PixelBackgroundTests`, `PixelWeatherTheme`, `.body`, `PixelPanel`, `AvatarPhotoStore`, `.setAvatarPhoto`, `AvatarAccessory`, `.build`, `AvatarPhotoPickerView`, `.makeModel`, `.makeModel`, `WeatherParticleConfig`, `AccessorySlot`, `WeatherService`, `FaceAnchors`, `.textColor`, `String`, `WidgetSnapshotStore`?**
  _High betweenness centrality (0.285) - this node is a cross-community bridge._
- **Why does `PixelWeatherTheme` connect `PixelWeatherTheme` to `String`, `PixelCloudLayer`, `WidgetTimeline.swift`, `WeatherParticleConfig`, `PixelSpriteKind`, `View`, `AccessorySlot`, `WidgetSnapshot`, `WeatherViewModel`, `PixelRainDropGauge`, `PixelGrid`, `.body`, `PixelPanel`, `.textColor`, `PixelWeatherTheme.swift`, `PixelPanelStyle`, `.make`?**
  _High betweenness centrality (0.166) - this node is a cross-community bridge._
- **Why does `Units` connect `Units` to `.build`, `Preferences`, `WeatherModels.swift`, `AccessorySlot`, `WeatherService`, `WidgetSnapshot`, `WeatherViewModel`, `.body`, `.hud`, `PixelTemperatureReadout`?**
  _High betweenness centrality (0.158) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `PixelWeatherTheme` (e.g. with `.body` and `.makeBody()`) actually correct?**
  _`PixelWeatherTheme` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 9 inferred relationships involving `PixelSpriteKind` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelSpriteKind` has 9 INFERRED edges - model-reasoned connections that need verification._
- **Are the 6 inferred relationships involving `WeatherViewModel` (e.g. with `ContentView` and `.body`) actually correct?**
  _`WeatherViewModel` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 2 inferred relationships involving `WidgetSnapshot` (e.g. with `.publishWidgetSnapshot()` and `.timelineHasAnEntryForNowEachFutureHourAndStaleness()`) actually correct?**
  _`WidgetSnapshot` has 2 INFERRED edges - model-reasoned connections that need verification._