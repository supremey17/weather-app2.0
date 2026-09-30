import SwiftUI

/// Port of SettingsWindow.java, shown as a sheet.
struct SettingsView: View {
    let model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var units: Units = .imperial
    @State private var homeCity = ""
    @State private var adviceEnabled = true
    @State private var avatarEnabled = true

    var body: some View {
        NavigationStack {
            Form {
                Picker("Default unit", selection: $units) {
                    ForEach(Units.allCases) { unit in
                        Text(unit.label).tag(unit)
                    }
                }
                .pickerStyle(.inline)

                Section("Home city") {
                    TextField("e.g. Rochester", text: $homeCity)
                }

                Section {
                    Toggle("Clothing Advisor", isOn: $adviceEnabled)
                    Toggle("Avatar", isOn: $avatarEnabled)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
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
