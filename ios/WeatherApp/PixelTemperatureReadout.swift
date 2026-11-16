import SwiftUI

// MARK: - Temperature bands

/// Which "heat level" a reading falls into, used to pick the hero temperature's arcade-style
/// gradient. Bands are defined in Fahrenheit so Celsius readings land in the same band as their
/// Fahrenheit equivalent.
enum TemperatureBand: CaseIterable, Equatable {
    /// Below 32°F (0°C).
    case freezing
    /// 32°F up to 55°F.
    case cold
    /// 55°F up to 75°F.
    case mild
    /// 75°F up to 90°F.
    case warm
    /// 90°F (about 32°C) and above.
    case hot

    static func make(fahrenheit: Double) -> TemperatureBand {
        switch fahrenheit {
        case ..<32: .freezing
        case ..<55: .cold
        case ..<75: .mild
        case ..<90: .warm
        default: .hot
        }
    }

    static func make(temp: Double, units: Units) -> TemperatureBand {
        make(fahrenheit: units == .metric ? temp * 9 / 5 + 32 : temp)
    }

    /// The vivid fill for this band: a hard-stepped three-tone gradient (top highlight, body,
    /// bottom shade) plus a matching neon glow, in the style of modern pixel-game score counters.
    /// Every fill tone is bright so it always reads against the dark `TemperatureColors.outline`.
    var colors: TemperatureColors {
        switch self {
        case .freezing:
            TemperatureColors(
                highlight: Color(red: 0.92, green: 0.97, blue: 1.0),
                base: Color(red: 0.62, green: 0.80, blue: 1.0),
                shade: Color(red: 0.58, green: 0.50, blue: 1.0),
                glow: Color(red: 0.65, green: 0.75, blue: 1.0)
            )
        case .cold:
            TemperatureColors(
                highlight: Color(red: 0.60, green: 1.0, blue: 1.0),
                base: Color(red: 0.10, green: 0.84, blue: 1.0),
                shade: Color(red: 0.20, green: 0.56, blue: 1.0),
                glow: Color(red: 0.10, green: 0.84, blue: 1.0)
            )
        case .mild:
            TemperatureColors(
                highlight: Color(red: 0.90, green: 1.0, blue: 0.45),
                base: Color(red: 0.45, green: 1.0, blue: 0.30),
                shade: Color(red: 0.10, green: 0.84, blue: 0.48),
                glow: Color(red: 0.45, green: 1.0, blue: 0.30)
            )
        case .warm:
            TemperatureColors(
                highlight: Color(red: 1.0, green: 0.95, blue: 0.40),
                base: Color(red: 1.0, green: 0.74, blue: 0.12),
                shade: Color(red: 1.0, green: 0.50, blue: 0.12),
                glow: Color(red: 1.0, green: 0.62, blue: 0.10)
            )
        case .hot:
            TemperatureColors(
                highlight: Color(red: 1.0, green: 0.78, blue: 0.32),
                base: Color(red: 1.0, green: 0.30, blue: 0.45),
                shade: Color(red: 0.95, green: 0.18, blue: 0.68),
                glow: Color(red: 1.0, green: 0.22, blue: 0.50)
            )
        }
    }
}

/// The color set for one `TemperatureBand`.
struct TemperatureColors: Equatable {
    let highlight: Color
    let base: Color
    let shade: Color
    let glow: Color

    /// The hard outline / drop-shadow ink behind every band's fill — a near-black navy so the
    /// number stays legible over bright day skies, snow, and dark night scenes alike.
    static let outline = Color(red: 0.05, green: 0.04, blue: 0.12)

    /// Hard color stops (no blending between bands) for a chunky 8/16-bit look.
    var gradient: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: highlight, location: 0),
                .init(color: highlight, location: 0.34),
                .init(color: base, location: 0.34),
                .init(color: base, location: 0.68),
                .init(color: shade, location: 0.68),
                .init(color: shade, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

// MARK: - Formatting

enum TemperatureReadoutFormat {
    /// The reading rounded to a whole number, e.g. 72.34 -> "72", -0.4 -> "0".
    static func number(_ temp: Double) -> String {
        String(Int(temp.rounded()))
    }

    /// Spoken form, e.g. "72 degrees Fahrenheit".
    static func accessibilityLabel(temp: Double, units: Units) -> String {
        let unitName = units == .imperial ? "Fahrenheit" : "Celsius"
        return "\(number(temp)) degrees \(unitName)"
    }
}

// MARK: - Seven-segment glyphs

/// Segment layout of a classic seven-segment display: `a` top, `b` upper right, `c` lower right,
/// `d` bottom, `e` lower left, `f` upper left, `g` middle.
enum SevenSegment {
    static let all = "abcdefg"

    /// The segments lit for `character`: digits, a minus sign, and the unit letters F and C.
    /// Anything else is blank.
    static func lit(for character: Character) -> String {
        switch character {
        case "0": "abcdef"
        case "1": "bc"
        case "2": "abdeg"
        case "3": "abcdg"
        case "4": "bcfg"
        case "5": "acdfg"
        case "6": "acdefg"
        case "7": "abc"
        case "8": "abcdefg"
        case "9": "abcdfg"
        case "-": "g"
        case "F": "aefg"
        case "C": "adef"
        default: ""
        }
    }
}

/// The chosen `segments` of one seven-segment cell, as chamfered bars filling `rect`.
struct SevenSegmentGlyph: Shape {
    let segments: String

    func path(in rect: CGRect) -> Path {
        let thickness = rect.width * 0.22
        let half = thickness / 2
        let gap = thickness * 0.14
        let left = rect.minX + half
        let right = rect.maxX - half
        let top = rect.minY + half
        let middle = rect.midY
        let bottom = rect.maxY - half

        var path = Path()

        func horizontal(_ y: CGFloat) {
            let start = left + gap
            let end = right - gap
            path.move(to: CGPoint(x: start, y: y))
            path.addLine(to: CGPoint(x: start + half, y: y - half))
            path.addLine(to: CGPoint(x: end - half, y: y - half))
            path.addLine(to: CGPoint(x: end, y: y))
            path.addLine(to: CGPoint(x: end - half, y: y + half))
            path.addLine(to: CGPoint(x: start + half, y: y + half))
            path.closeSubpath()
        }

        func vertical(_ x: CGFloat, from startY: CGFloat, to endY: CGFloat) {
            let start = startY + gap
            let end = endY - gap
            path.move(to: CGPoint(x: x, y: start))
            path.addLine(to: CGPoint(x: x + half, y: start + half))
            path.addLine(to: CGPoint(x: x + half, y: end - half))
            path.addLine(to: CGPoint(x: x, y: end))
            path.addLine(to: CGPoint(x: x - half, y: end - half))
            path.addLine(to: CGPoint(x: x - half, y: start + half))
            path.closeSubpath()
        }

        for segment in segments {
            switch segment {
            case "a": horizontal(top)
            case "b": vertical(right, from: top, to: middle)
            case "c": vertical(right, from: middle, to: bottom)
            case "d": horizontal(bottom)
            case "e": vertical(left, from: middle, to: bottom)
            case "f": vertical(left, from: top, to: middle)
            case "g": horizontal(middle)
            default: break
            }
        }
        return path
    }
}

// MARK: - View

/// The hero's current temperature as a seven-segment display set into a recessed dark window:
/// lit segments glow in the reading's band color over faint unlit "ghost" segments, like a
/// dashboard or bedside-clock readout. Static (no animation), so it's Reduce Motion-safe.
struct PixelTemperatureReadout: View {
    let temp: Double
    let units: Units
    var isNight: Bool = false

    @ScaledMetric(relativeTo: .largeTitle) private var scaledDigitHeight: CGFloat = 64

    /// Capped so the display still fits the card at the largest Dynamic Type sizes.
    private var digitHeight: CGFloat { min(scaledDigitHeight, 88) }

    private var colors: TemperatureColors {
        TemperatureBand.make(temp: temp, units: units).colors
    }

    private var unitLetter: Character { units == .imperial ? "F" : "C" }

    private static let screen = Color(red: 0.03, green: 0.05, blue: 0.08)

    private func glyph(_ character: Character, height: CGFloat) -> some View {
        ZStack {
            // Unlit segments stay faintly visible, as on a real display.
            SevenSegmentGlyph(segments: SevenSegment.all)
                .fill(colors.base.opacity(0.1))
            SevenSegmentGlyph(segments: SevenSegment.lit(for: character))
                .fill(colors.gradient)
                .shadow(color: colors.glow.opacity(isNight ? 0.8 : 0.6), radius: height / 16)
        }
        .frame(width: height / 2, height: height)
    }

    var body: some View {
        let digits = Array(TemperatureReadoutFormat.number(temp))
        let unitHeight = digitHeight / 2

        HStack(alignment: .top, spacing: PixelSpacing.sm) {
            ForEach(digits.indices, id: \.self) { index in
                glyph(digits[index], height: digitHeight)
            }

            HStack(alignment: .top, spacing: PixelSpacing.sm / 2) {
                // Degree mark: a small lit ring.
                RoundedRectangle(cornerRadius: 2, style: .continuous)
                    .strokeBorder(colors.highlight, lineWidth: unitHeight / 12)
                    .frame(width: unitHeight / 3, height: unitHeight / 3)
                    .shadow(color: colors.glow.opacity(0.6), radius: 2)
                glyph(unitLetter, height: unitHeight)
            }
        }
        .padding(PixelSpacing.md)
        .pixelWell(fill: Self.screen)
        .fixedSize()
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TemperatureReadoutFormat.accessibilityLabel(temp: temp, units: units))
    }
}

extension PixelFont {
    /// The pixel display face at an explicit point size, for oversized hero numbers. Callers
    /// scale `size` with `@ScaledMetric` themselves so Dynamic Type still applies.
    static func hero(size: CGFloat) -> Font {
        .custom("PressStart2P-Regular", fixedSize: size)
    }
}

#Preview {
    VStack(spacing: 24) {
        PixelTemperatureReadout(temp: 18.6, units: .imperial)
        PixelTemperatureReadout(temp: 41.2, units: .imperial)
        PixelTemperatureReadout(temp: 72.34, units: .imperial)
        PixelTemperatureReadout(temp: 28.4, units: .metric)
        PixelTemperatureReadout(temp: 104, units: .imperial, isNight: true)
    }
    .padding()
    .background(Color(red: 0.26, green: 0.72, blue: 0.91))
}
