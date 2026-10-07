import SwiftUI

struct ContentView: View {
    @State private var model = WeatherViewModel()
    @State private var showingSettings = false
    @State private var showingCities = false
    @State private var showingAvatarPhoto = false
    @State private var suggester = CitySuggester()
    @FocusState private var cityFieldFocused: Bool

    /// Shared tick for every stepped pixel animation on this page (hero scene, full-page weather
    /// particles, animated backdrops) — one clock instead of several independent `TimelineView`s.
    @State private var clock = PixelClock()
    /// Plain (non-observed) stores the particle layer polls directly on each tick; writing to
    /// these must never trigger a SwiftUI re-render, which is why they're `@State`-held reference
    /// types rather than `@Observable`.
    @State private var colliderStore = PanelColliderStore()
    @State private var particleEngine = WeatherParticleEngine()

    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Whether the shared clock should be running at all: reduce-motion, backgrounding, and any
    /// open sheet all stop it outright, and otherwise it only runs when something on screen
    /// actually animates (ambient weather in the hero, falling particles, or an animated
    /// backdrop) — idle clear-day weather with the default backdrop ticks nothing, which is
    /// cheaper than the old per-view `TimelineView`s' always-on 60s idle timer.
    private var ambientClockActive: Bool {
        guard !reduceMotion, scenePhase == .active,
              !showingSettings, !showingCities, !showingAvatarPhoto else { return false }
        if model.weatherTheme.supportsAmbientMotion { return true }
        if WeatherParticleConfig.make(theme: model.weatherTheme, intensity: model.precipitationIntensity, isNight: model.isNight) != nil {
            return true
        }
        return model.selectedBackground.isAnimated
    }

    var body: some View {
        NavigationStack {
            ZStack {
                PixelBackgroundLayer(
                    background: model.selectedBackground,
                    theme: model.weatherTheme,
                    isNight: model.isNight
                )

                ScrollView {
                    VStack(spacing: 16) {
                        PixelSearchBar(
                            model: model,
                            suggester: suggester,
                            isFocused: $cityFieldFocused
                        )
                        .weatherCollider("search")

                        if !suggester.suggestions.isEmpty && cityFieldFocused {
                            PixelSuggestionMenu(
                                suggestions: suggester.suggestions,
                                theme: model.weatherTheme,
                                onSelect: selectSuggestion
                            )
                            .weatherCollider("suggestions")
                        }

                        if model.avatarEnabled || (model.adviceEnabled && !model.advice.isEmpty) {
                            GarageCard(
                                avatarEnabled: model.avatarEnabled,
                                avatarImage: model.avatarImage,
                                avatarAccessories: model.activeAccessories,
                                avatarAnchors: model.avatarFaceAnchors,
                                onAvatarTap: { showingAvatarPhoto = true },
                                adviceEnabled: model.adviceEnabled,
                                advice: model.advice,
                                theme: model.weatherTheme
                            )
                            .weatherCollider("garage")
                        }

                        WeatherHero(
                            city: model.cityInput,
                            conditionTitle: model.conditionTitle,
                            resultText: model.resultText,
                            isLoading: model.isLoading,
                            theme: model.weatherTheme,
                            isNight: model.isNight,
                            onUseLocation: useCurrentLocation
                        )

                        if !model.isLoading, let details = model.details {
                            WeatherDetailsView(details: details, theme: model.weatherTheme)
                                .weatherCollider("details")
                        } else if !model.isLoading {
                            PixelPanel(theme: model.weatherTheme) {
                                ContentUnavailableView(
                                    "Ready to explore",
                                    systemImage: "map",
                                    description: Text("Search for a city or use your approximate location.")
                                )
                                .foregroundStyle(model.weatherTheme.panelTextColor)
                            }
                            .weatherCollider("ready")
                        }
                    }
                    .padding()
                    .coordinateSpace(.named("weatherContent"))
                    .onGeometryChange(for: CGFloat.self) { proxy in
                        proxy.frame(in: .named("weatherPage")).minY
                    } action: { newValue in
                        colliderStore.contentOriginY = newValue
                    }
                }

                WeatherParticleLayer(
                    theme: model.weatherTheme,
                    intensity: model.precipitationIntensity,
                    isNight: model.isNight,
                    engine: particleEngine,
                    colliderStore: colliderStore
                )
            }
            .coordinateSpace(.named("weatherPage"))
            .environment(clock)
            .environment(\.weatherColliderStore, colliderStore)
            .toolbarBackground(model.weatherTheme.skyColor(isNight: model.isNight), for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("WEATHER JOURNEY")
                        .pixelFont(.title)
                        .foregroundStyle(model.weatherTheme.skyTextColor(isNight: model.isNight))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        model.toggleCurrentCitySaved()
                    } label: {
                        PixelSprite(model.isCurrentCitySaved ? .starFilled : .star, scale: 2, tint: model.weatherTheme.skyTint(isNight: model.isNight))
                    }
                    .accessibilityLabel(model.isCurrentCitySaved ? "Remove city from saved" : "Save current city")

                    Button {
                        showingCities = true
                    } label: {
                        PixelSprite(.map, scale: 2, tint: model.weatherTheme.skyTint(isNight: model.isNight))
                    }
                    .accessibilityLabel("Saved cities")

                    Button {
                        showingSettings = true
                    } label: {
                        PixelSprite(.gear, scale: 2, tint: model.weatherTheme.skyTint(isNight: model.isNight))
                    }
                    .accessibilityLabel("Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(model: model)
            }
            .sheet(isPresented: $showingCities) {
                SavedCitiesView(model: model)
            }
            .sheet(isPresented: $showingAvatarPhoto) {
                AvatarPhotoPickerView(model: model)
            }
            .task {
                await model.start()
            }
            .task(id: ambientClockActive) {
                if ambientClockActive {
                    await clock.run()
                }
            }
        }
    }

    private func selectSuggestion(_ suggestion: CitySuggestion) {
        cityFieldFocused = false
        suggester.clear()
        Task { await model.search(city: suggestion.query) }
    }

    private func useCurrentLocation() {
        suggester.clear()
        Task { await model.useCurrentLocation() }
    }
}

private struct WeatherHero: View {
    let city: String
    let conditionTitle: String
    let resultText: String
    let isLoading: Bool
    let theme: PixelWeatherTheme
    var isNight: Bool = false
    let onUseLocation: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PixelParallaxScene(theme: theme, animate: theme.supportsAmbientMotion && !reduceMotion, isNight: isNight)

            VStack(alignment: .leading, spacing: 12) {
                Text(city.isEmpty ? "NEW ROUTE" : city)
                    .pixelFont(.display)
                    .foregroundStyle(theme.skyTextColor(isNight: isNight).opacity(0.86))

                HStack(alignment: .bottom, spacing: 16) {
                    PixelSprite(theme.spriteKind, scale: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(conditionTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(theme.skyTextColor(isNight: isNight))
                        Text(resultText.isEmpty ? "Choose your next weather checkpoint." : resultText)
                            .font(.subheadline)
                            .foregroundStyle(theme.skyTextColor(isNight: isNight).opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if isLoading {
                    HStack(spacing: 8) {
                        PixelSprite(.refresh, tint: theme.skyTint(isNight: isNight))
                        Text("Updating route…")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.skyTextColor(isNight: isNight))
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Updating route…")
                } else {
                    Button {
                        onUseLocation()
                    } label: {
                        HStack(spacing: 8) {
                            PixelSprite(.location, tint: .white)
                            Text("Use my approximate location")
                        }
                    }
                    .buttonStyle(PixelTextButtonStyle(theme: theme))
                    .accessibilityLabel("Use my approximate location")
                    .accessibilityHint("Requests your location once to find local weather.")
                }
            }
            .padding(18)
        }
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .stroke(.white.opacity(0.75), lineWidth: 2)
        }
        .shadow(color: .black.opacity(0.32), radius: 0, x: 4, y: 4)
        .accessibilityElement(children: .combine)
    }
}

/// Car Racer-style garage showroom card: the avatar stands on a small spotlit stage on
/// one side, with the day's gear checklist racked up on the other. Only shown when there's
/// something to display (an avatar, or non-empty gear advice).
private struct GarageCard: View {
    let avatarEnabled: Bool
    let avatarImage: UIImage?
    var avatarAccessories: [AvatarAccessory] = []
    var avatarAnchors: FaceAnchors? = nil
    let onAvatarTap: () -> Void
    let adviceEnabled: Bool
    let advice: [String]
    let theme: PixelWeatherTheme

    var body: some View {
        PixelPanel(theme: theme, style: .showroom) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("GARAGE · LOADOUT")
                        .pixelFont(.title)
                        .foregroundStyle(theme.accentText(on: .showroom))
                    Rectangle()
                        .fill(theme.palette.neon)
                        .frame(height: 2)
                }

                ViewThatFits {
                    HStack(alignment: .top, spacing: 16) {
                        if avatarEnabled {
                            avatarStage
                                .frame(maxWidth: adviceEnabled ? 150 : .infinity)
                        }
                        if adviceEnabled {
                            gearCheck
                        }
                    }

                    VStack(alignment: .leading, spacing: 16) {
                        if avatarEnabled {
                            avatarStage
                                .frame(maxWidth: .infinity)
                        }
                        if adviceEnabled {
                            gearCheck
                        }
                    }
                }
            }
        }
    }

    private var avatarStage: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                HStack {
                    Rectangle()
                        .fill(theme.palette.neon.opacity(0.55))
                        .frame(width: 3)
                    Spacer()
                    Rectangle()
                        .fill(theme.palette.neon.opacity(0.55))
                        .frame(width: 3)
                }
                .frame(height: 200)
                .accessibilityHidden(true)

                VStack(spacing: 0) {
                    Rectangle()
                        .fill(theme.palette.panelShade)
                        .frame(width: 140, height: 10)
                    Rectangle()
                        .fill(theme.palette.hud)
                        .frame(width: 100, height: 6)
                }
                .accessibilityHidden(true)

                Button(action: onAvatarTap) {
                    AvatarView(
                        image: avatarImage,
                        size: CGSize(width: 130, height: 190),
                        accessories: avatarAccessories,
                        anchors: avatarAnchors
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Change avatar photo")
            }

            Text("TAP TO SWAP")
                .pixelFont(.caption)
                .foregroundStyle(theme.textColor(on: .showroom).opacity(0.8))
        }
    }

    private var gearCheck: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                PixelSprite(.backpack, scale: 2, tint: theme.accentColor)
                Text("GEAR CHECK")
                    .pixelFont(.label)
                    .foregroundStyle(theme.textColor(on: .showroom))
            }

            if advice.isEmpty {
                Text("No gear needed — enjoy the ride!")
                    .pixelFont(.body)
                    .foregroundStyle(theme.textColor(on: .showroom).opacity(0.85))
            } else {
                ForEach(advice, id: \.self) { item in
                    HStack(spacing: 10) {
                        PixelBevelShape(notch: 2)
                            .fill(theme.palette.hud)
                            .frame(width: 20, height: 20)
                            .overlay {
                                PixelSprite(.check, scale: 1, tint: theme.accentColor)
                            }

                        Text(item)
                            .pixelFont(.body)
                            .foregroundStyle(theme.textColor(on: .showroom))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }

            HStack(spacing: 8) {
                Text("READY")
                    .pixelFont(.caption)
                    .foregroundStyle(theme.textColor(on: .showroom).opacity(0.85))
                PixelStatBar(value: Double(min(advice.count, 5)) / 5.0, segments: 5, theme: theme)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
