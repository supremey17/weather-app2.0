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
            ScrollView {
                VStack(spacing: 20) {
                    searchRow

                    if !suggester.suggestions.isEmpty && cityFieldFocused {
                        suggestionList
                    }

                    HStack(alignment: .top, spacing: 20) {
                        if model.avatarEnabled {
                            Button {
                                showingAvatarPhoto = true
                            } label: {
                                AvatarView(image: model.avatarImage)
                            }
                            .accessibilityLabel("Change avatar photo")
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

                    if !model.isLoading, let details = model.details {
                        WeatherDetailsView(details: details)
                    }
                }
                .padding()
            }
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
            .sheet(isPresented: $showingAvatarPhoto) {
                AvatarPhotoPickerView(model: model)
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
                .focused($cityFieldFocused)
                .onSubmit {
                    suggester.clear()
                    Task { await model.search() }
                }
                .onChange(of: model.cityInput) { _, newValue in
                    // Only react to the user typing; cityInput is also set by start()/search()/
                    // load() finishing, and those shouldn't trigger a lookup.
                    guard cityFieldFocused else { return }
                    suggester.update(query: newValue, saved: model.savedCities)
                }
                .onChange(of: cityFieldFocused) { _, focused in
                    if !focused { suggester.clear() }
                }

            Button("Search") {
                suggester.clear()
                Task { await model.search() }
            }
            .buttonStyle(.borderedProminent)

            Button(model.units.symbol) {
                suggester.clear()
                Task { await model.toggleUnits() }
            }
            .buttonStyle(.bordered)
        }
    }

    private var suggestionList: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(suggester.suggestions) { suggestion in
                Button {
                    cityFieldFocused = false
                    suggester.clear()
                    Task { await model.search(city: suggestion.query) }
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(verbatim: suggestion.title)
                        if !suggestion.subtitle.isEmpty {
                            Text(verbatim: suggestion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 10)
                }
                .accessibilityIdentifier("citySuggestion")
                .accessibilityLabel(suggestion.subtitle.isEmpty ? suggestion.title : "\(suggestion.title), \(suggestion.subtitle)")
            }
        }
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
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
