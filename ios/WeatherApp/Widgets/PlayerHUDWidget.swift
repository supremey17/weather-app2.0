import SwiftUI
import WidgetKit

/// Small home screen widget styled as a game HUD: stage (city), condition sprite, big temperature,
/// and an "HP" bar showing where the current temperature sits between today's low and high.
struct PlayerHUDWidget: Widget {
    static let kind = "PlayerHUDWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            PlayerHUDView(entry: entry)
        }
        .configurationDisplayName("Player HUD")
        .description("Current stage, temperature and today's HP bar.")
        .supportedFamilies([.systemSmall])
    }

    /// Where `temp` sits between `low` and `high`, clamped to 0...1. `nil` without a usable range.
    static func hpFraction(temp: Double, low: Double?, high: Double?) -> Double? {
        guard let low, let high, high > low else { return nil }
        return min(max((temp - low) / (high - low), 0), 1)
    }

    /// Text-only HP bar for monochrome surfaces, e.g. 0.75 over 8 segments -> "▰▰▰▰▰▰▱▱".
    static func hpBarText(fraction: Double, segments: Int = 8) -> String {
        let filled = Int((min(max(fraction, 0), 1) * Double(segments)).rounded())
        return String(repeating: "▰", count: filled) + String(repeating: "▱", count: segments - filled)
    }

    /// Spoken summary, e.g. "72 degrees Fahrenheit in Pixel Town, scattered clouds".
    static func accessibilityLabel(for snapshot: WidgetSnapshot) -> String {
        let temp = TemperatureReadoutFormat.accessibilityLabel(temp: snapshot.temp, units: snapshot.unitsValue)
        return "\(temp) in \(snapshot.city), \(snapshot.condition)"
    }
}

private struct PlayerHUDView: View {
    let entry: SnapshotEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            hud(snapshot)
                .pixelWidgetBackground(snapshot.weatherTheme)
        } else {
            PressStartView()
                .pixelWidgetBackground(.neutral)
        }
    }

    private func hud(_ snapshot: WidgetSnapshot) -> some View {
        let theme = snapshot.weatherTheme
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text("STAGE")
                    .pixelFont(.caption)
                    .foregroundStyle(theme.accentColor)
                Spacer(minLength: 4)
                if snapshot.isStale(at: entry.date) {
                    Text("STALE")
                        .pixelFont(.caption)
                        .padding(.horizontal, 3)
                        .background(TemperatureColors.outline.opacity(0.7))
                        .accessibilityLabel("Data is out of date")
                }
            }
            Text(snapshot.city)
                .pixelFont(.label)
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer(minLength: 0)

            HStack(spacing: 8) {
                PixelSprite(PixelSpriteKind(sfSymbol: theme.sceneSymbol), scale: 2)
                    .accessibilityHidden(true)
                HUDTemperature(temp: snapshot.temp, units: snapshot.unitsValue)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(PlayerHUDWidget.accessibilityLabel(for: snapshot))

            Spacer(minLength: 0)

            if let low = snapshot.low, let high = snapshot.high,
               let fraction = PlayerHUDWidget.hpFraction(temp: snapshot.temp, low: low, high: high) {
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 4) {
                        Text("HP").pixelFont(.caption)
                        PixelStatBar(value: fraction, segments: 10, theme: theme)
                    }
                    HStack {
                        Text("L \(TemperatureReadoutFormat.number(low))")
                        Spacer()
                        Text("H \(TemperatureReadoutFormat.number(high))")
                    }
                    .pixelFont(.caption)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Low \(TemperatureReadoutFormat.number(low)), high \(TemperatureReadoutFormat.number(high))")
            }
        }
        .foregroundStyle(.white)
        .shadow(color: TemperatureColors.outline, radius: 0, x: 1, y: 1)
    }
}

/// Widget-sized take on `PixelTemperatureReadout`: band gradient fill with a hard pixel shadow,
/// no glow or eight-way outline (too heavy at this size).
private struct HUDTemperature: View {
    let temp: Double
    let units: Units

    var body: some View {
        Text(TemperatureReadoutFormat.number(temp) + "°")
            .font(PixelFont.hero(size: 30))
            .foregroundStyle(TemperatureBand.make(temp: temp, units: units).colors.gradient)
            .shadow(color: TemperatureColors.outline, radius: 0, x: 2, y: 2)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
    }
}

#Preview(as: .systemSmall) {
    PlayerHUDWidget()
} timeline: {
    SnapshotEntry(date: WidgetSnapshot.sample.updatedAt, snapshot: .sample)
    SnapshotEntry(date: .now, snapshot: .sample)
    SnapshotEntry(date: .now, snapshot: nil)
}
