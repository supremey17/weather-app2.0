import SwiftUI

/// A small, value-type palette that is derived from the weather response already in memory.
/// It deliberately contains no network image or animation state.
enum PixelWeatherTheme: String, Equatable {
    case clearDay
    case clearNight
    case cloudy
    case rainy
    case stormy
    case snowy
    case misty
    case neutral

    static func make(condition: String, epochSeconds: Int?, timeZoneOffset: Int?) -> PixelWeatherTheme {
        switch condition {
        case "Clear":
            return isNight(epochSeconds: epochSeconds, timeZoneOffset: timeZoneOffset) ? .clearNight : .clearDay
        case "Clouds":
            return .cloudy
        case "Rain", "Drizzle":
            return .rainy
        case "Thunderstorm":
            return .stormy
        case "Snow":
            return .snowy
        case "Mist", "Fog", "Haze", "Smoke", "Dust", "Sand", "Ash", "Squall", "Tornado":
            return .misty
        default:
            return .neutral
        }
    }

    var skyColor: Color {
        switch self {
        case .clearDay: .init(red: 0.26, green: 0.72, blue: 0.91)
        case .clearNight: .init(red: 0.08, green: 0.12, blue: 0.31)
        case .cloudy: .init(red: 0.34, green: 0.44, blue: 0.56)
        case .rainy: .init(red: 0.08, green: 0.31, blue: 0.49)
        case .stormy: .init(red: 0.18, green: 0.13, blue: 0.39)
        case .snowy: .init(red: 0.63, green: 0.82, blue: 0.91)
        case .misty: .init(red: 0.45, green: 0.54, blue: 0.60)
        case .neutral: .init(red: 0.20, green: 0.33, blue: 0.43)
        }
    }

    var horizonColor: Color {
        switch self {
        case .clearDay: .init(red: 0.18, green: 0.55, blue: 0.39)
        case .clearNight: .init(red: 0.11, green: 0.25, blue: 0.29)
        case .cloudy: .init(red: 0.23, green: 0.40, blue: 0.40)
        case .rainy: .init(red: 0.06, green: 0.25, blue: 0.29)
        case .stormy: .init(red: 0.13, green: 0.12, blue: 0.27)
        case .snowy: .init(red: 0.88, green: 0.94, blue: 0.96)
        case .misty: .init(red: 0.36, green: 0.47, blue: 0.46)
        case .neutral: .init(red: 0.16, green: 0.37, blue: 0.34)
        }
    }

    var panelColor: Color { .init(red: 0.05, green: 0.10, blue: 0.16) }
    /// Text color for a `.standard`-style panel. Kept for existing call sites; prefer
    /// `textColor(on:)` for panel styles that can render with a light fill.
    var panelTextColor: Color { textColor(on: .standard) }
    var accentColor: Color {
        switch self {
        case .clearDay: .init(red: 1.0, green: 0.78, blue: 0.20)
        case .clearNight: .init(red: 0.72, green: 0.68, blue: 1.0)
        case .cloudy: .init(red: 0.72, green: 0.84, blue: 0.92)
        case .rainy: .init(red: 0.28, green: 0.82, blue: 0.94)
        case .stormy: .init(red: 0.93, green: 0.76, blue: 0.24)
        case .snowy: .init(red: 0.14, green: 0.35, blue: 0.60)
        case .misty: .init(red: 0.82, green: 0.88, blue: 0.86)
        case .neutral: .init(red: 0.41, green: 0.89, blue: 0.71)
        }
    }

    var sceneSymbol: String {
        switch self {
        case .clearDay: "sun.max.fill"
        case .clearNight: "moon.stars.fill"
        case .cloudy: "cloud.fill"
        case .rainy: "cloud.rain.fill"
        case .stormy: "cloud.bolt.rain.fill"
        case .snowy: "snowflake"
        case .misty: "cloud.fog.fill"
        case .neutral: "cloud.sun.fill"
        }
    }

    var supportsAmbientMotion: Bool {
        self == .rainy || self == .stormy || self == .snowy || self == .cloudy
    }

    private static func isNight(epochSeconds: Int?, timeZoneOffset: Int?) -> Bool {
        guard let epochSeconds else { return false }
        let date = Date(timeIntervalSince1970: TimeInterval(epochSeconds))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: timeZoneOffset ?? 0) ?? .current
        let hour = calendar.component(.hour, from: date)
        return hour < 6 || hour >= 20
    }
}

// MARK: - Palette

/// Extended colors for the pixel-game restyle: layered parallax scenery and the
/// wood / showroom / HUD panel finishes, on top of the original theme colors above.
struct PixelPalette {
    let skyTop: Color
    let skyBottom: Color
    let farHill: Color
    let nearHill: Color
    let ground: Color
    let panelHighlight: Color
    let panelShade: Color
    let wood: Color
    let woodTrim: Color
    let showroomPanel: Color
    let hud: Color
    let neon: Color
}

extension PixelWeatherTheme {
    var palette: PixelPalette {
        switch self {
        case .clearDay:
            PixelPalette(
                skyTop: .init(red: 0.31, green: 0.76, blue: 0.97),
                skyBottom: .init(red: 0.70, green: 0.90, blue: 0.99),
                farHill: .init(red: 0.18, green: 0.55, blue: 0.34),
                nearHill: .init(red: 0.36, green: 0.73, blue: 0.39),
                ground: .init(red: 0.55, green: 0.83, blue: 0.29),
                panelHighlight: .white,
                panelShade: .init(red: 0.85, green: 0.77, blue: 0.60),
                wood: .init(red: 0.48, green: 0.31, blue: 0.18),
                woodTrim: .init(red: 0.75, green: 0.52, blue: 0.32),
                showroomPanel: .init(red: 1.0, green: 0.96, blue: 0.84),
                hud: .init(red: 1.0, green: 0.98, blue: 0.91),
                neon: .init(red: 1.0, green: 0.76, blue: 0.28)
            )
        case .clearNight:
            PixelPalette(
                skyTop: .init(red: 0.04, green: 0.04, blue: 0.12),
                skyBottom: .init(red: 0.11, green: 0.11, blue: 0.23),
                farHill: .init(red: 0.08, green: 0.08, blue: 0.17),
                nearHill: .init(red: 0.12, green: 0.12, blue: 0.25),
                ground: .init(red: 0.06, green: 0.06, blue: 0.14),
                panelHighlight: .init(red: 1.0, green: 0.24, blue: 0.65).opacity(0.3),
                panelShade: .init(red: 0.03, green: 0.03, blue: 0.09),
                wood: .init(red: 0.08, green: 0.08, blue: 0.17),
                woodTrim: .init(red: 0.24, green: 0.94, blue: 1.0),
                showroomPanel: .init(red: 0.11, green: 0.11, blue: 0.24),
                hud: .init(red: 0.06, green: 0.06, blue: 0.15),
                neon: .init(red: 1.0, green: 0.24, blue: 0.65)
            )
        case .cloudy:
            PixelPalette(
                skyTop: .init(red: 0.34, green: 0.44, blue: 0.56),
                skyBottom: .init(red: 0.52, green: 0.61, blue: 0.70),
                farHill: .init(red: 0.42, green: 0.56, blue: 0.44),
                nearHill: .init(red: 0.53, green: 0.67, blue: 0.55),
                ground: .init(red: 0.66, green: 0.78, blue: 0.68),
                panelHighlight: .init(red: 0.75, green: 0.52, blue: 0.32),
                panelShade: .init(red: 0.31, green: 0.19, blue: 0.10),
                wood: .init(red: 0.48, green: 0.31, blue: 0.18),
                woodTrim: .init(red: 0.75, green: 0.52, blue: 0.32),
                showroomPanel: .init(red: 0.48, green: 0.31, blue: 0.18),
                hud: .init(red: 0.61, green: 0.42, blue: 0.24),
                neon: .init(red: 0.72, green: 0.84, blue: 0.92)
            )
        case .rainy:
            PixelPalette(
                skyTop: .init(red: 0.08, green: 0.31, blue: 0.49),
                skyBottom: .init(red: 0.11, green: 0.36, blue: 0.46),
                farHill: .init(red: 0.05, green: 0.29, blue: 0.27),
                nearHill: .init(red: 0.08, green: 0.42, blue: 0.37),
                ground: .init(red: 0.04, green: 0.23, blue: 0.21),
                panelHighlight: .init(red: 0.28, green: 0.82, blue: 0.94).opacity(0.3),
                panelShade: .init(red: 0.03, green: 0.14, blue: 0.17),
                wood: .init(red: 0.04, green: 0.18, blue: 0.22),
                woodTrim: .init(red: 0.28, green: 0.82, blue: 0.94),
                showroomPanel: .init(red: 0.04, green: 0.18, blue: 0.22),
                hud: .init(red: 0.07, green: 0.20, blue: 0.27),
                neon: .init(red: 0.28, green: 0.82, blue: 0.94)
            )
        case .stormy:
            PixelPalette(
                skyTop: .init(red: 0.18, green: 0.13, blue: 0.39),
                skyBottom: .init(red: 0.18, green: 0.14, blue: 0.38),
                farHill: .init(red: 0.12, green: 0.09, blue: 0.25),
                nearHill: .init(red: 0.17, green: 0.14, blue: 0.35),
                ground: .init(red: 0.08, green: 0.06, blue: 0.17),
                panelHighlight: .init(red: 0.93, green: 0.76, blue: 0.24).opacity(0.3),
                panelShade: .init(red: 0.08, green: 0.06, blue: 0.18),
                wood: .init(red: 0.11, green: 0.09, blue: 0.25),
                woodTrim: .init(red: 0.93, green: 0.76, blue: 0.24),
                showroomPanel: .init(red: 0.11, green: 0.09, blue: 0.25),
                hud: .init(red: 0.14, green: 0.11, blue: 0.30),
                neon: .init(red: 0.93, green: 0.76, blue: 0.24)
            )
        case .snowy:
            PixelPalette(
                skyTop: .init(red: 0.63, green: 0.82, blue: 0.91),
                skyBottom: .init(red: 0.91, green: 0.97, blue: 0.98),
                farHill: .init(red: 0.80, green: 0.91, blue: 0.94),
                nearHill: .init(red: 0.91, green: 0.97, blue: 0.98),
                ground: .init(red: 0.96, green: 0.99, blue: 1.0),
                panelHighlight: .white,
                panelShade: .init(red: 0.66, green: 0.80, blue: 0.84),
                wood: .init(red: 0.86, green: 0.94, blue: 0.96),
                woodTrim: .init(red: 0.14, green: 0.35, blue: 0.60),
                showroomPanel: .init(red: 0.86, green: 0.94, blue: 0.96),
                hud: .init(red: 0.92, green: 0.97, blue: 0.98),
                neon: .init(red: 0.56, green: 0.85, blue: 0.94)
            )
        case .misty:
            PixelPalette(
                skyTop: .init(red: 0.45, green: 0.54, blue: 0.60),
                skyBottom: .init(red: 0.56, green: 0.64, blue: 0.68),
                farHill: .init(red: 0.36, green: 0.42, blue: 0.41),
                nearHill: .init(red: 0.48, green: 0.55, blue: 0.53),
                ground: .init(red: 0.56, green: 0.63, blue: 0.61),
                panelHighlight: .white.opacity(0.2),
                panelShade: .init(red: 0.20, green: 0.24, blue: 0.23),
                wood: .init(red: 0.29, green: 0.34, blue: 0.33),
                woodTrim: .init(red: 0.82, green: 0.88, blue: 0.86),
                showroomPanel: .init(red: 0.29, green: 0.34, blue: 0.33),
                hud: .init(red: 0.33, green: 0.38, blue: 0.37),
                neon: .init(red: 0.82, green: 0.88, blue: 0.86)
            )
        case .neutral:
            PixelPalette(
                skyTop: .init(red: 0.20, green: 0.33, blue: 0.43),
                skyBottom: .init(red: 0.23, green: 0.40, blue: 0.40),
                farHill: .init(red: 0.12, green: 0.29, blue: 0.26),
                nearHill: .init(red: 0.18, green: 0.42, blue: 0.37),
                ground: .init(red: 0.13, green: 0.35, blue: 0.30),
                panelHighlight: .init(red: 0.41, green: 0.89, blue: 0.71).opacity(0.3),
                panelShade: .init(red: 0.06, green: 0.12, blue: 0.16),
                wood: .init(red: 0.09, green: 0.19, blue: 0.24),
                woodTrim: .init(red: 0.41, green: 0.89, blue: 0.71),
                showroomPanel: .init(red: 0.09, green: 0.19, blue: 0.24),
                hud: .init(red: 0.11, green: 0.23, blue: 0.28),
                neon: .init(red: 0.41, green: 0.89, blue: 0.71)
            )
        }
    }

    /// The original sprite each weather theme is drawn with, used by the hero scene.
    var spriteKind: PixelSpriteKind {
        switch self {
        case .clearDay: .sun
        case .clearNight: .moon
        case .cloudy: .cloud
        case .rainy: .rain
        case .stormy: .storm
        case .snowy: .snow
        case .misty: .fog
        case .neutral: .cloudSun
        }
    }
}

// MARK: - Contrast-aware text colors

/// Centralizes "what panel fill does this theme render with, and what text color reads on
/// it" so panel contrast logic lives in one place instead of drifting between `PixelPanel`
/// and call sites that pick their own hard-coded colors.
extension PixelWeatherTheme {
    /// Relative luminance (WCAG 2.1, 0...1 range) of a color given as 0...1 sRGB components.
    /// Reference: https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
    private static func luminance(red: Double, green: Double, blue: Double) -> Double {
        func linearize(_ component: Double) -> Double {
            let clamped = min(max(component, 0), 1)
            return clamped <= 0.03928 ? clamped / 12.92 : pow((clamped + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linearize(red) + 0.7152 * linearize(green) + 0.0722 * linearize(blue)
    }

    /// Best-effort relative luminance of a `Color`.
    ///
    /// Every color this is called with in this file is authored as a plain
    /// `.init(red:green:blue:)` literal, so resolving through `UIColor` is synchronous and has
    /// no environment/trait dependency (no `EnvironmentValues`, no trait collection lookup).
    /// If a color's RGB components can't be read for some reason, this falls back to `0`
    /// ("treat as dark"), which preserves the original white-on-dark-navy behavior rather than
    /// risking an unreadable light-on-light result.
    private static func luminance(of color: Color) -> Double {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        guard UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return 0
        }
        return luminance(red: Double(red), green: Double(green), blue: Double(blue))
    }

    /// WCAG 2.1 contrast ratio between two relative luminances, in 1...21.
    private static func contrastRatio(_ luminanceA: Double, _ luminanceB: Double) -> Double {
        let lighter = max(luminanceA, luminanceB)
        let darker = min(luminanceA, luminanceB)
        return (lighter + 0.05) / (darker + 0.05)
    }

    /// Fills at or above this luminance are light enough that white text is unreadable on them.
    private static let lightFillLuminanceThreshold = 0.5

    /// Minimum contrast ratio an accent color needs against a panel fill to be used as text.
    private static let minimumAccentContrastRatio = 4.5

    /// The fill color `PixelPanel` renders for a given style on this theme. `PixelPanel.fill`
    /// delegates to this so the "what does style X look like on theme Y" decision can't drift
    /// between the panel view and the text-contrast logic below.
    func fill(for style: PixelPanelStyle) -> Color {
        switch style {
        case .standard: panelColor.opacity(0.94)
        case .wood: palette.wood
        case .showroom: palette.showroomPanel
        case .hud: palette.hud
        }
    }

    /// A readable text color for content drawn on the fill `PixelPanel` renders for `style`:
    /// the theme's dark navy `panelColor` when that fill is light, otherwise white.
    ///
    /// `panelTextColor` is `textColor(on: .standard)`, kept as a separate property so existing
    /// call sites that only ever draw on `.standard` panels keep working unchanged.
    func textColor(on style: PixelPanelStyle) -> Color {
        Self.luminance(of: fill(for: style)) >= Self.lightFillLuminanceThreshold ? panelColor : .white
    }

    /// A readable text color for an accent-colored heading drawn on the fill `PixelPanel`
    /// renders for `style` (e.g. the "GARAGE · LOADOUT" title). Keeps `accentColor` itself when
    /// it already has enough contrast against that fill, otherwise falls back to the same
    /// dark-ink/white choice as `textColor(on:)`.
    func accentText(on style: PixelPanelStyle) -> Color {
        let fillLuminance = Self.luminance(of: fill(for: style))
        let accentLuminance = Self.luminance(of: accentColor)
        let ratio = Self.contrastRatio(fillLuminance, accentLuminance)
        return ratio >= Self.minimumAccentContrastRatio ? accentColor : textColor(on: style)
    }

    /// Text color for content drawn directly over the sky gradient / parallax scene (the hero
    /// scene and the navigation toolbar in `ContentView`), rather than over a panel fill.
    /// Only `.clearDay` and `.snowy` skies are light enough to need dark ink; every other theme
    /// keeps the original white.
    var skyTextColor: Color {
        switch self {
        case .clearDay, .snowy: panelColor
        default: .white
        }
    }

    /// Sprite tint matching `skyTextColor`, for icons drawn directly over the sky.
    var skyTint: Color { skyTextColor }
}

// MARK: - Fonts

/// Bundled OFL pixel fonts (Press Start 2P for display/numbers, Silkscreen for everything
/// else), wired through `Font.custom(_:size:relativeTo:)` so Dynamic Type still scales them.
enum PixelFont {
    enum Role {
        case display
        case title
        case headline
        case body
        case label
        case caption
        case number
    }

    static func font(_ role: Role) -> Font {
        switch role {
        case .display: .custom("PressStart2P-Regular", size: 20, relativeTo: .title)
        case .title: .custom("PressStart2P-Regular", size: 14, relativeTo: .title3)
        case .headline: .custom("Silkscreen-Bold", size: 16, relativeTo: .headline)
        case .body: .custom("Silkscreen-Regular", size: 15, relativeTo: .body)
        case .label: .custom("Silkscreen-Bold", size: 12, relativeTo: .subheadline)
        case .caption: .custom("Silkscreen-Regular", size: 11, relativeTo: .caption)
        case .number: .custom("PressStart2P-Regular", size: 13, relativeTo: .headline)
        }
    }
}

extension View {
    func pixelFont(_ role: PixelFont.Role) -> some View {
        font(PixelFont.font(role))
    }
}

// MARK: - Shapes

/// A square frame with stepped, notched corners instead of rounded ones, matching
/// the blocky window frames of 8/16-bit era game UIs.
struct PixelBevelShape: InsettableShape {
    var notch: CGFloat = 4
    private var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        guard insetRect.width > 0, insetRect.height > 0 else { return path }
        let n = min(notch, min(insetRect.width, insetRect.height) / 2)
        path.move(to: CGPoint(x: insetRect.minX + n, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX - n, y: insetRect.minY))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.minY + n))
        path.addLine(to: CGPoint(x: insetRect.maxX, y: insetRect.maxY - n))
        path.addLine(to: CGPoint(x: insetRect.maxX - n, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.minX + n, y: insetRect.maxY))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.maxY - n))
        path.addLine(to: CGPoint(x: insetRect.minX, y: insetRect.minY + n))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> PixelBevelShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

// MARK: - Panels

enum PixelPanelStyle {
    /// Dark navy panel, used for most HUD-style readouts.
    case standard
    /// Warm wooden frame, Stardew/Kairosoft-style menu.
    case wood
    /// Neon-trimmed showroom card, Car Racer garage-style.
    case showroom
    /// Light HUD chip, Pixel Pro Golf-style readout.
    case hud
}

struct PixelPanel<Content: View>: View {
    let theme: PixelWeatherTheme
    var style: PixelPanelStyle = .standard
    var padding: CGFloat = 14
    let content: Content

    init(
        theme: PixelWeatherTheme,
        style: PixelPanelStyle = .standard,
        padding: CGFloat = 14,
        @ViewBuilder content: () -> Content
    ) {
        self.theme = theme
        self.style = style
        self.padding = padding
        self.content = content()
    }

    private var fill: Color {
        theme.fill(for: style)
    }

    private var borderColor: Color {
        switch style {
        case .showroom: theme.palette.neon
        case .wood: theme.palette.woodTrim
        case .hud: theme.accentColor
        case .standard: theme.accentColor
        }
    }

    var body: some View {
        content
            .padding(padding)
            .background(fill)
            .overlay {
                PixelBevelShape()
                    .inset(by: 2.5)
                    .stroke(Color.white.opacity(0.22), lineWidth: 1)
            }
            .overlay {
                PixelBevelShape()
                    .stroke(borderColor.opacity(0.9), lineWidth: 2)
            }
            .clipShape(PixelBevelShape())
            .shadow(color: .black.opacity(0.28), radius: 0, x: 3, y: 3)
    }
}

// MARK: - Buttons

/// Unified pixel button: the bevel flips and the content nudges down-right when pressed,
/// mimicking a physical button being pushed into a sprite sheet.
struct PixelButtonStyle: ButtonStyle {
    enum Kind {
        case primary
        case secondary
        case icon
    }

    let theme: PixelWeatherTheme
    var kind: Kind = .primary

    private var background: Color {
        switch kind {
        case .primary, .icon: theme.accentColor
        case .secondary: theme.palette.hud
        }
    }

    private var foreground: Color {
        switch kind {
        case .primary, .icon: theme.panelColor
        case .secondary: theme.textColor(on: .hud)
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        configuration.label
            .pixelFont(.label)
            .foregroundStyle(foreground)
            .padding(kind == .icon ? 9 : 10)
            .background(background)
            .overlay {
                PixelBevelShape(notch: 3)
                    .stroke(isPressed ? Color.black.opacity(0.4) : Color.white.opacity(0.3), lineWidth: 1)
            }
            .clipShape(PixelBevelShape(notch: 3))
            .offset(x: isPressed ? 2 : 0, y: isPressed ? 2 : 0)
            .shadow(color: .black.opacity(isPressed ? 0 : 0.3), radius: 0, x: isPressed ? 0 : 2, y: isPressed ? 0 : 2)
    }
}

/// Thin wrappers kept so call sites written against the original two-style API
/// (icon buttons and text buttons) still compile unchanged.
struct PixelIconButtonStyle: ButtonStyle {
    let theme: PixelWeatherTheme

    func makeBody(configuration: Configuration) -> some View {
        PixelButtonStyle(theme: theme, kind: .icon).makeBody(configuration: configuration)
    }
}

struct PixelTextButtonStyle: ButtonStyle {
    let theme: PixelWeatherTheme

    func makeBody(configuration: Configuration) -> some View {
        PixelButtonStyle(theme: theme, kind: .primary).makeBody(configuration: configuration)
    }
}

// MARK: - Stat bar

/// A chunky, segmented progress indicator in the style of old sports-game HUDs.
struct PixelStatBar: View {
    let value: Double
    var segments: Int = 10
    let theme: PixelWeatherTheme

    private var filledCount: Int {
        let clamped = min(max(value, 0), 1)
        return Int((clamped * Double(max(segments, 1))).rounded())
    }

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<max(segments, 1), id: \.self) { index in
                Rectangle()
                    .fill(index < filledCount ? theme.accentColor : theme.palette.panelShade)
                    .frame(width: 8, height: 12)
            }
        }
        .accessibilityHidden(true)
    }
}

// MARK: - Parallax scene

/// Layered pixel hills with a stepped (not tweened) sun/moon and weather particles,
/// replacing the old flat sky + horizon band.
struct PixelParallaxScene: View {
    let theme: PixelWeatherTheme
    var animate: Bool = true
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool {
        animate && !reduceMotion && scenePhase == .active
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: shouldAnimate ? 0.25 : 60)) { timeline in
            let step = shouldAnimate ? Int(timeline.date.timeIntervalSinceReferenceDate / 0.25) : 0
            GeometryReader { proxy in
                let width = proxy.size.width
                let height = proxy.size.height
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [theme.palette.skyTop, theme.palette.skyBottom],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    PixelHillLayer(color: theme.palette.farHill, heightFraction: 0.34, columns: 9, step: step, speed: 1)
                    PixelHillLayer(color: theme.palette.nearHill, heightFraction: 0.22, columns: 7, step: step, speed: 2)

                    Rectangle()
                        .fill(theme.palette.ground)
                        .frame(height: height * 0.10)

                    PixelSprite(theme.spriteKind, scale: 3)
                        .position(x: width * 0.78, y: height * 0.24)

                    if theme.supportsAmbientMotion {
                        PixelWeatherParticles(theme: theme, step: step)
                    }
                }
            }
        }
        .clipped()
        .accessibilityHidden(true)
    }
}

private struct PixelHillLayer: View {
    let color: Color
    let heightFraction: CGFloat
    let columns: Int
    let step: Int
    let speed: Int

    var body: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let height = proxy.size.height
            let hillHeight = height * heightFraction
            let colWidth = width / CGFloat(columns)
            let shift = CGFloat((step * speed) % max(columns, 1)) * colWidth

            HStack(spacing: 0) {
                ForEach(0..<(columns * 2), id: \.self) { index in
                    let bump: CGFloat = index.isMultiple(of: 2) ? 1.0 : 0.72
                    Rectangle()
                        .fill(color)
                        .frame(width: colWidth, height: hillHeight * bump)
                }
            }
            .frame(width: colWidth * CGFloat(columns * 2), height: height, alignment: .bottom)
            .offset(x: -shift)
            .frame(width: width, height: height, alignment: .bottomLeading)
            .clipped()
        }
    }
}

private struct PixelWeatherParticles: View {
    let theme: PixelWeatherTheme
    let step: Int

    var body: some View {
        GeometryReader { proxy in
            let width = max(Int(proxy.size.width), 1)
            let height = max(Int(proxy.size.height), 1)
            ForEach(0..<12, id: \.self) { index in
                Rectangle()
                    .fill(theme == .snowy ? Color.white.opacity(0.85) : theme.palette.neon.opacity(0.75))
                    .frame(width: theme == .snowy ? 4 : 2, height: theme == .snowy ? 4 : 14)
                    .position(
                        x: CGFloat((index * 43) % width),
                        y: CGFloat((index * 31 + step * 17) % height)
                    )
            }
        }
        .clipped()
    }
}
