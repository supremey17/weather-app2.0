import SwiftUI

/// The HUD-style destination search field: one recessed text "well" with a small decorative
/// magnifier inside it, an inline clear "x" that only appears while there's text, and a compact
/// units pill at the right edge. Submitting happens via the keyboard's Search key (`onSubmit`),
/// so there is no separate search button. Every behavior below (onSubmit/onChange/suggester
/// calls, focus handling) is copied verbatim from the old `CitySearchPanel`.
struct PixelSearchBar: View {
    @Bindable var model: WeatherViewModel
    let suggester: CitySuggester
    let isFocused: FocusState<Bool>.Binding

    private var theme: PixelWeatherTheme { model.weatherTheme }

    var body: some View {
        PixelPanel(theme: theme, style: .hud, padding: 8, isTranslucent: true) {
            HStack(spacing: 8) {
                searchField

                Button(model.units.symbol) {
                    suggester.clear()
                    Task { await model.toggleUnits() }
                }
                .buttonStyle(PixelTextButtonStyle(theme: theme))
                .accessibilityLabel("Switch temperature unit")
            }
        }
        .overlay {
            if isFocused.wrappedValue {
                PixelBevelShape()
                    .stroke(theme.palette.neon, lineWidth: 2)
            }
        }
    }

    /// The recessed text well. The whole well is the tap target: tapping the magnifier or the
    /// padding around the text focuses the field, just like tapping the text itself. (The inline
    /// clear button is a child `Button`, so its tap wins over this container's tap gesture.)
    private var searchField: some View {
        HStack(spacing: 8) {
            PixelSprite(.search, scale: 1, tint: theme.accentText(on: .hud))
                .opacity(0.8)

            TextField("SEARCH CITY…", text: $model.cityInput)
                .textFieldStyle(.plain)
                .pixelFont(.body)
                .foregroundStyle(theme.textColor(on: .hud))
                .tint(theme.accentText(on: .hud))
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
                    PixelSprite(.close, scale: 1)
                        .opacity(0.7)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Clear city")
            }
        }
        .padding(.leading, 10)
        .padding(.trailing, model.cityInput.isEmpty ? 10 : 4)
        .frame(maxWidth: .infinity, minHeight: 38, alignment: .leading)
        .background {
            // Sunken text box, like the name-entry fields of old game menus: a slightly darker
            // well with a thin dark rim, sitting inside the lighter HUD panel.
            PixelBevelShape(notch: 3)
                .fill(Color.black.opacity(0.14))
        }
        .overlay {
            PixelBevelShape(notch: 3)
                .stroke(Color.black.opacity(0.3), lineWidth: 1)
        }
        .contentShape(PixelBevelShape(notch: 3))
        .onTapGesture {
            isFocused.wrappedValue = true
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
