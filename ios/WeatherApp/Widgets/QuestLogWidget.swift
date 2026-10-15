import SwiftUI
import WidgetKit

/// Medium widget: the next few forecast hours as a level-select strip, the current hour marked
/// "YOU ARE HERE".
struct QuestLogWidget: Widget {
    static let kind = "QuestLogWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            QuestLogView(entry: entry)
        }
        .configurationDisplayName("Quest Log")
        .description("The next five hours as a level map.")
        .supportedFamilies([.systemMedium])
    }

    /// Hours that haven't fully passed at `date` (the one containing `date` stays), in order,
    /// capped at `count`.
    static func visibleHours(_ hourly: [WidgetSnapshot.Hour], at date: Date, count: Int = 5) -> [WidgetSnapshot.Hour] {
        let now = date.timeIntervalSince1970
        return Array(hourly.filter { TimeInterval($0.epoch + 3600) > now }.prefix(max(count, 0)))
    }

    static func isCurrent(_ hour: WidgetSnapshot.Hour, at date: Date) -> Bool {
        let now = date.timeIntervalSince1970
        return TimeInterval(hour.epoch) <= now && now < TimeInterval(hour.epoch + 3600)
    }
}

private struct QuestLogView: View {
    let entry: SnapshotEntry

    var body: some View {
        if let snapshot = entry.snapshot {
            let theme = snapshot.weatherTheme
            let hours = QuestLogWidget.visibleHours(snapshot.hourly, at: entry.date)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("QUEST LOG")
                        .pixelFont(.title)
                        .foregroundStyle(theme.accentColor)
                    Text(verbatim: snapshot.city)
                        .pixelFont(.caption)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if snapshot.isStale(at: entry.date) {
                        Text("STALE")
                            .pixelFont(.caption)
                            .padding(.horizontal, 4)
                            .background(Color.red.opacity(0.8), in: PixelBevelShape(notch: 2))
                    }
                }
                .foregroundStyle(theme.skyTextColor)

                if hours.isEmpty {
                    Spacer(minLength: 0)
                    Text("NO QUESTS — open app")
                        .pixelFont(.label)
                        .foregroundStyle(theme.skyTextColor)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                } else {
                    HStack(alignment: .bottom, spacing: 4) {
                        ForEach(hours, id: \.epoch) { hour in
                            QuestTile(hour: hour, isCurrent: QuestLogWidget.isCurrent(hour, at: entry.date), theme: theme)
                        }
                    }
                    .frame(maxHeight: .infinity, alignment: .bottom)
                }
            }
            .pixelWidgetBackground(theme)
        } else {
            PressStartView()
                .pixelWidgetBackground(.neutral)
        }
    }
}

private struct QuestTile: View {
    let hour: WidgetSnapshot.Hour
    let isCurrent: Bool
    let theme: PixelWeatherTheme

    /// `PixelRainDropGauge` is 33x42pt; shrink it to fit five tiles in a medium widget.
    private static let gaugeScale: CGFloat = 0.7

    var body: some View {
        VStack(spacing: 2) {
            // "YOU ARE HERE" doesn't fit a ~56pt tile at pixel font sizes, so the arrow carries it.
            Text("▼")
                .font(.system(size: 9, weight: .black))
                .foregroundStyle(theme.accentColor)
                .opacity(isCurrent ? 1 : 0)
                .accessibilityHidden(true)

            VStack(spacing: 2) {
                Text(verbatim: isCurrent ? "NOW" : hour.time)
                    .pixelFont(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                PixelSprite(PixelSpriteKind(sfSymbol: hour.symbol), scale: 1.25)
                    .frame(height: 20)
                Text(verbatim: hour.temp)
                    .pixelFont(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                PixelRainDropGauge(chance: hour.chanceOfRain, theme: theme)
                    .scaleEffect(Self.gaugeScale)
                    .frame(width: 33 * Self.gaugeScale, height: 42 * Self.gaugeScale)
            }
            .foregroundStyle(theme.textColor(on: .standard))
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity)
            .background(theme.fill(for: .standard), in: PixelBevelShape(notch: 3))
            .overlay(
                PixelBevelShape(notch: 3)
                    .strokeBorder(isCurrent ? theme.accentColor : theme.palette.panelShade, lineWidth: isCurrent ? 2 : 1)
            )
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(isCurrent ? "Now" : hour.time), \(hour.temp), \(hour.chanceOfRain)% chance of rain")
    }
}

#Preview(as: .systemMedium) {
    QuestLogWidget()
} timeline: {
    SnapshotEntry(date: Date(timeIntervalSince1970: 1_800_000_000 + 1800), snapshot: .sample)
    SnapshotEntry(date: Date(timeIntervalSince1970: 1_800_000_000 + 4 * 3600 + 60), snapshot: .sample)
    SnapshotEntry(date: Date(timeIntervalSince1970: 1_800_000_000 + 4 * 3600 + 60), snapshot: nil)
}
