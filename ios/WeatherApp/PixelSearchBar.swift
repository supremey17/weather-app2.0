import SwiftUI

/// The HUD-style destination search field: a pixel-font "DESTINATION" label, the flag sprite,
/// the city text field, a clear button (shown once there's text to clear), the search button,
/// and the units toggle. Replaces the old `CitySearchPanel` with retro-game dressing; every
/// behavior below (onSubmit/onChange/suggester calls) is copied verbatim from that view.
struct PixelSearchBar: View {
    @Bindable var model: WeatherViewModel
    let suggester: CitySuggester
    let isFocused: FocusState<Bool>.Binding

    var body: some View {
        PixelPanel(theme: model.weatherTheme, style: .hud) {
            VStack(alignment: .leading, spacing: 6) {
                Text("▶ DESTINATION")
                    .pixelFont(.label)
                    .foregroundStyle(model.weatherTheme.accentText(on: .hud))

                HStack(spacing: 10) {
                    PixelSprite(.flag, scale: 2, tint: model.weatherTheme.accentColor)

                    TextField("ENTER CITY…", text: $model.cityInput)
                        .textFieldStyle(.plain)
                        .foregroundStyle(model.weatherTheme.textColor(on: .hud))
                        .tint(model.weatherTheme.accentText(on: .hud))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
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

                    if !model.cityInput.isEmpty {
                        Button {
                            model.cityInput = ""
                            suggester.clear()
                        } label: {
                            PixelSprite(.close, scale: 2)
                        }
                        .buttonStyle(PixelIconButtonStyle(theme: model.weatherTheme))
                        .accessibilityLabel("Clear city")
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
        .overlay {
            if isFocused.wrappedValue {
                PixelBevelShape()
                    .stroke(model.weatherTheme.palette.neon, lineWidth: 2)
            }
        }
    }
}

/// The autocomplete dropdown: one row per `CitySuggestion`, each with a static "▶" menu cursor,
/// title/subtitle in pixel fonts, and a thin divider between rows. Replaces the old
/// `CitySuggestionPanel`; the button/accessibility wiring per row is copied verbatim.
struct PixelSuggestionMenu: View {
    let suggestions: [CitySuggestion]
    let theme: PixelWeatherTheme
    let onSelect: (CitySuggestion) -> Void

    var body: some View {
        PixelPanel(theme: theme) {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(Array(suggestions.enumerated()), id: \.element.id) { index, suggestion in
                    if index > 0 {
                        Rectangle()
                            .fill(theme.palette.panelShade)
                            .frame(height: 1)
                    }

                    Button {
                        onSelect(suggestion)
                    } label: {
                        HStack(alignment: .top, spacing: 8) {
                            Text("▶")
                                .pixelFont(.caption)
                                .foregroundStyle(theme.accentText(on: .standard))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(verbatim: suggestion.title)
                                    .pixelFont(.body)
                                if !suggestion.subtitle.isEmpty {
                                    Text(verbatim: suggestion.subtitle)
                                        .pixelFont(.caption)
                                        .foregroundStyle(theme.panelTextColor.opacity(0.72))
                                }
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
