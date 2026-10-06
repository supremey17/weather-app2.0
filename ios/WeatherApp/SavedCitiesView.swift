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
                        PixelPanel(theme: model.weatherTheme, style: .wood) {
                            VStack(spacing: 10) {
                                PixelSprite(.star, scale: 4, tint: model.weatherTheme.accentColor)
                                Text("No saved cities")
                                    .pixelFont(.headline)
                                Text("Save a city from the dashboard to add a checkpoint.")
                                    .pixelFont(.body)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .foregroundStyle(model.weatherTheme.textColor(on: .wood))
                        }
                        .padding()
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(model.savedCities, id: \.self) { city in
                                PixelPanel(theme: model.weatherTheme, style: .wood) {
                                    HStack {
                                        Button {
                                            Task { await model.search(city: city) }
                                            dismiss()
                                        } label: {
                                            HStack {
                                                PixelSprite(.flag, scale: 2, tint: model.weatherTheme.accentColor)
                                                Text(city)
                                                    .pixelFont(.body)
                                            }
                                            .foregroundStyle(model.weatherTheme.textColor(on: .wood))
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                        }
                                        .buttonStyle(.plain)

                                        Button(role: .destructive) {
                                            if let index = model.savedCities.firstIndex(of: city) {
                                                model.removeSavedCities(at: IndexSet(integer: index))
                                            }
                                        } label: {
                                            PixelSprite(.trash, scale: 2, tint: model.weatherTheme.accentColor)
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
