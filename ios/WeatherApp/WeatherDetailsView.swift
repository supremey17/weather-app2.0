import SwiftUI

/// Shows precomputed weather details in the shared pixel dashboard language.
struct WeatherDetailsView: View {
    let details: WeatherDetailsResult
    let theme: PixelWeatherTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            CurrentMetricsSection(items: details.current, theme: theme)
            if let air = details.air {
                AirQualitySection(air: air, theme: theme)
            }
            if !details.hourly.isEmpty {
                HourlyForecastSection(hours: details.hourly, theme: theme)
            }
            if !details.daily.isEmpty {
                DailyForecastSection(days: details.daily, theme: theme)
            }
        }
    }
}

private struct CurrentMetricsSection: View {
    let items: [DetailItem]
    let theme: PixelWeatherTheme

    var body: some View {
        PixelPanel(theme: theme) {
            VStack(alignment: .leading, spacing: 12) {
                PixelSectionTitle(title: "Right now", symbol: "gauge.with.dots.needle.67percent", theme: theme)

                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)],
                    spacing: 10
                ) {
                    ForEach(items) { item in
                        MetricTile(item: item, theme: theme)
                    }
                }
            }
        }
    }
}

private struct MetricTile: View {
    let item: DetailItem
    let theme: PixelWeatherTheme

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(item.label, systemImage: item.symbol)
                .font(.caption.weight(.semibold))
                .foregroundStyle(theme.panelTextColor.opacity(0.72))
            Text(verbatim: item.value)
                .font(.headline.monospacedDigit())
                .foregroundStyle(theme.panelTextColor)
        }
        .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
        .padding(10)
        .background(theme.skyColor.opacity(0.22))
        .overlay {
            Rectangle()
                .stroke(theme.accentColor.opacity(0.38), lineWidth: 1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(item.label): \(item.value)")
    }
}

private struct AirQualitySection: View {
    let air: AirQualitySummary
    let theme: PixelWeatherTheme

    var body: some View {
        PixelPanel(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                PixelSectionTitle(title: "Air quality", symbol: "aqi.medium", theme: theme)

                Label {
                    Text(verbatim: air.label)
                        .font(.headline)
                } icon: {
                    Circle()
                        .fill(aqiColor(air.colorName))
                        .frame(width: 12, height: 12)
                }
                .foregroundStyle(theme.panelTextColor)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                    spacing: 8
                ) {
                    ForEach(pollutants, id: \.name) { pollutant in
                        VStack(spacing: 2) {
                            Text(verbatim: pollutant.name)
                                .font(.caption2)
                                .foregroundStyle(theme.panelTextColor.opacity(0.72))
                            Text("\(Int(pollutant.value.rounded()))")
                                .font(.subheadline.monospacedDigit())
                                .foregroundStyle(theme.panelTextColor)
                        }
                        .frame(maxWidth: .infinity)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(pollutant.name): \(Int(pollutant.value.rounded())) micrograms per cubic meter")
                    }
                }
            }
        }
    }

    private var pollutants: [(name: String, value: Double)] {
        [
            ("PM2.5", air.pm25), ("PM10", air.pm10), ("O₃", air.o3),
            ("NO₂", air.no2), ("SO₂", air.so2), ("CO", air.co),
        ]
    }

    private func aqiColor(_ name: String) -> Color {
        switch name {
        case "green": .green
        case "yellow": .yellow
        case "orange": .orange
        case "red": .red
        case "purple": .purple
        default: .gray
        }
    }
}

private struct HourlyForecastSection: View {
    let hours: [HourlyForecast]
    let theme: PixelWeatherTheme

    var body: some View {
        PixelPanel(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                PixelSectionTitle(title: "Next 24 hours", symbol: "clock", theme: theme)

                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(hours) { hour in
                            VStack(spacing: 7) {
                                Text(verbatim: hour.time)
                                    .font(.caption2)
                                Image(systemName: hour.symbol)
                                    .font(.title3)
                                Text(verbatim: hour.temp)
                                    .font(.subheadline.monospacedDigit())
                            }
                            .foregroundStyle(theme.panelTextColor)
                            .frame(width: 72, height: 104)
                            .background(theme.skyColor.opacity(0.22))
                            .overlay {
                                Rectangle()
                                    .stroke(theme.accentColor.opacity(0.38), lineWidth: 1)
                            }
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("\(hour.time): \(hour.temp)")
                        }
                    }
                }
            }
        }
    }
}

private struct DailyForecastSection: View {
    let days: [DailyForecast]
    let theme: PixelWeatherTheme

    var body: some View {
        PixelPanel(theme: theme) {
            VStack(alignment: .leading, spacing: 10) {
                PixelSectionTitle(title: "5-day forecast", symbol: "calendar", theme: theme)

                ForEach(days) { day in
                    HStack(spacing: 10) {
                        Text(verbatim: day.day)
                            .frame(minWidth: 42, alignment: .leading)
                        Image(systemName: day.symbol)
                            .frame(width: 24)
                        if day.chanceOfRain > 0 {
                            Label("\(day.chanceOfRain)%", systemImage: "drop.fill")
                                .font(.caption)
                                .foregroundStyle(theme.accentColor)
                        } else {
                            Text("—")
                                .foregroundStyle(theme.panelTextColor.opacity(0.55))
                        }
                        Spacer()
                        Text(verbatim: day.low)
                            .foregroundStyle(theme.panelTextColor.opacity(0.68))
                        Text(verbatim: day.high)
                            .fontWeight(.bold)
                    }
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(theme.panelTextColor)
                    .padding(.vertical, 6)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(day.day): low \(day.low), high \(day.high), \(day.chanceOfRain)% chance of rain")
                }
            }
        }
    }
}

private struct PixelSectionTitle: View {
    let title: String
    let symbol: String
    let theme: PixelWeatherTheme

    var body: some View {
        Label(title, systemImage: symbol)
            .font(.headline.monospaced())
            .foregroundStyle(theme.accentColor)
    }
}
