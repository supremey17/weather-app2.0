import Foundation

/// A switchable decorative backdrop for the main page. `.weather` is the existing weather-reactive
/// sky/hills look (today's only option); the rest are purely cosmetic scenes that the weather
/// particle layer and the day/night tint always render on top of — see
/// `PixelBackgroundScenes.swift` for how each one is drawn, and `Preferences.selectedBackground`
/// for how the choice is persisted.
enum PixelBackground: String, CaseIterable, Identifiable {
    case weather
    case space
    case cherryBlossom
    case mountains
    case river
    case ocean
    case beach

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .weather: "WEATHER"
        case .space: "SPACE"
        case .cherryBlossom: "BLOSSOM"
        case .mountains: "MOUNTAINS"
        case .river: "RIVER"
        case .ocean: "OCEAN"
        case .beach: "BEACH"
        }
    }

    /// The `Assets.xcassets` imageset a custom override lives in, or `nil` for `.weather` (which
    /// has no custom-art slot — it's the existing theme-driven sky, not a static scene). Scaffolded
    /// as empty slots; `PixelBackgroundLayer` falls back to the procedural scene when empty, same
    /// pattern as `AvatarAccessory.assetName`.
    var assetName: String? {
        switch self {
        case .weather: nil
        case .space: "background-space"
        case .cherryBlossom: "background-cherryblossom"
        case .mountains: "background-mountains"
        case .river: "background-river"
        case .ocean: "background-ocean"
        case .beach: "background-beach"
        }
    }

    /// Whether this background's own scene has ambient motion (twinkling stars, drifting petals,
    /// waves, …) and therefore needs the shared `PixelClock` running. `.weather` is driven by the
    /// existing theme/particle logic, not by this flag.
    var isAnimated: Bool {
        self != .weather
    }

    /// Steps to the next (`forward: true`) or previous backdrop, wrapping at both ends. There's no
    /// "none" slot here (unlike accessories) — `.weather` is itself a valid, always-present choice.
    static func cycled(from current: PixelBackground, forward: Bool) -> PixelBackground {
        let all = allCases
        guard let currentIndex = all.firstIndex(of: current) else { return .weather }
        let step = forward ? 1 : -1
        let count = all.count
        let nextIndex = ((currentIndex + step) % count + count) % count
        return all[nextIndex]
    }
}
