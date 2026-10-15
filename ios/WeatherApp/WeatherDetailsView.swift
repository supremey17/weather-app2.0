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
        PixelPanel(theme: theme, isTranslucent: true) {
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
        PixelPanel(theme: theme, style: .hud, padding: 10, isTranslucent: true) {
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
        PixelPanel(theme: theme, isTranslucent: true) {
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
        PixelPanel(theme: theme, isTranslucent: true) {
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
                                    .stroke(theme.accentColor.opacity(0.50), lineWidth: 1)
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
        PixelPanel(theme: theme, isTranslucent: true) {
            VStack(alignment: .leading, spacing: 10) {
                PixelSectionTitle(title: "5-day forecast", symbol: "calendar", theme: theme)

                ForEach(days) { day in
                    HStack(spacing: 10) {
                        Text(verbatim: day.day)
                            .frame(minWidth: 42, alignment: .leading)
                        PixelSprite(PixelSpriteKind(sfSymbol: day.symbol), scale: 2)
                            .frame(width: 24)
                        PixelRainDropGauge(chance: day.chanceOfRain, theme: theme)
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

/// Chance of rain as a chunky pixel raindrop that fills with water from the bottom up, with the
/// percentage printed inside, like a potion/health flask in a game HUD. Static, so it's Reduce
/// Motion-safe; the row's accessibility label already speaks the percentage.
struct PixelRainDropGauge: View {
    let chance: Int
    let theme: PixelWeatherTheme

    /// One pixel of the drop, in points.
    static let cell: CGFloat = 3

    /// The drop's silhouette: `#` cells are inside the drop. Wide rows at the bottom leave room
    /// for the percentage text.
    static let mask: [String] = [
        "....#....",
        "....#....",
        "...###...",
        "...###...",
        "..#####..",
        ".#######.",
        "#########",
        "#########",
        "#########",
        "#########",
        ".#######.",
        "..#####..",
    ]

    static var columns: Int { mask[0].count }
    static var rows: Int { mask.count }

    /// How many rows (counted from the bottom) are under water. Any non-zero chance shows at
    /// least one row, and only 100% fills the tip.
    static func filledRows(chance: Int) -> Int {
        let clamped = min(max(chance, 0), 100)
        guard clamped > 0 else { return 0 }
        if clamped == 100 { return rows }
        return min(max(Int((Double(clamped) / 100.0 * Double(rows)).rounded()), 1), rows - 1)
    }

    private static let water = Color(red: 0.22, green: 0.62, blue: 1.0)
    private static let waterSurface = Color(red: 0.55, green: 0.85, blue: 1.0)
    private static let outline = Color(red: 0.05, green: 0.04, blue: 0.12)

    private var label: String { "\(min(max(chance, 0), 100))%" }

    var body: some View {
        let cell = Self.cell
        let filled = Self.filledRows(chance: chance)
        let emptyColor = theme.palette.panelShade.opacity(0.85)

        Canvas { context, _ in
            let mask = Self.mask.map { Array($0) }
            let isInside: (Int, Int) -> Bool = { row, col in
                row >= 0 && row < Self.rows && col >= 0 && col < Self.columns && mask[row][col] == "#"
            }
            func rect(_ row: Int, _ col: Int) -> CGRect {
                // Offset by one cell so the outline ring fits inside the canvas.
                CGRect(x: CGFloat(col + 1) * cell, y: CGFloat(row + 1) * cell, width: cell, height: cell)
            }

            // Hard one-cell outline around the silhouette.
            for row in -1...Self.rows {
                for col in -1...Self.columns where !isInside(row, col) {
                    let touchesDrop = (-1...1).contains { dr in
                        (-1...1).contains { dc in isInside(row + dr, col + dc) }
                    }
                    if touchesDrop {
                        context.fill(Path(rect(row, col)), with: .color(Self.outline))
                    }
                }
            }

            let surfaceRow = Self.rows - filled
            for row in 0..<Self.rows {
                for col in 0..<Self.columns where isInside(row, col) {
                    let color: Color
                    if row < surfaceRow {
                        color = emptyColor
                    } else if row == surfaceRow && filled < Self.rows {
                        color = Self.waterSurface
                    } else {
                        color = Self.water
                    }
                    context.fill(Path(rect(row, col)), with: .color(color))
                }
            }

            // Little glassy shine on the upper-left of the bulb.
            for (row, col) in [(5, 2), (6, 1), (7, 1)] {
                context.fill(Path(rect(row, col)), with: .color(.white.opacity(0.75)))
            }
        }
        .frame(width: CGFloat(Self.columns + 2) * cell, height: CGFloat(Self.rows + 2) * cell)
        .overlay(alignment: .bottom) {
            Text(label)
                .font(.custom("PressStart2P-Regular", fixedSize: label.count > 3 ? 6 : 7))
                .foregroundStyle(.white)
                .shadow(color: Self.outline, radius: 0, x: 1, y: 1)
                .lineLimit(1)
                .fixedSize()
                // Sit the text in the wide lower rows of the drop.
                .padding(.bottom, cell * 3.5)
        }
        .accessibilityHidden(true)
    }
}

private struct PixelSectionTitle: View {
    let title: String
    let symbol: String
    let theme: PixelWeatherTheme

    var body: some View {
        PixelPanel(theme: theme, style: .hud, padding: 6, isTranslucent: true) {
            HStack(spacing: 6) {
                PixelSprite(PixelSpriteKind(sfSymbol: symbol), scale: 2, tint: theme.accentColor)
                Text(title)
                    .pixelFont(.headline)
                    .foregroundStyle(theme.accentColor)
            }
        }
    }
}
