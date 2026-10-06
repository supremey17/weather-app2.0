import SwiftUI

struct SettingsView: View {
    let model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var units: Units = .imperial
    @State private var homeCity = ""
    @State private var adviceEnabled = true
    @State private var avatarEnabled = true

    var body: some View {
        NavigationStack {
            ZStack {
                model.weatherTheme.skyColor
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Home checkpoint", symbol: "house", theme: model.weatherTheme)
                                PixelPanel(theme: model.weatherTheme, style: .hud, padding: 8) {
                                    TextField("e.g. Rochester", text: $homeCity)
                                        .textFieldStyle(.plain)
                                        .pixelFont(.body)
                                        .foregroundStyle(model.weatherTheme.textColor(on: .hud))
                                        .accessibilityLabel("Home city")
                                }
                            }
                        }

                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Weather units", symbol: "thermometer", theme: model.weatherTheme)
                                HStack(spacing: 10) {
                                    ForEach(Units.allCases) { unit in
                                        Button(unit.label) {
                                            units = unit
                                        }
                                        .buttonStyle(PixelButtonStyle(theme: model.weatherTheme, kind: units == unit ? .primary : .secondary))
                                    }
                                }
                            }
                        }

                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Dashboard options", symbol: "slider.horizontal.3", theme: model.weatherTheme)
                                Toggle("Gear check", isOn: $adviceEnabled)
                                    .toggleStyle(PixelToggleStyle(theme: model.weatherTheme))
                                Toggle("Avatar", isOn: $avatarEnabled)
                                    .toggleStyle(PixelToggleStyle(theme: model.weatherTheme))
                            }
                            .foregroundStyle(model.weatherTheme.textColor(on: .wood))
                        }
                    }
                    .padding()
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(model.weatherTheme.skyColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            await model.saveSettings(
                                defaultUnits: units,
                                homeCity: homeCity,
                                adviceEnabled: adviceEnabled,
                                avatarEnabled: avatarEnabled
                            )
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                units = model.defaultUnits
                homeCity = model.homeCity
                adviceEnabled = model.adviceEnabled
                avatarEnabled = model.avatarEnabled
            }
        }
    }
}

private struct SettingsSectionTitle: View {
    let title: String
    let symbol: String
    let theme: PixelWeatherTheme

    var body: some View {
        HStack(spacing: 6) {
            PixelSprite(PixelSpriteKind(sfSymbol: symbol), scale: 2, tint: theme.accentColor)
            Text(title)
                .pixelFont(.headline)
        }
        .foregroundStyle(theme.textColor(on: .wood))
    }
}

/// Renders a Toggle as a bevel-framed ON/OFF pixel switch with a square thumb that
/// slides to the left (off) or right (on) side of the track.
private struct PixelToggleStyle: ToggleStyle {
    let theme: PixelWeatherTheme

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label
                .pixelFont(.body)
                .foregroundStyle(theme.textColor(on: .wood))
            Spacer()
            Button {
                configuration.isOn.toggle()
            } label: {
                PixelBevelShape(notch: 3)
                    .fill(theme.palette.panelShade)
                    .frame(width: 64, height: 28)
                    .overlay {
                        PixelBevelShape(notch: 3)
                            .stroke(theme.accentColor.opacity(0.7), lineWidth: 1)
                    }
                    .overlay(alignment: configuration.isOn ? .trailing : .leading) {
                        Text(configuration.isOn ? "ON" : "OFF")
                            .pixelFont(.caption)
                            .foregroundStyle(theme.panelColor)
                            .frame(width: 32, height: 22)
                            .background(theme.accentColor)
                            .clipShape(PixelBevelShape(notch: 2))
                            .padding(3)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(configuration.isOn ? "On" : "Off")
        }
    }
}
