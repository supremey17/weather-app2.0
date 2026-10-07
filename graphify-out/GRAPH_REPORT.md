# Graph Report - weather-app2.0  (2026-10-07)

## Corpus Check
- 120 files · ~68,451 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 9 file(s) not represented in the graph (top: .ttf 3, (none) 2, .xcconfig 1)

## Summary
- 977 nodes · 2110 edges · 43 communities (31 shown, 12 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 252 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `e5fb1b17`
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
- PixelSprite
- com.weatherapp:weather-app
- BodyPoseLandmarks
- PixelBackgroundTests
- PreferencesService
- WeatherViewModel
- AvatarPhotoStore
- PixelWeatherTheme
- .textColor
- View
- PixelPanel
- PixelBevelShape
- Role
- PixelStatBar
- AvatarAccessory
- PixelWeatherTheme.swift
- CodingKeys
- com.fasterxml.jackson.annotation.JsonIgnoreProperties
- .make
- AvatarImageProcessing
- WeatherDetailsTests
- .advice
- DetailItem
- .makeModel
- .makeModel
- list
- WeatherParticleConfig
- AirSample
- Color
- AvatarView.java
- PixelSpriteKindSFSymbolMappingTests

## God Nodes (most connected - your core abstractions)
1. `PixelWeatherTheme` - 67 edges
2. `PixelSpriteKind` - 63 edges
3. `WeatherViewModel` - 45 edges
4. `PixelPanel` - 27 edges
5. `RequestGate` - 25 edges
6. `Preferences` - 24 edges
7. `PixelBackground` - 23 edges
8. `AvatarAccessory` - 22 edges
9. `CodingKeys` - 22 edges
10. `Units` - 22 edges

## Surprising Connections (you probably didn't know these)
- `Still to build` --references--> `PixelSprite`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/PixelSprites.swift
- `Coordinate mapping` --references--> `AvatarAccessoryGeometry`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarView.swift
- `Search autocomplete` --references--> `RequestGate`  [INFERRED]
  ios/README.md → ios/WeatherApp/RequestGate.swift
- `Persistence` --references--> `AvatarPhotoStore`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarPhotoStore.swift
- `Detection` --references--> `BodyPoseDetector`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/BodyPoseDetector.swift

## Import Cycles
- None detected.

## Communities (43 total, 12 thin omitted)

### Community 0 - "App.java"
Cohesion: 0.12
Nodes (3): App, SettingsWindow, CityNotFoundException

### Community 1 - "Preferences"
Cohesion: 0.13
Nodes (9): Preferences, .defaultUnits, .homeCity, .isAccessoriesEnabled, .isAdviceEnabled, .isAvatarEnabled, .lastCity, .savedCities (+1 more)

### Community 2 - "CitySuggester"
Cohesion: 0.06
Nodes (10): CityCompleting, CitySuggester, CitySuggestion, .id, CitySuggestionLogic, MapKitCityCompleter, CitySuggesterTests, FakeCompleter (+2 more)

### Community 3 - "PixelBackground"
Cohesion: 0.15
Nodes (12): PixelBackground, .assetName, beach, cherryBlossom, .displayName, .id, .isAnimated, mountains (+4 more)

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
Nodes (48): PixelSpriteKind, accessoryBeaniePlaceholder, accessoryCapPlaceholder, accessoryCigarettePlaceholder, accessoryGlassesPlaceholder, accessoryHatPlaceholder, accessoryLollipopPlaceholder, accessoryMonoclePlaceholder (+40 more)

### Community 9 - "Foundation"
Cohesion: 0.07
Nodes (15): CoreGraphics, Foundation, WeatherApp, .body, contrastRatio(), PixelSpriteKindGridTests, PixelWeatherThemeContrastTests, PixelWeatherThemeNightModifierTests (+7 more)

### Community 10 - "LocationService"
Cohesion: 0.21
Nodes (4): CoreLocation, LocationError, denied, LocationService

### Community 11 - "PixelSprite"
Cohesion: 0.14
Nodes (17): PixelSprite, AirQualitySection, .aqiLevel, .aqiNormalizedLevel, .body, .pollutants, CurrentMetricsSection, .body (+9 more)

### Community 14 - "BodyPoseLandmarks"
Cohesion: 0.27
Nodes (3): BodyPoseLandmarks, PoseGuidance, PoseGuidanceTests

### Community 17 - "WeatherViewModel"
Cohesion: 0.17
Nodes (9): PixelSearchBar, .body, SavedCitiesView, .body, WeatherViewModel, .defaultUnits, .hasAvatarPhoto, .homeCity (+1 more)

### Community 18 - "AvatarPhotoStore"
Cohesion: 0.06
Nodes (19): Art spec, Avatar accessories (scaffold), Default silhouette, Detection, Goal & privacy boundary, Open questions, Persistence, Slots (+11 more)

### Community 19 - "PixelWeatherTheme"
Cohesion: 0.10
Nodes (20): PixelSuggestionMenu, .body, PixelPalette, PixelWeatherTheme, .accentColor, .appliesNightModifier, clearDay, clearNight (+12 more)

### Community 20 - ".textColor"
Cohesion: 0.33
Nodes (3): .avatarStage, .foreground, .panelTextColor

### Community 21 - "View"
Cohesion: 0.07
Nodes (40): ContentView, .body, GarageCard, WeatherHero, BeachScene, .body, .palmTree, .shouldAnimate (+32 more)

### Community 22 - "PixelPanel"
Cohesion: 0.19
Nodes (8): PixelPanel, .borderColor, PixelPanelStyle, hud, showroom, standard, wood, PixelPanelTranslucencyTests

### Community 23 - "PixelBevelShape"
Cohesion: 0.17
Nodes (9): .body, .body, PixelBevelShape, PixelHillLayer, .body, .body, .fill, .body (+1 more)

### Community 24 - "Role"
Cohesion: 0.20
Nodes (9): PixelFont, Role, body, caption, display, headline, label, number (+1 more)

### Community 25 - "PixelStatBar"
Cohesion: 0.24
Nodes (4): .gearCheck, PixelStatBar, .filledCount, PixelWeatherThemeTests

### Community 26 - "AvatarAccessory"
Cohesion: 0.06
Nodes (19): Coordinate mapping, AccessorySlot, eyes, head, mouth, AvatarAccessory, .placeholderSprite, AvatarAccessoryGeometry (+11 more)

### Community 27 - "PixelWeatherTheme.swift"
Cohesion: 0.24
Nodes (9): Kind, icon, primary, secondary, PixelButtonStyle, .background, PixelIconButtonStyle, PixelTextButtonStyle (+1 more)

### Community 28 - "CodingKeys"
Cohesion: 0.11
Nodes (17): CodingKeys, co, feelsLike, grndLevel, humidity, no2, o3, oneHour (+9 more)

### Community 29 - "com.fasterxml.jackson.annotation.JsonIgnoreProperties"
Cohesion: 0.25
Nodes (6): Coord, CurrentBlock, MainInfo, OneCallResponse, WeatherInfo, WeatherResponse

### Community 31 - "AvatarImageProcessing"
Cohesion: 0.08
Nodes (6): CoreImage, CoreImage.CIFilterBuiltins, AvatarBackgroundRemoval, AvatarImageProcessing, AvatarBackgroundRemovalTests, AvatarImageProcessingTests

### Community 34 - "DetailItem"
Cohesion: 0.27
Nodes (6): Comparable, DailyForecast, DetailItem, .id, HourlyForecast, WeatherDetailsResult

### Community 38 - "WeatherParticleConfig"
Cohesion: 0.07
Nodes (23): .ambientClockActive, PrecipitationIntensity, heavy, light, normal, EnvironmentValues, .weatherColliderStore, Kind (+15 more)

### Community 39 - "AirSample"
Cohesion: 0.39
Nodes (5): AirQualitySummary, AirComponents, AirMain, AirPollutionResponse, AirSample

### Community 40 - "Color"
Cohesion: 0.18
Nodes (10): .body, .body, .base, .body, Color, PixelParallaxScene, .shouldAnimate, .skyColor (+2 more)

## Knowledge Gaps
- **177 isolated node(s):** `head`, `eyes`, `mouth`, `.placeholderSprite`, `PhotosUI` (+172 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 309 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **12 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeatherViewModel` connect `WeatherViewModel` to `.advice`, `Preferences`, `PixelBackground`, `DetailItem`, `.makeModel`, `WeatherParticleConfig`, `Units`, `RequestGate`, `Foundation`, `LocationService`, `.makeModel`, `PixelBackgroundTests`, `AvatarPhotoStore`, `PixelWeatherTheme`, `View`, `AvatarAccessory`?**
  _High betweenness centrality (0.339) - this node is a cross-community bridge._
- **Why does `WeatherApp` connect `Foundation` to `App.java`?**
  _High betweenness centrality (0.187) - this node is a cross-community bridge._
- **Why does `App` connect `App.java` to `PreferencesService`, `Foundation`, `WeatherAPI.java`, `list`?**
  _High betweenness centrality (0.186) - this node is a cross-community bridge._
- **Are the 5 inferred relationships involving `PixelWeatherTheme` (e.g. with `.body` and `.makeBody()`) actually correct?**
  _`PixelWeatherTheme` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PixelSpriteKind` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelSpriteKind` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `WeatherViewModel` (e.g. with `ContentView` and `.body`) actually correct?**
  _`WeatherViewModel` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 15 inferred relationships involving `PixelPanel` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelPanel` has 15 INFERRED edges - model-reasoned connections that need verification._