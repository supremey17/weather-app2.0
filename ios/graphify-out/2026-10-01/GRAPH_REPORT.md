# Graph Report - ios  (2026-10-01)

## Corpus Check
- Corpus is ~4,043 words - fits in a single context window. You may not need a graph.

## Summary
- 157 nodes · 248 edges · 22 communities (12 shown, 10 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 24 edges (avg confidence: 0.82)
- Token cost: 134,623 input · 0 output

## Community Hubs (Navigation)
- Main Screen UI
- Location Services
- Weather API Models
- User Preferences Storage
- Weather Networking
- App Entry & Avatar Rendering
- Units Enum
- Clothing Advisor Logic
- Swift File Imports
- UV Index & API Key Setup
- Java-to-Swift Port Overview
- Avatar Asset Catalog
- Xcode Project Requirements
- Location Service Port (Java->Swift)
- Preferences Port (Java->Swift)
- Saved Cities Port (Java->Swift)
- Settings Port (Java->Swift)
- Weather API Port (Java->Swift)
- Casual Avatar Sprite
- Coat Outfit Asset
- Hot Weather Outfit Asset
- Jacket Outfit Asset

## God Nodes (most connected - your core abstractions)
1. `WeatherViewModel` - 23 edges
2. `Preferences` - 16 edges
3. `Units` - 16 edges
4. `LocationService` - 12 edges
5. `WeatherService` - 10 edges
6. `WeatherResponse` - 9 edges
7. `ContentView` - 7 edges
8. `.body` - 7 edges
9. `WeatherError` - 7 edges
10. `AvatarView` - 6 edges

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
- **App Setup and Run Procedure** — readme_config_secrets_example_xcconfig, readme_config_secrets_xcconfig, readme_weatherapp_xcodeproj, readme_openweathermap_api [INFERRED 0.75]
- **App.java Ported to Three SwiftUI Files** — readme_app_java, weatherapp_weatherapp, weatherapp_contentview, weatherapp_weatherviewmodel [EXTRACTED 1.00]
- **UV Index Feature Depends on One Call API 4.0 / OpenWeatherMap Subscription** — readme_uv_index_feature, readme_one_call_api_4_0, readme_openweathermap_api [EXTRACTED 1.00]

## Communities (22 total, 10 thin omitted)

### Community 0 - "Main Screen UI"
Cohesion: 0.20
Nodes (10): ContentView, .adviceList, .body, .searchRow, SavedCitiesView, SettingsView, .body, WeatherViewModel (+2 more)

### Community 1 - "Location Services"
Cohesion: 0.19
Nodes (4): CoreLocation, LocationError, denied, LocationService

### Community 2 - "Weather API Models"
Cohesion: 0.21
Nodes (11): Java records (WeatherResponse, MainInfo, ...), CodingKeys, feelsLike, humidity, temp, Coord, CurrentBlock, MainInfo (+3 more)

### Community 3 - "User Preferences Storage"
Cohesion: 0.15
Nodes (8): Preferences, .defaultUnits, .homeCity, .isAdviceEnabled, .isAvatarEnabled, .lastCity, .savedCities, .body

### Community 4 - "Weather Networking"
Cohesion: 0.21
Nodes (5): WeatherError, badStatus, cityNotFound, missingAPIKey, WeatherService

### Community 5 - "App Entry & Avatar Rendering"
Cohesion: 0.15
Nodes (7): App.java, SwiftUI, UIKit, AvatarView, .body, WeatherApp, .body

### Community 6 - "Units Enum"
Cohesion: 0.22
Nodes (7): Units, .id, imperial, .label, metric, .symbol, .toggled

### Community 8 - "Swift File Imports"
Cohesion: 0.29
Nodes (3): Foundation, Observation, ClothingAdvisor.java

### Community 9 - "UV Index & API Key Setup"
Cohesion: 0.40
Nodes (4): Config/Secrets.example.xcconfig, Config/Secrets.xcconfig, One Call API 4.0, OpenWeatherMap API key/subscription

### Community 10 - "Java-to-Swift Port Overview"
Cohesion: 0.50
Nodes (3): JavaFX App, src/main/java, Weather App (iOS)

### Community 11 - "Avatar Asset Catalog"
Cohesion: 0.67
Nodes (3): Assets.xcassets, AvatarView.java, AvatarView.swift (ZStack of images)

### Community 12 - "Xcode Project Requirements"
Cohesion: 0.67
Nodes (3): iOS 17, WeatherApp.xcodeproj, Xcode 16

## Knowledge Gaps
- **44 isolated node(s):** `UIKit`, `.adviceList`, `denied`, `.lastCity`, `.homeCity` (+39 more)
  These have ≤1 connection - possible missing edges or undocumented components. (Counts symbols only; 61 node(s) total have ≤1 connection when file, concept and rationale nodes are included.)
- **10 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `WeatherViewModel` connect `Main Screen UI` to `Location Services`, `User Preferences Storage`, `Weather Networking`, `Units Enum`, `Clothing Advisor Logic`, `Swift File Imports`?**
  _High betweenness centrality (0.362) - this node is a cross-community bridge._
- **Why does `Units` connect `Units Enum` to `Main Screen UI`, `Weather API Models`, `User Preferences Storage`, `Weather Networking`?**
  _High betweenness centrality (0.181) - this node is a cross-community bridge._
- **Why does `LocationService` connect `Location Services` to `Main Screen UI`?**
  _High betweenness centrality (0.127) - this node is a cross-community bridge._
- **Are the 4 inferred relationships involving `WeatherViewModel` (e.g. with `ContentView` and `.body`) actually correct?**
  _`WeatherViewModel` has 4 INFERRED edges - model-reasoned connections that need verification._
- **What connects `UIKit`, `.adviceList`, `denied` to the rest of the system?**
  _44 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `User Preferences Storage` be split into smaller, more focused modules?**
  _Cohesion score 0.14705882352941177 - nodes in this community are weakly interconnected._