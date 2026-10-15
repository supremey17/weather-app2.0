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

// MARK: - View

/// The hero's big arcade-style current temperature: a rounded whole number in the pixel display
/// font, filled with a band-colored stepped gradient, wrapped in a hard dark outline and pixel
/// drop shadow, with a soft neon glow. Static (no animation), so it's Reduce Motion-safe.
struct PixelTemperatureReadout: View {
    let temp: Double
    let units: Units
    var isNight: Bool = false

    @ScaledMetric(relativeTo: .largeTitle) private var numberSize: CGFloat = 80
    @ScaledMetric(relativeTo: .largeTitle) private var unitSize: CGFloat = 24
    @ScaledMetric(relativeTo: .largeTitle) private var outlineWidth: CGFloat = 3
    @ScaledMetric(relativeTo: .largeTitle) private var dropOffset: CGFloat = 6

    private var colors: TemperatureColors {
        TemperatureBand.make(temp: temp, units: units).colors
    }

    /// One `Text` (number + raised smaller unit) so every copy below scales identically under
    /// `minimumScaleFactor` and the unit stays locked to the number.
    private var readout: Text {
        let number = Text(TemperatureReadoutFormat.number(temp))
            .font(PixelFont.hero(size: numberSize))
        let unit = Text(units.symbol)
            .font(PixelFont.hero(size: unitSize))
            // Raise the unit so its top lines up with the number's (Press Start 2P's caps fill
            // roughly 7/8 of the em), like a game HUD's superscript unit.
            .baselineOffset((numberSize - unitSize) * 0.875)
        return Text("\(number)\(unit)")
    }

    private func layer(_ style: Color) -> some View {
        readout
            .foregroundStyle(style)
            .lineLimit(1)
            .minimumScaleFactor(0.4)
    }

    var body: some View {
        ZStack {
            // Hard pixel drop shadow.
            layer(TemperatureColors.outline.opacity(0.85))
                .offset(x: dropOffset, y: dropOffset)

            // Blocky dark outline: eight hard offsets, no blur.
            ForEach(Self.outlineDirections.indices, id: \.self) { index in
                let direction = Self.outlineDirections[index]
                layer(TemperatureColors.outline)
                    .offset(x: direction.x * outlineWidth, y: direction.y * outlineWidth)
            }

            readout
                .foregroundStyle(colors.gradient)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
        .padding(.trailing, dropOffset)
        .padding(.bottom, dropOffset)
        .compositingGroup()
        .shadow(color: colors.glow.opacity(isNight ? 0.7 : 0.5), radius: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(TemperatureReadoutFormat.accessibilityLabel(temp: temp, units: units))
    }

    private static let outlineDirections: [CGPoint] = [
        CGPoint(x: -1, y: -1), CGPoint(x: 0, y: -1), CGPoint(x: 1, y: -1),
        CGPoint(x: -1, y: 0), CGPoint(x: 1, y: 0),
        CGPoint(x: -1, y: 1), CGPoint(x: 0, y: 1), CGPoint(x: 1, y: 1),
    ]
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
