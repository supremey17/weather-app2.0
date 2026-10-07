import SwiftUI

/// Composes whichever backdrop is selected: a custom user-supplied image if one exists for it, a
/// procedurally-drawn pixel scene otherwise, with a theme-driven "weather wash" and (at night) a
/// darkening scrim layered on top for decorative (non-`.weather`) backgrounds — so a chosen scene
/// still reads as rainy/cloudy/nighttime, just as a backdrop rather than the primary sky.
struct PixelBackgroundLayer: View {
    let background: PixelBackground
    let theme: PixelWeatherTheme
    let isNight: Bool
    var animate: Bool = true

    var body: some View {
        ZStack {
            base
            if background != .weather {
                weatherWash
                if isNight {
                    Color(red: 0.03, green: 0.04, blue: 0.12).opacity(0.5)
                }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private var base: some View {
        if background == .weather {
            theme.skyColor(isNight: isNight)
        } else if let assetName = background.assetName, let uiImage = UIImage(named: assetName) {
            Image(uiImage: uiImage)
                .resizable()
                .interpolation(.none)
                .scaledToFill()
                .clipped()
        } else {
            proceduralScene
        }
    }

    @ViewBuilder
    private var proceduralScene: some View {
        switch background {
        case .weather: Color.clear // unreachable, `base` already handles .weather
        case .space: SpaceScene(animate: animate)
        case .cherryBlossom: CherryBlossomScene(animate: animate)
        case .mountains: MountainsScene(animate: animate)
        case .river: RiverScene(animate: animate)
        case .ocean: OceanScene(animate: animate, isNight: isNight)
        case .beach: BeachScene(animate: animate)
        }
    }

    /// A translucent wash of the active weather theme's own sky color over a decorative
    /// background, so "it's raining" or "it's foggy" still reads even when you've picked, say, the
    /// beach scene as your backdrop. Returns fully transparent for clear/neutral — nothing to wash
    /// with.
    private var weatherWash: some View {
        let (color, opacity): (Color, Double) = {
            switch theme {
            case .rainy, .stormy: return (theme.skyColor, 0.25)
            case .cloudy: return (theme.skyColor, 0.15)
            case .misty: return (.white, 0.2)
            case .snowy: return (.white, 0.1)
            case .clearDay, .clearNight, .neutral: return (.clear, 0)
            }
        }()
        return color.opacity(opacity)
    }
}

// MARK: - Scenes

private struct SpaceScene: View {
    let animate: Bool
    @Environment(PixelClock.self) private var clock: PixelClock?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool { animate && !reduceMotion && scenePhase == .active }

    var body: some View {
        GeometryReader { proxy in
            let step = shouldAnimate ? (clock?.step ?? 0) : 0
            let width = proxy.size.width
            let height = proxy.size.height
            let widthBucket = max(Int(width), 1)
            let heightBucket = max(Int(height), 1)

            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.02, green: 0.02, blue: 0.08),
                        Color(red: 0.08, green: 0.05, blue: 0.22),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                ForEach(0..<40, id: \.self) { index in
                    let x = CGFloat((index * 53) % widthBucket)
                    let y = CGFloat((index * 37) % heightBucket)
                    let isDim = (index + step) % 7 == 0
                    Rectangle()
                        .fill(Color.white.opacity(isDim ? 0.25 : 0.9))
                        .frame(width: 2, height: 2)
                        .position(x: x, y: y)
                }

                ZStack {
                    Circle()
                        .fill(Color(red: 0.62, green: 0.42, blue: 0.24))
                        .frame(width: 22, height: 22)
                    Ellipse()
                        .stroke(Color(red: 0.85, green: 0.72, blue: 0.5), lineWidth: 2)
                        .frame(width: 38, height: 12)
                        .rotationEffect(.degrees(-18))
                }
                .position(x: width * 0.78, y: height * 0.22)

                let moonX = (CGFloat(step / 6) * 2).truncatingRemainder(dividingBy: max(width, 1))
                Circle()
                    .fill(Color(red: 0.75, green: 0.75, blue: 0.78))
                    .frame(width: 14, height: 14)
                    .position(x: width * 0.2 + moonX, y: height * 0.35)
            }
        }
        .clipped()
    }
}

private struct CherryBlossomScene: View {
    let animate: Bool
    @Environment(PixelClock.self) private var clock: PixelClock?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool { animate && !reduceMotion && scenePhase == .active }

    var body: some View {
        GeometryReader { proxy in
            let step = shouldAnimate ? (clock?.step ?? 0) : 0
            let width = proxy.size.width
            let height = proxy.size.height
            let widthBucket = max(Int(width), 1)
            let heightBucket = max(Int(height), 1)

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.85, blue: 0.90),
                        Color(red: 0.86, green: 0.80, blue: 0.95),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                PixelHillLayer(color: Color(red: 0.56, green: 0.42, blue: 0.52), heightFraction: 0.28, columns: 8, step: step, speed: 1)
                PixelHillLayer(color: Color(red: 0.48, green: 0.68, blue: 0.48), heightFraction: 0.18, columns: 6, step: step, speed: 2)

                VStack(spacing: 0) {
                    ZStack {
                        Circle().fill(Color(red: 0.95, green: 0.72, blue: 0.80)).frame(width: 26, height: 26).offset(x: -10, y: 0)
                        Circle().fill(Color(red: 0.98, green: 0.78, blue: 0.85)).frame(width: 30, height: 30)
                        Circle().fill(Color(red: 0.95, green: 0.70, blue: 0.80)).frame(width: 24, height: 24).offset(x: 12, y: 6)
                    }
                    Rectangle()
                        .fill(Color(red: 0.36, green: 0.24, blue: 0.16))
                        .frame(width: 8, height: 34)
                }
                .position(x: width * 0.18, y: height * 0.55)

                ForEach(0..<12, id: \.self) { index in
                    let baseX = CGFloat((index * 71) % widthBucket)
                    let baseY = CGFloat((index * 59) % heightBucket)
                    let drift = CGFloat((step + index * 5) % 100)
                    Rectangle()
                        .fill(Color(red: 0.98, green: 0.75, blue: 0.84))
                        .frame(width: 3, height: 3)
                        .position(
                            x: (baseX + drift * 0.4).truncatingRemainder(dividingBy: max(width, 1)),
                            y: (baseY + drift * 0.6).truncatingRemainder(dividingBy: max(height, 1))
                        )
                }
            }
        }
        .clipped()
    }
}

private struct MountainsScene: View {
    let animate: Bool
    @Environment(PixelClock.self) private var clock: PixelClock?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool { animate && !reduceMotion && scenePhase == .active }

    var body: some View {
        GeometryReader { proxy in
            let step = shouldAnimate ? (clock?.step ?? 0) : 0
            let width = proxy.size.width
            let height = proxy.size.height

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(red: 0.20, green: 0.22, blue: 0.38),
                        Color(red: 0.38, green: 0.40, blue: 0.52),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                HStack(alignment: .bottom, spacing: max(width * 0.08, 0)) {
                    peak(baseWidth: width * 0.22, baseHeight: height * 0.42)
                    peak(baseWidth: width * 0.28, baseHeight: height * 0.52)
                    peak(baseWidth: width * 0.20, baseHeight: height * 0.36)
                }
                .frame(width: width, alignment: .center)

                PixelHillLayer(color: Color(red: 0.09, green: 0.33, blue: 0.22), heightFraction: 0.16, columns: 8, step: step, speed: 1)
            }
        }
        .clipped()
    }

    @ViewBuilder
    private func peak(baseWidth: CGFloat, baseHeight: CGFloat) -> some View {
        let steps = 4
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.white.opacity(0.9))
                .frame(width: max(baseWidth * 0.35, 1), height: max(baseHeight * 0.14, 1))
            ForEach(0..<steps, id: \.self) { index in
                Rectangle()
                    .fill(Color(red: 0.42, green: 0.46, blue: 0.56).opacity(1 - Double(index) * 0.08))
                    .frame(
                        width: max(baseWidth * (1 - CGFloat(steps - 1 - index) * 0.18), 1),
                        height: max(baseHeight * 0.86 / CGFloat(steps), 1)
                    )
            }
        }
    }
}

private struct RiverScene: View {
    let animate: Bool
    @Environment(PixelClock.self) private var clock: PixelClock?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool { animate && !reduceMotion && scenePhase == .active }

    var body: some View {
        GeometryReader { proxy in
            let step = shouldAnimate ? (clock?.step ?? 0) : 0
            let width = proxy.size.width
            let height = proxy.size.height
            let widthBucket = max(Int(width), 1)

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(red: 0.55, green: 0.78, blue: 0.85),
                        Color(red: 0.78, green: 0.90, blue: 0.80),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                PixelHillLayer(color: Color(red: 0.10, green: 0.30, blue: 0.16), heightFraction: 0.30, columns: 10, step: step, speed: 1)

                Rectangle()
                    .fill(Color(red: 0.35, green: 0.62, blue: 0.32))
                    .frame(height: height * 0.22)

                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(red: 0.18, green: 0.42, blue: 0.62))
                        .frame(height: height * 0.18)

                    ForEach(0..<6, id: \.self) { index in
                        let shift = CGFloat((step * 3 + index * 17) % widthBucket)
                        Rectangle()
                            .fill(Color.white.opacity(0.35))
                            .frame(width: max(width * 0.12, 1), height: 2)
                            .position(x: shift, y: (height * 0.18) / 2)
                    }
                }
                .frame(height: height * 0.18)
            }
        }
        .clipped()
    }
}

private struct OceanScene: View {
    let animate: Bool
    let isNight: Bool
    @Environment(PixelClock.self) private var clock: PixelClock?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool { animate && !reduceMotion && scenePhase == .active }

    var body: some View {
        GeometryReader { proxy in
            let step = shouldAnimate ? (clock?.step ?? 0) : 0
            let width = proxy.size.width
            let height = proxy.size.height
            let columnWidth = max(width / 10, 1)

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: isNight
                        ? [Color(red: 0.03, green: 0.05, blue: 0.16), Color(red: 0.05, green: 0.14, blue: 0.30)]
                        : [Color(red: 0.45, green: 0.78, blue: 0.92), Color(red: 0.10, green: 0.35, blue: 0.55)],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Circle()
                    .fill(isNight ? Color(red: 0.82, green: 0.82, blue: 0.86) : Color(red: 1.0, green: 0.86, blue: 0.45))
                    .frame(width: isNight ? 18 : 26, height: isNight ? 18 : 26)
                    .position(x: width * 0.5, y: height * 0.42)

                VStack(spacing: 2) {
                    ForEach(0..<3, id: \.self) { row in
                        let multiplier = CGFloat(row + 1)
                        let shift = (CGFloat(step) * multiplier).truncatingRemainder(dividingBy: columnWidth)
                        HStack(spacing: 0) {
                            ForEach(0..<10, id: \.self) { col in
                                Rectangle()
                                    .fill((col + row).isMultiple(of: 2)
                                        ? Color(red: 0.10, green: 0.30, blue: 0.50)
                                        : Color(red: 0.16, green: 0.42, blue: 0.62))
                                    .frame(width: columnWidth, height: 10)
                            }
                        }
                        .offset(x: -shift)
                    }
                }
                .frame(height: height * 0.3)
            }
        }
        .clipped()
    }
}

private struct BeachScene: View {
    let animate: Bool
    @Environment(PixelClock.self) private var clock: PixelClock?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var shouldAnimate: Bool { animate && !reduceMotion && scenePhase == .active }

    var body: some View {
        GeometryReader { proxy in
            let step = shouldAnimate ? (clock?.step ?? 0) : 0
            let width = proxy.size.width
            let height = proxy.size.height
            let foamOffset = CGFloat(step % 4) * 2 - 3

            ZStack(alignment: .bottom) {
                LinearGradient(
                    colors: [
                        Color(red: 0.55, green: 0.82, blue: 0.93),
                        Color(red: 0.80, green: 0.93, blue: 0.95),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                Rectangle()
                    .fill(Color(red: 0.16, green: 0.52, blue: 0.62))
                    .frame(height: height * 0.22)

                Rectangle()
                    .fill(Color.white.opacity(0.7))
                    .frame(width: max(width * 0.9, 1), height: 3)
                    .offset(x: foamOffset, y: -(height * 0.20))

                Rectangle()
                    .fill(Color(red: 0.90, green: 0.80, blue: 0.58))
                    .frame(height: height * 0.18)

                palmTree
                    .position(x: width * 0.2, y: height * 0.55)
            }
        }
        .clipped()
    }

    private var palmTree: some View {
        VStack(spacing: 0) {
            ZStack {
                Capsule().fill(Color(red: 0.22, green: 0.55, blue: 0.28)).frame(width: 30, height: 8)
                    .rotationEffect(.degrees(-25)).offset(x: -10, y: 0)
                Capsule().fill(Color(red: 0.25, green: 0.60, blue: 0.30)).frame(width: 30, height: 8)
                    .offset(y: -4)
                Capsule().fill(Color(red: 0.22, green: 0.55, blue: 0.28)).frame(width: 30, height: 8)
                    .rotationEffect(.degrees(25)).offset(x: 10, y: 0)
            }
            VStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { _ in
                    Rectangle().fill(Color(red: 0.42, green: 0.28, blue: 0.16)).frame(width: 6, height: 6)
                }
            }
        }
    }
}
