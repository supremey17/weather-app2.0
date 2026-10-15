import SwiftUI
import WidgetKit

/// Lock screen accessories. The OS renders these monochrome/vibrant, so they lean on shape and
/// text rather than the theme's colors.
struct LockScreenGaugesWidget: Widget {
    static let kind = "LockScreenGaugesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            LockScreenGaugesView(entry: entry)
                .containerBackground(for: .widget) { Color.clear }
        }
        .configurationDisplayName("Lock Screen Gauges")
        .description("Rain-chance mana ring, stage readout and a one-line HUD.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }

    /// Chance of rain for the hour in progress at `date` (or the next one if none has started):
    /// the first hour that hasn't ended yet.
    static func nextHourChance(in hourly: [WidgetSnapshot.Hour], at date: Date) -> Int? {
        let now = date.timeIntervalSince1970
        return hourly.first { TimeInterval($0.epoch + 3600) > now }?.chanceOfRain
    }
}

private struct LockScreenGaugesView: View {
    let entry: SnapshotEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        if let snapshot = entry.snapshot {
            switch family {
            case .accessoryCircular: circular(snapshot)
            case .accessoryInline: inline(snapshot)
            default: rectangular(snapshot)
            }
        } else {
            switch family {
            case .accessoryInline: Text("PRESS START")
            default: Text("PRESS START").pixelFont(.caption).multilineTextAlignment(.center)
            }
        }
    }

    private func temp(_ snapshot: WidgetSnapshot) -> String {
        TemperatureReadoutFormat.number(snapshot.temp) + "°"
    }

    private func circular(_ snapshot: WidgetSnapshot) -> some View {
        let chance = LockScreenGaugesWidget.nextHourChance(in: snapshot.hourly, at: entry.date)
        return ZStack {
            AccessoryWidgetBackground()
            Gauge(value: Double(chance ?? 0), in: 0...100) {
                Image(systemName: "drop.fill")
            } currentValueLabel: {
                Text(chance.map { "\($0)%" } ?? "--")
                    .font(PixelFont.hero(size: 10))
                    .minimumScaleFactor(0.6)
            }
            .gaugeStyle(.accessoryCircular)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(chance.map { "\($0) percent chance of rain this hour" } ?? "Rain chance unavailable")
    }

    private func rectangular(_ snapshot: WidgetSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(snapshot.city)
                .pixelFont(.label)
                .lineLimit(1)
            HStack(spacing: 4) {
                Text(temp(snapshot)).font(PixelFont.hero(size: 12))
                Text(snapshot.condition)
                    .pixelFont(.caption)
                    .lineLimit(1)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(PlayerHUDWidget.accessibilityLabel(for: snapshot))
            if let low = snapshot.low, let high = snapshot.high,
               let fraction = PlayerHUDWidget.hpFraction(temp: snapshot.temp, low: low, high: high) {
                Text("L\(TemperatureReadoutFormat.number(low)) \(PlayerHUDWidget.hpBarText(fraction: fraction)) H\(TemperatureReadoutFormat.number(high))")
                    .pixelFont(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .accessibilityLabel("Low \(TemperatureReadoutFormat.number(low)), high \(TemperatureReadoutFormat.number(high))")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func inline(_ snapshot: WidgetSnapshot) -> some View {
        Label("\(temp(snapshot)) \(snapshot.city)", systemImage: snapshot.weatherTheme.sceneSymbol)
            .accessibilityLabel(PlayerHUDWidget.accessibilityLabel(for: snapshot))
    }
}

#Preview(as: .accessoryCircular) {
    LockScreenGaugesWidget()
} timeline: {
    SnapshotEntry(date: WidgetSnapshot.sample.updatedAt.addingTimeInterval(4000), snapshot: .sample)
    SnapshotEntry(date: .now, snapshot: nil)
}

#Preview(as: .accessoryRectangular) {
    LockScreenGaugesWidget()
} timeline: {
    SnapshotEntry(date: WidgetSnapshot.sample.updatedAt, snapshot: .sample)
    SnapshotEntry(date: .now, snapshot: nil)
}

#Preview(as: .accessoryInline) {
    LockScreenGaugesWidget()
} timeline: {
    SnapshotEntry(date: WidgetSnapshot.sample.updatedAt, snapshot: .sample)
}
