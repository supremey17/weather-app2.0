# Graph Report - ios  (2026-10-01)

## Corpus Check
- 20 files · ~4,710 words
- Verdict: corpus is large enough that graph structure adds value.
- Unclassified: 5 file(s) not represented in the graph (top: (none) 1, .xcconfig 1, .plist 1)

## Summary
- 171 nodes · 276 edges · 23 communities (12 shown, 11 thin omitted)
- Extraction: 91% EXTRACTED · 9% INFERRED · 0% AMBIGUOUS · INFERRED: 25 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `1b6a775a`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

## Community Hubs (Navigation)
- WeatherViewModel
- LocationService
- WeatherModels.swift
- Preferences
- WeatherService
- AvatarView
- Units
- .advice
- Foundation
- Config/Secrets.xcconfig
- JavaFX App
- AvatarView.swift (ZStack of images)
- WeatherApp.xcodeproj
- LocationService.java (ip-api.com)
- Preferences.swift (UserDefaults)
- SavedCitiesView.swift (sheet, swipe to delete)
- SettingsView.swift (sheet)
- WeatherAPI.java
- Casual Avatar Sprite (casual.png)
- Coat Avatar Outfit Asset
- Hot Weather Avatar Asset (hot.png)
- Jacket.png (Avatar Outfit Sprite)
- RequestGate

## God Nodes (most connected - your core abstractions)
1. `WeatherViewModel` - 23 edges
2. `Preferences` - 16 edges
3. `Units` - 16 edges
4. `RequestGate` - 15 edges
5. `LocationService` - 12 edges
6. `WeatherService` - 12 edges
7. `WeatherResponse` - 9 edges
8. `WeatherError` - 8 edges
9. `ContentView` - 7 edges
10. `.body` - 7 edges

## Surprising Connections (you probably didn't know these)
- `.body` --calls--> `ContentView`  [INFERRED]
  WeatherApp/WeatherApp.swift → WeatherApp/ContentView.swift
- `.body` --calls--> `AvatarView`  [INFERRED]
  WeatherApp/ContentView.swift → WeatherApp/AvatarView.swift
- `WeatherViewModel` --calls--> `ClothingAdvisor`  [INFERRED]
  WeatherApp/WeatherViewModel.swift → WeatherApp/ClothingAdvisor.swift
- `WeatherViewModel` --calls--> `LocationService`  [INFERRED]
  WeatherApp/WeatherViewModel.swift → WeatherApp/LocationService.swift
- `ContentView` --calls--> `WeatherViewModel`  [INFERRED]
  WeatherApp/ContentView.swift → WeatherApp/WeatherViewModel.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **App.java Ported to Three SwiftUI Files** — readme_app_java, weatherapp_weatherapp, weatherapp_contentview, weatherapp_weatherviewmodel [EXTRACTED 1.00]
- **UV Index Feature Depends on One Call API 4.0 / OpenWeatherMap Subscription** — readme_uv_index_feature, readme_one_call_api_4_0, readme_openweathermap_api [EXTRACTED 1.00]
- **App Setup and Run Procedure** — readme_config_secrets_example_xcconfig, readme_config_secrets_xcconfig, readme_weatherapp_xcodeproj, readme_openweathermap_api [INFERRED 0.75]

## Communities (23 total, 11 thin omitted)

### Community 0 - "WeatherViewModel"
Cohesion: 0.17
Nodes (11): ContentView, .adviceList, .body, .searchRow, SavedCitiesView, .body, SettingsView, .body (+3 more)

### Community 1 - "LocationService"
Cohesion: 0.19
Nodes (4): CoreLocation, LocationError, denied, LocationService

### Community 2 - "WeatherModels.swift"
Cohesion: 0.21
Nodes (11): Java records (WeatherResponse, MainInfo, ...), CodingKeys, feelsLike, humidity, temp, Coord, CurrentBlock, MainInfo (+3 more)

### Community 3 - "Preferences"
Cohesion: 0.16
Nodes (7): Preferences, .defaultUnits, .homeCity, .isAdviceEnabled, .isAvatarEnabled, .lastCity, .savedCities

### Community 4 - "WeatherService"
Cohesion: 0.24
Nodes (6): WeatherError, badStatus, cityNotFound, missingAPIKey, rateLimited, WeatherService

### Community 5 - "AvatarView"
Cohesion: 0.17
Nodes (7): App.java, SwiftUI, UIKit, AvatarView, .body, WeatherApp, .body

### Community 6 - "Units"
Cohesion: 0.22
Nodes (7): Units, .id, imperial, .label, metric, .symbol, .toggled

### Community 8 - "Foundation"
Cohesion: 0.25
Nodes (3): Foundation, Observation, ClothingAdvisor.java

### Community 9 - "Config/Secrets.xcconfig"
Cohesion: 0.40
Nodes (4): Config/Secrets.example.xcconfig, Config/Secrets.xcconfig, One Call API 4.0, OpenWeatherMap API key/subscription

### Community 10 - "JavaFX App"
Cohesion: 0.50
Nodes (3): JavaFX App, src/main/java, Weather App (iOS)

### Community 11 - "AvatarView.swift (ZStack of images)"
Cohesion: 0.67
Nodes (3): Assets.xcassets, AvatarView.java, AvatarView.swift (ZStack of images)

### Community 12 - "WeatherApp.xcodeproj"
Cohesion: 0.67
Nodes (3): iOS 17, WeatherApp.xcodeproj, Xcode 16

## Knowledge Gaps
- **45 isolated node(s):** `UIKit`, `.adviceList`, `denied`, `.lastCity`, `.homeCity` (+40 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 65 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **11 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeatherViewModel` connect `WeatherViewModel` to `LocationService`, `Preferences`, `WeatherService`, `Units`, `.advice`, `Foundation`?**
  _High betweenness centrality (0.369) - this node is a cross-community bridge._
- **Why does `Units` connect `Units` to `WeatherViewModel`, `WeatherModels.swift`, `Preferences`, `WeatherService`?**
  _High betweenness centrality (0.164) - this node is a cross-community bridge._
- **Why does `WeatherService` connect `WeatherService` to `Foundation`, `WeatherViewModel`, `RequestGate`?**
  _High betweenness centrality (0.142) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `WeatherViewModel` (e.g. with `ContentView` and `.body`) actually correct?**
  _`WeatherViewModel` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `UIKit`, `.adviceList`, `denied` to the rest of the system?**
  _45 weakly-connected nodes found - possible documentation gaps or missing edges._