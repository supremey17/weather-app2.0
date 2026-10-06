import SwiftUI

struct ContentView: View {
    @State private var model = WeatherViewModel()
    @State private var showingSettings = false
    @State private var showingCities = false
    @State private var showingAvatarPhoto = false
    @State private var suggester = CitySuggester()
    @FocusState private var cityFieldFocused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                model.weatherTheme.skyColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        CitySearchPanel(
                            model: model,
                            suggester: suggester,
                            isFocused: $cityFieldFocused
                        )

                        if !suggester.suggestions.isEmpty && cityFieldFocused {
                            CitySuggestionPanel(
                                suggestions: suggester.suggestions,
                                theme: model.weatherTheme,
                                onSelect: selectSuggestion
                            )
                        }

                        if model.avatarEnabled || (model.adviceEnabled && !model.advice.isEmpty) {
                            GarageCard(
                                avatarEnabled: model.avatarEnabled,
                                avatarImage: model.avatarImage,
                                onAvatarTap: { showingAvatarPhoto = true },
                                adviceEnabled: model.adviceEnabled,
                                advice: model.advice,
                                theme: model.weatherTheme
                            )
                        }

                        WeatherHero(
                            city: model.cityInput,
                            conditionTitle: model.conditionTitle,
                            resultText: model.resultText,
                            isLoading: model.isLoading,
                            theme: model.weatherTheme,
                            onUseLocation: useCurrentLocation
                        )

                        if !model.isLoading, let details = model.details {
                            WeatherDetailsView(details: details, theme: model.weatherTheme)
                        } else if !model.isLoading {
                            PixelPanel(theme: model.weatherTheme) {
                                ContentUnavailableView(
                                    "Ready to explore",
                                    systemImage: "map",
                                    description: Text("Search for a city or use your approximate location.")
                                )
                                .foregroundStyle(model.weatherTheme.panelTextColor)
                            }
                        }
                    }
                    .padding()
                }
            }
            .toolbarBackground(model.weatherTheme.skyColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("WEATHER JOURNEY")
                        .pixelFont(.title)
                        .foregroundStyle(model.weatherTheme.skyTextColor)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        model.toggleCurrentCitySaved()
                    } label: {
                        PixelSprite(model.isCurrentCitySaved ? .starFilled : .star, scale: 2, tint: model.weatherTheme.skyTint)
                    }
                    .accessibilityLabel(model.isCurrentCitySaved ? "Remove city from saved" : "Save current city")

                    Button {
                        showingCities = true
                    } label: {
                        PixelSprite(.map, scale: 2, tint: model.weatherTheme.skyTint)
                    }
                    .accessibilityLabel("Saved cities")

                    Button {
                        showingSettings = true
                    } label: {
                        PixelSprite(.gear, scale: 2, tint: model.weatherTheme.skyTint)
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

private struct CitySearchPanel: View {
    @Bindable var model: WeatherViewModel
    let suggester: CitySuggester
    let isFocused: FocusState<Bool>.Binding

    var body: some View {
        PixelPanel(theme: model.weatherTheme, style: .hud) {
            HStack(spacing: 10) {
                PixelSprite(.flag, scale: 2, tint: model.weatherTheme.accentColor)

                TextField("Change city", text: $model.cityInput)
                    .textFieldStyle(.plain)
                    .foregroundStyle(model.weatherTheme.textColor(on: .hud))
                    .submitLabel(.search)
                    .focused(isFocused)
                    .onSubmit {
                        suggester.clear()
                        Task { await model.search() }
                    }
                    .onChange(of: model.cityInput) { _, newValue in
                        guard isFocused.wrappedValue else { return }
                        suggester.update(query: newValue, saved: model.savedCities)
                    }
                    .onChange(of: isFocused.wrappedValue) { _, focused in
                        if !focused {
                            suggester.clear()
                        }
                    }

                Button {
                    suggester.clear()
                    Task { await model.search() }
                } label: {
                    PixelSprite(.search, scale: 2)
                }
                .buttonStyle(PixelIconButtonStyle(theme: model.weatherTheme))
                .accessibilityLabel("Search city")

                Button(model.units.symbol) {
                    suggester.clear()
                    Task { await model.toggleUnits() }
                }
                .buttonStyle(PixelTextButtonStyle(theme: model.weatherTheme))
                .accessibilityLabel("Switch temperature unit")
            }
        }
    }
}

private struct CitySuggestionPanel: View {
    let suggestions: [CitySuggestion]
    let theme: PixelWeatherTheme
    let onSelect: (CitySuggestion) -> Void

    var body: some View {
        PixelPanel(theme: theme) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(suggestions) { suggestion in
                    Button {
                        onSelect(suggestion)
                    } label: {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(verbatim: suggestion.title)
                            if !suggestion.subtitle.isEmpty {
                                Text(verbatim: suggestion.subtitle)
                                    .font(.caption)
                                    .foregroundStyle(theme.panelTextColor.opacity(0.72))
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.vertical, 8)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("citySuggestion")
                    .accessibilityLabel(suggestion.subtitle.isEmpty ? suggestion.title : "\(suggestion.title), \(suggestion.subtitle)")
                }
            }
            .foregroundStyle(theme.panelTextColor)
        }
    }
}

private struct WeatherHero: View {
    let city: String
    let conditionTitle: String
    let resultText: String
    let isLoading: Bool
    let theme: PixelWeatherTheme
    let onUseLocation: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PixelParallaxScene(theme: theme, animate: theme.supportsAmbientMotion && !reduceMotion)

            VStack(alignment: .leading, spacing: 12) {
                Text(city.isEmpty ? "NEW ROUTE" : city)
                    .pixelFont(.display)
                    .foregroundStyle(theme.skyTextColor.opacity(0.86))

                HStack(alignment: .bottom, spacing: 16) {
                    PixelSprite(theme.spriteKind, scale: 4)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(conditionTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(theme.skyTextColor)
                        Text(resultText.isEmpty ? "Choose your next weather checkpoint." : resultText)
                            .font(.subheadline)
                            .foregroundStyle(theme.skyTextColor.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                if isLoading {
                    HStack(spacing: 8) {
                        PixelSprite(.refresh, tint: theme.skyTint)
                        Text("Updating route…")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.skyTextColor)
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
                    AvatarView(image: avatarImage, size: CGSize(width: 130, height: 190))
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
