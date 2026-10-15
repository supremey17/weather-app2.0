import SwiftUI
import WidgetKit

/// RPG inventory screen: each clothing-advice line becomes an item in one of four slots.
struct LoadoutWidget: Widget {
    static let kind = "LoadoutWidget"
    static let slotCount = 4

    struct Item: Equatable {
        let sprite: PixelSpriteKind
        let name: String
        /// The full advice line, shown in the description box and read by VoiceOver.
        let detail: String
    }

    /// Keywords from `ClothingAdvisor`'s lines; first match wins, so "Snow ... winter coat" is
    /// BOOTS, not a cold-weather JACKET.
    private static let catalog: [(keywords: [String], sprite: PixelSpriteKind, name: String)] = [
        (["snow", "boots"], .snow, "BOOTS"),
        (["raincoat", "rain", "shower"], .rain, "RAINCOAT"),
        (["humid", "linen"], .humidity, "LINEN"),
        (["uv", "sunscreen"], .star, "SUNSCREEN"),
        (["hot"], .sun, "SHADES"),
        (["cold", "chilly", "jacket", "brick"], .thermometer, "JACKET"),
    ]

    static func item(for advice: String) -> Item {
        // Whole words, so e.g. "brain" doesn't read as "rain".
        let words = Set(advice.lowercased().split { !$0.isLetter }.map(String.init))
        let match = catalog.first { !words.isDisjoint(with: $0.keywords) }
        return Item(sprite: match?.sprite ?? .check, name: match?.name ?? "COMFY", detail: advice)
    }

    static func items(for advice: [String]) -> [Item] {
        guard !advice.isEmpty else {
            return [Item(sprite: .check, name: "COMFY", detail: "Dress comfortably for the day.")]
        }
        return advice.prefix(slotCount).map(item(for:))
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: Self.kind, provider: SnapshotProvider()) { entry in
            LoadoutWidgetView(entry: entry)
        }
        .configurationDisplayName("Loadout")
        .description("Today's gear, as an inventory screen.")
        .supportedFamilies([.systemMedium])
    }
}

private struct LoadoutWidgetView: View {
    let entry: SnapshotEntry

    var body: some View {
        let theme = entry.snapshot?.weatherTheme ?? .neutral
        Group {
            if let snapshot = entry.snapshot {
                content(snapshot, theme: theme)
            } else {
                PressStartView()
            }
        }
        .pixelWidgetBackground(theme)
    }

    private func content(_ snapshot: WidgetSnapshot, theme: PixelWeatherTheme) -> some View {
        let items = LoadoutWidget.items(for: snapshot.advice)
        let ink = theme.textColor(on: .wood)
        return PixelPanel(theme: theme, style: .wood, padding: 8, isTranslucent: false) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 6) {
                    PixelSprite(.backpack, scale: 1.5, tint: theme.accentText(on: .wood))
                        .accessibilityHidden(true)
                    Text("LOADOUT")
                        .pixelFont(.label)
                        .foregroundStyle(theme.accentText(on: .wood))
                    Text(snapshot.city.uppercased())
                        .pixelFont(.caption)
                        .foregroundStyle(ink.opacity(0.85))
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    if snapshot.isStale(at: entry.date) {
                        Text("STALE")
                            .pixelFont(.caption)
                            .foregroundStyle(theme.panelColor)
                            .padding(.horizontal, 4)
                            .background(theme.accentColor)
                    }
                }

                HStack(spacing: 6) {
                    ForEach(0..<LoadoutWidget.slotCount, id: \.self) { index in
                        slot(index < items.count ? items[index] : nil, theme: theme)
                    }
                }

                Text(items[0].detail)
                    .pixelFont(.caption)
                    .foregroundStyle(theme.textColor(on: .hud))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(theme.palette.hud)
                    .overlay { PixelBevelShape(notch: 2).stroke(theme.palette.woodTrim, lineWidth: 1) }
                    .accessibilityHidden(true)
            }
        }
    }

    private func slot(_ item: LoadoutWidget.Item?, theme: PixelWeatherTheme) -> some View {
        VStack(spacing: 2) {
            if let item {
                PixelSprite(item.sprite, scale: 2, tint: theme.accentColor)
                Text(item.name)
                    .pixelFont(.caption)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
        }
        .padding(4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.palette.panelShade.opacity(item == nil ? 0.35 : 0.9))
        .overlay {
            PixelBevelShape(notch: 3)
                .stroke(theme.palette.woodTrim.opacity(item == nil ? 0.5 : 1), lineWidth: 2)
        }
        .clipShape(PixelBevelShape(notch: 3))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(item?.detail ?? "")
        .accessibilityHidden(item == nil)
    }
}

#Preview(as: .systemMedium) {
    LoadoutWidget()
} timeline: {
    SnapshotEntry(date: WidgetSnapshot.sample.updatedAt, snapshot: .sample)
    SnapshotEntry(date: .now, snapshot: .sample)
    SnapshotEntry(date: .now, snapshot: nil)
}
