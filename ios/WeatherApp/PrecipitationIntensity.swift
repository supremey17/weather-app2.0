import Foundation

/// How hard rain or snow is coming down, used to scale the full-page particle effect (see
/// `WeatherParticles.swift`). Separate from `PixelWeatherTheme` — a storm is still `.stormy`
/// whether it's a light or heavy one; intensity only changes how the particles behave.
enum PrecipitationIntensity: String, Equatable, CaseIterable {
    case light
    case normal
    case heavy

    /// Conditions that can actually show precipitation particles. Anything else (clear, cloudy,
    /// misty, neutral) has no rain/snow to be light or heavy about, so callers that care whether
    /// particles should render at all should check `condition` against this set themselves
    /// (`WeatherParticleConfig.make` does) rather than inferring it from intensity.
    static let precipitatingConditions: Set<String> = ["Rain", "Drizzle", "Thunderstorm", "Snow"]

    /// Derives intensity from the weather response's own description text first (always present,
    /// and it's the same text already shown to the person as `conditionTitle`), falling back to
    /// the decoded rain/snow volume only when the description doesn't say. Pure and total — never
    /// crashes, and untrusted/out-of-range volume values (NaN, negative) are ignored rather than
    /// propagated.
    static func make(
        condition: String,
        description: String,
        rainOneHourMillimeters: Double?,
        snowOneHourMillimeters: Double?
    ) -> PrecipitationIntensity {
        guard precipitatingConditions.contains(condition) else { return .normal }

        let lowered = description.lowercased()
        // Checked before "light": "heavy intensity drizzle" contains the substring "intensity",
        // not "light", so this ordering alone wouldn't misfire — but checking heavy/extreme terms
        // first keeps the rule order obviously correct regardless of future keyword additions.
        let heavyKeywords = ["heavy", "extreme", "very heavy", "ragged"]
        if heavyKeywords.contains(where: lowered.contains) {
            return .heavy
        }
        if lowered.contains("light") {
            return .light
        }

        if let volume = validVolume(rainOneHourMillimeters) ?? validVolume(snowOneHourMillimeters) {
            if volume < 1.0 { return .light }
            if volume > 7.6 { return .heavy }
            return .normal
        }

        if condition == "Drizzle" {
            return .light
        }

        return .normal
    }

    /// `nil` for anything that isn't a finite, non-negative measurement — a corrupt or absent API
    /// value should fall through to the next signal, not be trusted at face value.
    private static func validVolume(_ value: Double?) -> Double? {
        guard let value, value.isFinite, value >= 0 else { return nil }
        return value
    }
}
