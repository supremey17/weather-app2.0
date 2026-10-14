import Foundation

/// A switchable decorative backdrop for the main page. `.weather` is the default weather-reactive
/// pixel sky and hills; the rest are purely cosmetic scenes that the weather
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

    /// Custom artwork shown instead of the drawn stock scene. Only Space has one; every other
    /// backdrop is always its stock pixel scene.
    var assetName: String? {
        self == .space ? "background-space" : nil
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
