import SwiftUI

/// Shows everything OWM gives us beyond the headline temperature: current-conditions tiles, air
/// quality, an hourly strip and a 5-day outlook. All values are precomputed by `WeatherDetails`
/// (see `WeatherViewModel.load`), so this view does no parsing or date math while redrawing.
struct WeatherDetailsView: View {
    let details: WeatherDetailsResult

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            currentSection
            if let air = details.air {
                airQualitySection(air)
            }
            if !details.hourly.isEmpty {
                hourlySection
            }
            if !details.daily.isEmpty {
                dailySection
            }
        }
    }

    private var currentSection: some View {
        sectionCard(title: "Right now") {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(details.current) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Label {
                            Text(verbatim: item.label)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } icon: {
                            Image(systemName: item.symbol)
                                .foregroundStyle(.secondary)
                        }
                        Text(verbatim: item.value)
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(item.label): \(item.value)")
                }
            }
        }
    }

    private func airQualitySection(_ air: AirQualitySummary) -> some View {
        sectionCard(title: "Air quality") {
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text(verbatim: air.label)
                        .font(.headline)
                } icon: {
                    Circle()
                        .fill(aqiColor(air.colorName))
                        .frame(width: 12, height: 12)
                }

                let pollutants: [(String, Double)] = [
                    ("PM2.5", air.pm25), ("PM10", air.pm10), ("O\u{2083}", air.o3),
                    ("NO\u{2082}", air.no2), ("SO\u{2082}", air.so2), ("CO", air.co),
                ]
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    ForEach(pollutants, id: \.0) { name, value in
                        VStack(spacing: 2) {
                            Text(verbatim: name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(verbatim: "\(Int(value.rounded()))")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(name): \(Int(value.rounded())) micrograms per cubic meter")
                    }
                }
            }
        }
    }

    private var hourlySection: some View {
        sectionCard(title: "Next 24 hours") {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(details.hourly) { hour in
                        VStack(spacing: 6) {
                            Text(verbatim: hour.time)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Image(systemName: hour.symbol)
                                .font(.title3)
                            Text(verbatim: hour.temp)
                                .font(.subheadline)
                        }
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(hour.time): \(hour.temp)")
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

    private var dailySection: some View {
        sectionCard(title: "5-day forecast") {
            VStack(spacing: 10) {
                ForEach(details.daily) { day in
                    HStack {
                        Text(verbatim: day.day)
                            .frame(width: 48, alignment: .leading)
                        Image(systemName: day.symbol)
                            .frame(width: 24)
                        if day.chanceOfRain > 0 {
                            Label("\(day.chanceOfRain)%", systemImage: "drop")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 56, alignment: .leading)
                        } else {
                            Spacer().frame(width: 56)
                        }
                        Spacer()
                        Text(verbatim: day.low)
                            .foregroundStyle(.secondary)
                        Text(verbatim: day.high)
                            .fontWeight(.semibold)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(day.day): low \(day.low), high \(day.high), \(day.chanceOfRain)% chance of rain")
                }
            }
        }
    }

    /// `WeatherDetails.swift` is plain logic with no SwiftUI import, so it hands back a word
    /// ("green", "red", ...) rather than a `Color`; this is the one place that maps it to an
    /// actual system color instead of relying on `Color(_:)`'s asset-catalog lookup, which would
    /// silently fail since no such named color sets exist in Assets.xcassets.
    private func aqiColor(_ name: String) -> Color {
        switch name {
        case "green": return .green
        case "yellow": return .yellow
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        default: return .gray
        }
    }

    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
