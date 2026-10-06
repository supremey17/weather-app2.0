import SwiftUI

/// Every icon concept the app needs, standing in for the SF Symbols that used to be here.
/// Each case maps to one hand-drawn 16x16 bitmap in `PixelSpriteKind.grid` below.
enum PixelSpriteKind: String, CaseIterable {
    // Weather
    case sun
    case moon
    case cloud
    case cloudSun
    case cloudMoon
    case rain
    case snow
    case storm
    case fog

    // UI and metrics
    case search
    case star
    case starFilled
    case map
    case gear
    case location
    case backpack
    case check
    case flag
    case trash
    case drop
    case wind
    case thermometer
    case thermometerVariable
    case tempRange
    case humidity
    case gauge
    case gaugeAQI
    case eye
    case sunrise
    case sunset
    case clock
    case calendar
    case house
    case sliders
    case refresh

    /// Maps the SF Symbol names previously used across the app onto the closest original sprite,
    /// so call sites that stored a symbol string (e.g. `DetailItem.symbol`) keep working.
    init(sfSymbol: String) {
        switch sfSymbol {
        case "sun.max.fill", "sun.max": self = .sun
        case "moon.stars.fill", "moon.stars": self = .moon
        case "cloud.fill", "cloud": self = .cloud
        case "cloud.sun.fill", "cloud.sun": self = .cloudSun
        case "cloud.moon.fill", "cloud.moon": self = .cloudMoon
        case "cloud.rain.fill", "cloud.rain": self = .rain
        case "cloud.bolt.rain.fill", "cloud.bolt.rain": self = .storm
        case "snowflake", "cloud.snow": self = .snow
        case "cloud.fog.fill", "cloud.fog": self = .fog
        case "magnifyingglass": self = .search
        case "star": self = .star
        case "star.fill": self = .starFilled
        case "map": self = .map
        case "gearshape": self = .gear
        case "location": self = .location
        case "backpack": self = .backpack
        case "checkmark.square.fill": self = .check
        case "flag.checkered": self = .flag
        case "trash": self = .trash
        case "drop.fill": self = .drop
        case "wind": self = .wind
        case "thermometer": self = .thermometer
        case "thermometer.variable": self = .thermometerVariable
        case "arrow.up.arrow.down": self = .tempRange
        case "humidity": self = .humidity
        case "gauge": self = .gauge
        case "gauge.with.dots.needle.67percent", "aqi.medium": self = .gaugeAQI
        case "eye": self = .eye
        case "sunrise", "sunrise.fill": self = .sunrise
        case "sunset", "sunset.fill": self = .sunset
        case "clock": self = .clock
        case "calendar": self = .calendar
        case "house": self = .house
        case "slider.horizontal.3": self = .sliders
        case "arrow.triangle.2.circlepath": self = .refresh
        default: self = .cloud
        }
    }
}

extension PixelSpriteKind {
    /// 16x16 grid of palette characters: '.' clear, 'K' outline, 'W' white, 'A' accent/tint, 'S' shade.
    /// TODO(workstream A): replace with hand-drawn art per case. All cases currently share one
    /// placeholder blob so the view hierarchy compiles and renders something while that work lands.
    var grid: [String] {
        switch self {
        default: return Self.placeholderGrid
        }
    }

    private static let placeholderGrid: [String] = [
        "................",
        "................",
        "......KKKK......",
        ".....KAAAAK.....",
        "....KAAAAAAK....",
        "...KAAAAAAAAK...",
        "...KAAAAAAAAK...",
        "....KAAAAAAK....",
        ".....KAAAAK.....",
        "......KKKK......",
        "................",
        "................",
        "................",
        "................",
        "................",
        "................",
    ]

    fileprivate func color(for char: Character, tint: Color?) -> Color? {
        switch char {
        case ".": nil
        case "K": .black.opacity(0.85)
        case "W": .white
        case "A": tint ?? .yellow
        case "S": .black.opacity(0.35)
        default: nil
        }
    }
}

/// Renders one `PixelSpriteKind` as crisp, integer-snapped squares instead of a vector glyph.
/// Purely decorative: callers that convey meaning (toolbar buttons, labeled rows) supply their
/// own accessibility label, since the sprite itself is hidden from assistive technologies.
struct PixelSprite: View {
    let kind: PixelSpriteKind
    var scale: CGFloat = 2
    var tint: Color?
    @ScaledMetric(relativeTo: .body) private var baseUnit: CGFloat = 1

    init(_ kind: PixelSpriteKind, scale: CGFloat = 2, tint: Color? = nil) {
        self.kind = kind
        self.scale = scale
        self.tint = tint
    }

    var body: some View {
        let grid = kind.grid
        let rows = grid.count
        let cols = grid.first?.count ?? 0
        let unit = scale * baseUnit

        Canvas { context, _ in
            for (r, row) in grid.enumerated() {
                for (c, char) in row.enumerated() {
                    guard let color = kind.color(for: char, tint: tint) else { continue }
                    let rect = CGRect(x: CGFloat(c) * unit, y: CGFloat(r) * unit, width: unit, height: unit)
                    context.fill(Path(rect), with: .color(color))
                }
            }
        }
        .frame(width: CGFloat(cols) * unit, height: CGFloat(rows) * unit)
        .accessibilityHidden(true)
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 48))], spacing: 12) {
            ForEach(PixelSpriteKind.allCases, id: \.self) { kind in
                PixelSprite(kind, scale: 2)
            }
        }
        .padding()
    }
    .background(Color.black)
}
