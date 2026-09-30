import SwiftUI

struct ContentView: View {
    @State private var model = WeatherViewModel()
    @State private var showingSettings = false
    @State private var showingCities = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                searchRow

                HStack(alignment: .top, spacing: 20) {
                    if model.avatarEnabled {
                        AvatarView(layers: model.layers)
                    }
                    if model.adviceEnabled {
                        adviceList
                    }
                }

                if model.isLoading {
                    ProgressView()
                } else {
                    Text(model.resultText)
                        .multilineTextAlignment(.center)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Weather App")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        model.saveCurrentCity()
                    } label: {
                        Image(systemName: model.savedCities.contains(model.cityInput) ? "star.fill" : "star")
                    }
                    .accessibilityLabel("Save city")

                    Button {
                        showingCities = true
                    } label: {
                        Image(systemName: "list.bullet")
                    }
                    .accessibilityLabel("Cities")

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
            .task {
                await model.start()
            }
        }
    }

    private var searchRow: some View {
        HStack {
            TextField("City", text: $model.cityInput)
                .textFieldStyle(.roundedBorder)
                .submitLabel(.search)
                .onSubmit { Task { await model.search() } }

            Button("Search") {
                Task { await model.search() }
            }
            .buttonStyle(.borderedProminent)

            Button(model.units.symbol) {
                Task { await model.toggleUnits() }
            }
            .buttonStyle(.bordered)
        }
    }

    private var adviceList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(model.advice, id: \.self) { item in
                    Text("• \(item)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: 220)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ContentView()
}
