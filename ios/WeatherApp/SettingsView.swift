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
                        PixelPanel(theme: model.weatherTheme) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Home checkpoint", symbol: "house")
                                TextField("e.g. Rochester", text: $homeCity)
                                    .textFieldStyle(.roundedBorder)
                                    .accessibilityLabel("Home city")
                            }
                        }

                        PixelPanel(theme: model.weatherTheme) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Weather units", symbol: "thermometer")
                                Picker("Default unit", selection: $units) {
                                    ForEach(Units.allCases) { unit in
                                        Text(unit.label).tag(unit)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                        }

                        PixelPanel(theme: model.weatherTheme) {
                            VStack(alignment: .leading, spacing: 12) {
                                SettingsSectionTitle(title: "Dashboard options", symbol: "slider.horizontal.3")
                                Toggle("Gear check", isOn: $adviceEnabled)
                                Toggle("Avatar", isOn: $avatarEnabled)
                            }
                            .foregroundStyle(model.weatherTheme.panelTextColor)
                        }
                    }
                    .padding()
                }
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

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline.monospaced())
            .foregroundStyle(.white)
    }
}
