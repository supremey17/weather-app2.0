# Graph Report - weather-app2.0  (2026-10-05)

## Corpus Check
- 60 files · ~57,197 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 9 file(s) not represented in the graph (top: .ttf 3, (none) 2, .xcconfig 1)

## Summary
- 782 nodes · 1631 edges · 29 communities (27 shown, 2 thin omitted)
- Extraction: 87% EXTRACTED · 13% INFERRED · 0% AMBIGUOUS · INFERRED: 207 edges (avg confidence: 0.84)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `302f83bc`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- App.java
- Preferences
- CitySuggester
- RequestGate
- CodingKeys
- com.fasterxml.jackson.annotation.JsonIgnoreProperties
- Units
- WeatherService
- PixelSpriteKind
- Foundation
- LocationService
- View
- com.weatherapp:weather-app
- BodyPoseLandmarks
- AvatarImageProcessing
- WeatherViewModel
- .body
- AvatarPhotoStore
- PixelWeatherTheme
- FaceAnchors
- SwiftUI
- .textColor
- PixelPanel
- Role
- .fill
- AirQualitySection
- PixelButtonStyle
- Kind

## God Nodes (most connected - your core abstractions)
1. `PixelWeatherTheme` - 60 edges
2. `PixelSpriteKind` - 55 edges
3. `WeatherViewModel` - 36 edges
4. `RequestGate` - 25 edges
5. `PixelPanel` - 24 edges
6. `CodingKeys` - 22 edges
7. `Units` - 22 edges
8. `PixelSprite` - 20 edges
9. `Preferences` - 19 edges
10. `PreferencesService` - 19 edges

## Surprising Connections (you probably didn't know these)
- `Still to build` --references--> `PixelSprite`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/PixelSprites.swift
- `Coordinate mapping` --references--> `AvatarAccessoryGeometry`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarView.swift
- `Search autocomplete` --references--> `RequestGate`  [INFERRED]
  ios/README.md → ios/WeatherApp/RequestGate.swift
- `Avatar photo` --references--> `WeatherService`  [INFERRED]
  ios/README.md → ios/WeatherApp/WeatherService.swift
- `Persistence` --references--> `AvatarPhotoStore`  [INFERRED]
  ios/docs/avatar-accessories.md → ios/WeatherApp/AvatarPhotoStore.swift

## Import Cycles
- None detected.

## Communities (29 total, 2 thin omitted)

### Community 0 - "App.java"
Cohesion: 0.06
Nodes (8): WeatherApp, .body, App, ClothingAdvisor, PreferencesService, SavedCitiesWindow, SettingsWindow, CityNotFoundException

### Community 1 - "Preferences"
Cohesion: 0.15
Nodes (8): Preferences, .defaultUnits, .homeCity, .isAccessoriesEnabled, .isAdviceEnabled, .isAvatarEnabled, .lastCity, .savedCities

### Community 2 - "CitySuggester"
Cohesion: 0.07
Nodes (10): CityCompleting, CitySuggester, CitySuggestion, .id, CitySuggestionLogic, MapKitCityCompleter, CitySuggesterTests, FakeCompleter (+2 more)

### Community 3 - "RequestGate"
Cohesion: 0.11
Nodes (14): API usage limits, Avatar photo, Full weather details, Java to Swift map, Run it, Search autocomplete, Tests, Weather App (iOS) (+6 more)

### Community 4 - "CodingKeys"
Cohesion: 0.07
Nodes (36): AirComponents, AirMain, AirPollutionResponse, AirSample, Clouds, CodingKeys, co, feelsLike (+28 more)

### Community 5 - "com.fasterxml.jackson.annotation.JsonIgnoreProperties"
Cohesion: 0.08
Nodes (10): AvatarView, Coord, CurrentBlock, IpLocation, LocationService, MainInfo, OneCallResponse, WeatherInfo (+2 more)

### Community 6 - "Units"
Cohesion: 0.12
Nodes (15): AirQualitySummary, Comparable, DailyForecast, DetailItem, .id, HourlyForecast, WeatherDetails, WeatherDetailsResult (+7 more)

### Community 7 - "WeatherService"
Cohesion: 0.17
Nodes (6): WeatherError, badStatus, cityNotFound, missingAPIKey, rateLimited, WeatherService

### Community 8 - "PixelSpriteKind"
Cohesion: 0.04
Nodes (42): .body, PixelSpriteKind, accessoryCigarettePlaceholder, accessoryGlassesPlaceholder, accessoryHatPlaceholder, backpack, calendar, check (+34 more)

### Community 9 - "Foundation"
Cohesion: 0.05
Nodes (14): CoreGraphics, Foundation, ClothingAdvisor, AvatarBackgroundRemovalTests, contrastRatio(), PixelSpriteKindGridTests, PixelWeatherThemeContrastTests, PixelWeatherThemeTests (+6 more)

### Community 10 - "LocationService"
Cohesion: 0.19
Nodes (4): CoreLocation, LocationError, denied, LocationService

### Community 11 - "View"
Cohesion: 0.20
Nodes (16): PixelSprite, PixelStatBar, .filledCount, View, CurrentMetricsSection, .body, DailyForecastSection, .body (+8 more)

### Community 14 - "BodyPoseLandmarks"
Cohesion: 0.27
Nodes (3): BodyPoseLandmarks, PoseGuidance, PoseGuidanceTests

### Community 15 - "AvatarImageProcessing"
Cohesion: 0.11
Nodes (5): CoreImage, CoreImage.CIFilterBuiltins, AvatarBackgroundRemoval, AvatarImageProcessing, AvatarImageProcessingTests

### Community 16 - "WeatherViewModel"
Cohesion: 0.27
Nodes (8): .body, SavedCitiesView, .body, WeatherViewModel, .defaultUnits, .hasAvatarPhoto, .homeCity, .isCurrentCitySaved

### Community 17 - ".body"
Cohesion: 0.19
Nodes (9): CitySearchPanel, CitySuggestionPanel, .body, ContentView, .body, GarageCard, .body, .gearCheck (+1 more)

### Community 18 - "AvatarPhotoStore"
Cohesion: 0.05
Nodes (20): Art spec, Avatar accessories (scaffold), Default silhouette, Detection, Goal & privacy boundary, Open questions, Persistence, Slots (+12 more)

### Community 19 - "PixelWeatherTheme"
Cohesion: 0.10
Nodes (24): .body, PixelPalette, PixelParallaxScene, .shouldAnimate, PixelTextButtonStyle, PixelWeatherTheme, .accentColor, clearDay (+16 more)

### Community 20 - "FaceAnchors"
Cohesion: 0.07
Nodes (16): Coordinate mapping, AccessorySlot, eyes, head, mouth, AvatarAccessory, AvatarAccessoryGeometry, AvatarView (+8 more)

### Community 21 - "SwiftUI"
Cohesion: 0.18
Nodes (6): PixelToggleStyle, SettingsSectionTitle, .body, SettingsView, .body, SwiftUI

### Community 22 - ".textColor"
Cohesion: 0.23
Nodes (6): PixelPanelStyle, hud, showroom, standard, wood, .panelTextColor

### Community 23 - "PixelPanel"
Cohesion: 0.24
Nodes (4): PixelBevelShape, PixelPanel, .body, .borderColor

### Community 24 - "Role"
Cohesion: 0.20
Nodes (9): PixelFont, Role, body, caption, display, headline, label, number (+1 more)

### Community 25 - ".fill"
Cohesion: 0.29
Nodes (7): PixelHillLayer, .body, .fill, .body, .body, PixelWeatherParticles, .body

### Community 26 - "AirQualitySection"
Cohesion: 0.24
Nodes (5): AirQualitySection, .aqiLevel, .aqiNormalizedLevel, .body, .pollutants

### Community 27 - "PixelButtonStyle"
Cohesion: 0.36
Nodes (4): PixelButtonStyle, .background, .foreground, PixelIconButtonStyle

### Community 28 - "Kind"
Cohesion: 0.50
Nodes (4): Kind, icon, primary, secondary

## Knowledge Gaps
- **135 isolated node(s):** `head`, `eyes`, `mouth`, `PhotosUI`, `.statusMessage` (+130 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 247 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **2 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeatherViewModel` connect `WeatherViewModel` to `Preferences`, `Units`, `WeatherService`, `Foundation`, `LocationService`, `.body`, `AvatarPhotoStore`, `PixelWeatherTheme`, `FaceAnchors`, `SwiftUI`?**
  _High betweenness centrality (0.276) - this node is a cross-community bridge._
- **Why does `App` connect `App.java` to `com.fasterxml.jackson.annotation.JsonIgnoreProperties`?**
  _High betweenness centrality (0.227) - this node is a cross-community bridge._
- **Are the 6 inferred relationships involving `PixelWeatherTheme` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelWeatherTheme` has 6 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `PixelSpriteKind` (e.g. with `.body` and `.body`) actually correct?**
  _`PixelSpriteKind` has 7 INFERRED edges - model-reasoned connections that need verification._
- **Are the 5 inferred relationships involving `WeatherViewModel` (e.g. with `.body` and `.body`) actually correct?**
  _`WeatherViewModel` has 5 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `RequestGate` (e.g. with `Avatar photo` and `Full weather details`) actually correct?**
  _`RequestGate` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `head`, `eyes`, `mouth` to the rest of the system?**
  _135 weakly-connected nodes found - possible documentation gaps or missing edges._