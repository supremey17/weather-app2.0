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
        PixelPanel(theme: theme, style: .hud, padding: 10) {
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    PixelSprite(PixelSpriteKind(sfSymbol: item.symbol), scale: 2, tint: theme.accentColor)
                    Text(item.label)
                        .pixelFont(.caption)
                }
                .foregroundStyle(theme.textColor(on: .hud).opacity(0.72))
                Text(verbatim: item.value)
                    .pixelFont(.number)
                    .foregroundStyle(theme.textColor(on: .hud))
            }
            .frame(maxWidth: .infinity, minHeight: 62, alignment: .leading)
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
                        .pixelFont(.headline)
                } icon: {
                    Rectangle()
                        .fill(aqiColor(air.colorName))
                        .frame(width: 14, height: 14)
                        .overlay {
                            PixelBevelShape(notch: 2)
                                .stroke(Color.black.opacity(0.4), lineWidth: 1)
                        }
                        .clipShape(PixelBevelShape(notch: 2))
                }
                .foregroundStyle(theme.panelTextColor)

                PixelStatBar(value: aqiNormalizedLevel, segments: 5, theme: theme)

                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 3),
                    spacing: 8
                ) {
                    ForEach(pollutants, id: \.name) { pollutant in
                        VStack(spacing: 2) {
                            Text(verbatim: pollutant.name)
                                .pixelFont(.caption)
                                .foregroundStyle(theme.panelTextColor.opacity(0.72))
                            Text("\(Int(pollutant.value.rounded()))")
                                .pixelFont(.number)
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

    /// OWM's AQI is a 1...5 ordinal scale (good...very poor); `colorName` is derived
    /// from that same scale, so we can recover the level to drive the stat bar.
    private var aqiLevel: Int {
        switch air.colorName {
        case "green": 1
        case "yellow": 2
        case "orange": 3
        case "red": 4
        case "purple": 5
        default: 1
        }
    }

    private var aqiNormalizedLevel: Double {
        Double(aqiLevel - 1) / 4.0
    }

    private func aqiColor(_ name: String) -> Color {
        switch name {
        case "green": theme.accentColor
        case "yellow": Color(red: 0.95, green: 0.78, blue: 0.2)
        case "orange": Color(red: 0.95, green: 0.55, blue: 0.2)
        case "red": Color(red: 0.85, green: 0.25, blue: 0.25)
        case "purple": Color(red: 0.55, green: 0.15, blue: 0.35)
        default: theme.palette.panelShade
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
                                    .pixelFont(.caption)
                                PixelSprite(PixelSpriteKind(sfSymbol: hour.symbol), scale: 2)
                                Text(verbatim: hour.temp)
                                    .pixelFont(.number)
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
                        PixelSprite(PixelSpriteKind(sfSymbol: day.symbol), scale: 2)
                            .frame(width: 24)
                        if day.chanceOfRain > 0 {
                            HStack(spacing: 4) {
                                PixelSprite(.drop, scale: 1, tint: theme.accentColor)
                                Text("\(day.chanceOfRain)%")
                                PixelStatBar(value: Double(day.chanceOfRain) / 100.0, segments: 5, theme: theme)
                            }
                            .pixelFont(.caption)
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
                    .pixelFont(.number)
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
        PixelPanel(theme: theme, style: .hud, padding: 6) {
            HStack(spacing: 6) {
                PixelSprite(PixelSpriteKind(sfSymbol: symbol), scale: 2, tint: theme.accentColor)
                Text(title)
                    .pixelFont(.headline)
                    .foregroundStyle(theme.accentColor)
            }
        }
    }
}
