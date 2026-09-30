import SwiftUI

/// Port of SavedCitiesWindow.java: tap a city to load it, swipe to remove it.
struct SavedCitiesView: View {
    let model: WeatherViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(model.savedCities, id: \.self) { city in
                    Button(city) {
                        Task { await model.search(city: city) }
                        dismiss()
                    }
                }
                .onDelete { model.removeSavedCities(at: $0) }
            }
            .overlay {
                if model.savedCities.isEmpty {
                    ContentUnavailableView("No saved cities", systemImage: "star",
                                           description: Text("Tap the star to save the city you're looking at."))
                }
            }
            .navigationTitle("Saved Cities")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
