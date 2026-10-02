import SwiftUI

struct SavedCitiesView: View {
    let model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                model.weatherTheme.skyColor
                    .ignoresSafeArea()

                ScrollView {
                    if model.savedCities.isEmpty {
                        PixelPanel(theme: model.weatherTheme) {
                            ContentUnavailableView(
                                "No saved cities",
                                systemImage: "star",
                                description: Text("Save a city from the dashboard to add a checkpoint.")
                            )
                            .foregroundStyle(model.weatherTheme.panelTextColor)
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(model.savedCities, id: \.self) { city in
                                PixelPanel(theme: model.weatherTheme) {
                                    HStack {
                                        Button {
                                            Task { await model.search(city: city) }
                                            dismiss()
                                        } label: {
                                            Label(city, systemImage: "flag.checkered")
                                                .font(.headline)
                                                .foregroundStyle(model.weatherTheme.panelTextColor)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)

                                        Button(role: .destructive) {
                                            if let index = model.savedCities.firstIndex(of: city) {
                                                model.removeSavedCities(at: IndexSet(integer: index))
                                            }
                                        } label: {
                                            Image(systemName: "trash")
                                        }
                                        .buttonStyle(PixelIconButtonStyle(theme: model.weatherTheme))
                                        .accessibilityLabel("Delete \(city)")
                                    }
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Saved Cities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(model.weatherTheme.skyColor, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
