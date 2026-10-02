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

                        WeatherHero(
                            city: model.cityInput,
                            conditionTitle: model.conditionTitle,
                            resultText: model.resultText,
                            isLoading: model.isLoading,
                            theme: model.weatherTheme,
                            avatarEnabled: model.avatarEnabled,
                            avatarImage: model.avatarImage,
                            onAvatarTap: { showingAvatarPhoto = true },
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

                        if model.adviceEnabled, !model.advice.isEmpty {
                            GearAdviceSection(advice: model.advice, theme: model.weatherTheme)
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Weather Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(model.weatherTheme.skyColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        model.saveCurrentCity()
                    } label: {
                        Image(systemName: model.savedCities.contains(model.cityInput) ? "star.fill" : "star")
                    }
                    .accessibilityLabel("Save current city")

                    Button {
                        showingCities = true
                    } label: {
                        Image(systemName: "map")
                    }
                    .accessibilityLabel("Saved cities")

                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape")
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
        PixelPanel(theme: model.weatherTheme) {
            HStack(spacing: 10) {
                Image(systemName: "flag.checkered")
                    .foregroundStyle(model.weatherTheme.accentColor)

                TextField("Change city", text: $model.cityInput)
                    .textFieldStyle(.plain)
                    .foregroundStyle(model.weatherTheme.panelTextColor)
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
                    Image(systemName: "magnifyingglass")
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
    let avatarEnabled: Bool
    let avatarImage: UIImage?
    let onAvatarTap: () -> Void
    let onUseLocation: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            PixelScene(theme: theme, animate: theme.supportsAmbientMotion && !reduceMotion)

            VStack(alignment: .leading, spacing: 12) {
                Text(city.isEmpty ? "NEW ROUTE" : city)
                    .font(.headline.monospaced())
                    .foregroundStyle(.white.opacity(0.86))

                HStack(alignment: .bottom, spacing: 16) {
                    Image(systemName: theme.sceneSymbol)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(theme.accentColor)
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(conditionTitle)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                        Text(resultText.isEmpty ? "Choose your next weather checkpoint." : resultText)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.88))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if avatarEnabled {
                        Button {
                            onAvatarTap()
                        } label: {
                            AvatarView(image: avatarImage, size: CGSize(width: 54, height: 76))
                                .accessibilityHidden(true)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Change avatar photo")
                    }
                }

                if isLoading {
                    Label("Updating route…", systemImage: "arrow.triangle.2.circlepath")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                } else {
                    Button {
                        onUseLocation()
                    } label: {
                        Label("Use my approximate location", systemImage: "location")
                    }
                    .buttonStyle(PixelTextButtonStyle(theme: theme))
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

private struct PixelScene: View {
    let theme: PixelWeatherTheme
    let animate: Bool
    @Environment(\.scenePhase) private var scenePhase
    @State private var isOffset = false

    private var shouldAnimate: Bool {
        animate && scenePhase == .active
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottom) {
                theme.skyColor
                Rectangle()
                    .fill(theme.horizonColor)
                    .frame(height: proxy.size.height * 0.28)

                if theme.supportsAmbientMotion {
                    PixelAmbientWeather(theme: theme, offset: isOffset)
                }
            }
        }
        .onAppear {
            updateAnimation()
        }
        .onChange(of: shouldAnimate) { _, _ in
            updateAnimation()
        }
    }

    private func updateAnimation() {
        guard shouldAnimate else {
            withAnimation(.none) {
                isOffset = false
            }
            return
        }
        withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
            isOffset = true
        }
    }
}

private struct PixelAmbientWeather: View {
    let theme: PixelWeatherTheme
    let offset: Bool

    var body: some View {
        GeometryReader { proxy in
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(theme == .snowy ? Color.white.opacity(0.84) : theme.accentColor.opacity(0.74))
                    .frame(width: theme == .snowy ? 4 : 2, height: theme == .snowy ? 4 : 14)
                    .position(
                        x: CGFloat((index * 43) % max(Int(proxy.size.width), 1)),
                        y: CGFloat((index * 31) % max(Int(proxy.size.height), 1)) + (offset ? proxy.size.height : 0)
                    )
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

private struct GearAdviceSection: View {
    let advice: [String]
    let theme: PixelWeatherTheme

    var body: some View {
        PixelPanel(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                Label("Gear check", systemImage: "backpack")
                    .font(.headline.monospaced())
                    .foregroundStyle(theme.accentColor)

                ForEach(advice, id: \.self) { item in
                    Label(item, systemImage: "checkmark.square.fill")
                        .font(.subheadline)
                        .foregroundStyle(theme.panelTextColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

struct PixelIconButtonStyle: ButtonStyle {
    let theme: PixelWeatherTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(theme.panelColor)
            .padding(9)
            .background(theme.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .opacity(configuration.isPressed ? 0.68 : 1)
    }
}

struct PixelTextButtonStyle: ButtonStyle {
    let theme: PixelWeatherTheme

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.bold))
            .foregroundStyle(theme.panelColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(theme.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
            .opacity(configuration.isPressed ? 0.68 : 1)
    }
}

#Preview {
    ContentView()
}
