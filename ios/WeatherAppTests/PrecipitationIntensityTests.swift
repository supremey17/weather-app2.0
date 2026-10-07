import Foundation
import Testing
@testable import WeatherApp

struct PrecipitationIntensityTests {

    // MARK: - Description keyword precedence

    @Test func heavyKeywordWinsEvenWhenDescriptionAlsoContainsLight() {
        // "heavy intensity drizzle" doesn't literally contain "light", but it does contain the
        // substring "intensity" — this confirms the heavy check isn't accidentally short-circuited
        // by an earlier, looser "light" check.
        let result = PrecipitationIntensity.make(
            condition: "Drizzle",
            description: "heavy intensity drizzle",
            rainOneHourMillimeters: nil,
            snowOneHourMillimeters: nil
        )
        #expect(result == .heavy)
    }

    @Test func lightKeywordWinsWhenNoHeavyKeywordPresent() {
        let result = PrecipitationIntensity.make(
            condition: "Rain",
            description: "light rain",
            rainOneHourMillimeters: nil,
            snowOneHourMillimeters: nil
        )
        #expect(result == .light)
    }

    // MARK: - Volume fallback

    @Test func fallsBackToRainVolumeWhenNoIntensityKeyword() {
        #expect(PrecipitationIntensity.make(
            condition: "Rain", description: "rain", rainOneHourMillimeters: 0.5, snowOneHourMillimeters: nil
        ) == .light)

        #expect(PrecipitationIntensity.make(
            condition: "Rain", description: "rain", rainOneHourMillimeters: 3.0, snowOneHourMillimeters: nil
        ) == .normal)

        #expect(PrecipitationIntensity.make(
            condition: "Rain", description: "rain", rainOneHourMillimeters: 10.0, snowOneHourMillimeters: nil
        ) == .heavy)
    }

    @Test func ignoresNegativeOrNonFiniteVolumeRatherThanTrustingIt() {
        // "Rain" has no Drizzle-style condition default, so if the garbage value were trusted
        // instead of ignored, each of these would misfire to a different result than .normal:
        // a negative value would satisfy "< 1.0" (-> .light), and +infinity would satisfy
        // "> 7.6" (-> .heavy). Ignoring them correctly falls through to the plain .normal default.
        #expect(PrecipitationIntensity.make(
            condition: "Rain", description: "rain", rainOneHourMillimeters: -5.0, snowOneHourMillimeters: nil
        ) == .normal)

        #expect(PrecipitationIntensity.make(
            condition: "Rain", description: "rain", rainOneHourMillimeters: Double.nan, snowOneHourMillimeters: nil
        ) == .normal)

        #expect(PrecipitationIntensity.make(
            condition: "Rain", description: "rain", rainOneHourMillimeters: Double.infinity, snowOneHourMillimeters: nil
        ) == .normal)
    }

    // MARK: - Condition-only default

    @Test func defaultsToLightForDrizzleWhenNothingElseMatched() {
        let result = PrecipitationIntensity.make(
            condition: "Drizzle", description: "drizzle", rainOneHourMillimeters: nil, snowOneHourMillimeters: nil
        )
        #expect(result == .light)
    }

    @Test func nonPrecipitatingConditionIsAlwaysNormal() {
        let result = PrecipitationIntensity.make(
            condition: "Clear",
            description: "heavy intensity nonsense",
            rainOneHourMillimeters: 50.0,
            snowOneHourMillimeters: nil
        )
        #expect(result == .normal)
    }
}
