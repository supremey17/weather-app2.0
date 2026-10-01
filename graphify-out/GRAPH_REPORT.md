# Graph Report - weather-app2.0  (2026-10-01)

## Corpus Check
- 52 files · ~46,117 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 6 file(s) not represented in the graph (top: (none) 2, .xcconfig 1, .plist 1)

## Summary
- 524 nodes · 1084 edges · 22 communities (17 shown, 5 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 126 edges (avg confidence: 0.83)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `85b6e6a1`
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
- AvatarView.java
- Foundation
- LocationService
- WeatherDetailsView
- com.weatherapp:weather-app
- BodyPoseLandmarks
- .makeAvatar
- WeatherViewModel
- ContentView
- AvatarPhotoStore
- AvatarPhotoPickerView
- SwiftUI
- .isForeground

## God Nodes (most connected - your core abstractions)
1. `WeatherViewModel` - 30 edges
2. `RequestGate` - 25 edges
3. `CodingKeys` - 22 edges
4. `Units` - 22 edges
5. `PreferencesService` - 19 edges
6. `CitySuggester` - 17 edges
7. `Preferences` - 16 edges
8. `CitySuggestionLogicTests` - 16 edges
9. `WeatherDetailsTests` - 16 edges
10. `WeatherService` - 15 edges

## Surprising Connections (you probably didn't know these)
- `Full weather details` --references--> `RequestGate`  [INFERRED]
  ios/README.md → ios/WeatherApp/RequestGate.swift
- `Search autocomplete` --references--> `RequestGate`  [INFERRED]
  ios/README.md → ios/WeatherApp/RequestGate.swift
- `Avatar photo` --references--> `WeatherService`  [INFERRED]
  ios/README.md → ios/WeatherApp/WeatherService.swift
- `Avatar photo` --references--> `RequestGate`  [INFERRED]
  ios/README.md → ios/WeatherApp/RequestGate.swift
- `WeatherApp` --implements--> `App`  [EXTRACTED]
  ios/WeatherApp/WeatherApp.swift → src/main/java/com/weatherapp/App.java

## Import Cycles
- None detected.

## Communities (22 total, 5 thin omitted)

### Community 0 - "App.java"
Cohesion: 0.06
Nodes (6): App, ClothingAdvisor, PreferencesService, SavedCitiesWindow, SettingsWindow, CityNotFoundException

### Community 1 - "Preferences"
Cohesion: 0.17
Nodes (7): Preferences, .defaultUnits, .homeCity, .isAdviceEnabled, .isAvatarEnabled, .lastCity, .savedCities

### Community 2 - "CitySuggester"
Cohesion: 0.07
Nodes (10): CityCompleting, CitySuggester, CitySuggestion, .id, CitySuggestionLogic, MapKitCityCompleter, CitySuggesterTests, FakeCompleter (+2 more)

### Community 3 - "RequestGate"
Cohesion: 0.11
Nodes (13): API usage limits, Avatar photo, Java to Swift map, Run it, Search autocomplete, Tests, Weather App (iOS), RequestGate (+5 more)

### Community 4 - "CodingKeys"
Cohesion: 0.07
Nodes (36): AirComponents, AirMain, AirPollutionResponse, AirSample, Clouds, CodingKeys, co, feelsLike (+28 more)

### Community 5 - "com.fasterxml.jackson.annotation.JsonIgnoreProperties"
Cohesion: 0.11
Nodes (9): Coord, CurrentBlock, IpLocation, LocationService, MainInfo, OneCallResponse, WeatherInfo, WeatherResponse (+1 more)

### Community 6 - "Units"
Cohesion: 0.12
Nodes (15): AirQualitySummary, Comparable, DailyForecast, DetailItem, .id, HourlyForecast, WeatherDetails, WeatherDetailsResult (+7 more)

### Community 7 - "WeatherService"
Cohesion: 0.19
Nodes (6): WeatherError, badStatus, cityNotFound, missingAPIKey, rateLimited, WeatherService

### Community 9 - "Foundation"
Cohesion: 0.09
Nodes (11): CoreGraphics, CoreImage, CoreImage.CIFilterBuiltins, Foundation, BodyPoseDetector, ClothingAdvisor, Observation, Testing (+3 more)

### Community 10 - "LocationService"
Cohesion: 0.21
Nodes (4): CoreLocation, LocationError, denied, LocationService

### Community 11 - "WeatherDetailsView"
Cohesion: 0.35
Nodes (5): WeatherDetailsView, .body, .currentSection, .dailySection, .hourlySection

### Community 14 - "BodyPoseLandmarks"
Cohesion: 0.27
Nodes (3): BodyPoseLandmarks, PoseGuidance, PoseGuidanceTests

### Community 16 - "WeatherViewModel"
Cohesion: 0.17
Nodes (9): Full weather details, .body, .searchRow, SettingsView, .body, WeatherViewModel, .defaultUnits, .hasAvatarPhoto (+1 more)

### Community 17 - "ContentView"
Cohesion: 0.25
Nodes (5): ContentView, .adviceList, .suggestionList, WeatherApp, .body

### Community 18 - "AvatarPhotoStore"
Cohesion: 0.18
Nodes (3): AvatarPhotoStore, .exists, AvatarPhotoStoreTests

### Community 19 - "AvatarPhotoPickerView"
Cohesion: 0.22
Nodes (3): AvatarPhotoPickerView, .body, .preview

### Community 20 - "SwiftUI"
Cohesion: 0.17
Nodes (6): AvatarView, .body, SavedCitiesView, .body, PhotosUI, SwiftUI

## Knowledge Gaps
- **47 isolated node(s):** `PhotosUI`, `.preview`, `.exists`, `.body`, `MapKit` (+42 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 135 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **5 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeatherViewModel` connect `WeatherViewModel` to `Preferences`, `Units`, `WeatherService`, `Foundation`, `LocationService`, `ContentView`, `AvatarPhotoStore`, `AvatarPhotoPickerView`, `SwiftUI`?**
  _High betweenness centrality (0.416) - this node is a cross-community bridge._
- **Why does `ContentView` connect `ContentView` to `WeatherViewModel`, `CitySuggester`, `WeatherDetailsView`, `SwiftUI`?**
  _High betweenness centrality (0.325) - this node is a cross-community bridge._
- **Why does `App` connect `App.java` to `ContentView`, `com.fasterxml.jackson.annotation.JsonIgnoreProperties`?**
  _High betweenness centrality (0.317) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `WeatherViewModel` (e.g. with `ContentView` and `.body`) actually correct?**
  _`WeatherViewModel` has 4 INFERRED edges - model-reasoned connections that need verification._
- **Are the 10 inferred relationships involving `RequestGate` (e.g. with `Avatar photo` and `Full weather details`) actually correct?**
  _`RequestGate` has 10 INFERRED edges - model-reasoned connections that need verification._
- **What connects `PhotosUI`, `.preview`, `.exists` to the rest of the system?**
  _47 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `App.java` be split into smaller, more focused modules?**
  _Cohesion score 0.06271186440677966 - nodes in this community are weakly interconnected._