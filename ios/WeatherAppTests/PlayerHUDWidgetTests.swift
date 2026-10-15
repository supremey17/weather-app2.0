import Foundation
import Testing
@testable import WeatherApp

struct PlayerHUDWidgetTests {
    @Test func hpFractionIsTheTempsPositionInTheRange() {
        #expect(PlayerHUDWidget.hpFraction(temp: 70, low: 60, high: 80) == 0.5)
        #expect(PlayerHUDWidget.hpFraction(temp: 60, low: 60, high: 80) == 0)
    }

    @Test func hpFractionClampsOutsideTheRange() {
        #expect(PlayerHUDWidget.hpFraction(temp: 50, low: 60, high: 80) == 0)
        #expect(PlayerHUDWidget.hpFraction(temp: 95, low: 60, high: 80) == 1)
    }

    @Test func hpFractionNeedsAUsableRange() {
        #expect(PlayerHUDWidget.hpFraction(temp: 70, low: nil, high: 80) == nil)
        #expect(PlayerHUDWidget.hpFraction(temp: 70, low: 60, high: nil) == nil)
        #expect(PlayerHUDWidget.hpFraction(temp: 70, low: 80, high: 80) == nil)
        #expect(PlayerHUDWidget.hpFraction(temp: 70, low: 80, high: 60) == nil)
    }

    @Test func hpBarTextFillsProportionally() {
        #expect(PlayerHUDWidget.hpBarText(fraction: 0) == "▱▱▱▱▱▱▱▱")
        #expect(PlayerHUDWidget.hpBarText(fraction: 0.5) == "▰▰▰▰▱▱▱▱")
        #expect(PlayerHUDWidget.hpBarText(fraction: 1.5) == "▰▰▰▰▰▰▰▰")
    }

    private let hours = (0..<3).map {
        WidgetSnapshot.Hour(epoch: 1_000 + $0 * 3600, time: "", symbol: "cloud.fill", temp: "", chanceOfRain: 10 * ($0 + 1))
    }

    @Test func nextHourChancePicksTheHourInProgress() {
        #expect(LockScreenGaugesWidget.nextHourChance(in: hours, at: Date(timeIntervalSince1970: 1_000)) == 10)
        #expect(LockScreenGaugesWidget.nextHourChance(in: hours, at: Date(timeIntervalSince1970: 1_000 + 3599)) == 10)
    }

    @Test func nextHourChanceSkipsPastHours() {
        #expect(LockScreenGaugesWidget.nextHourChance(in: hours, at: Date(timeIntervalSince1970: 1_000 + 3600)) == 20)
        #expect(LockScreenGaugesWidget.nextHourChance(in: hours, at: Date(timeIntervalSince1970: 0)) == 10)
    }

    @Test func nextHourChanceIsNilWhenNothingIsLeft() {
        #expect(LockScreenGaugesWidget.nextHourChance(in: hours, at: Date(timeIntervalSince1970: 1_000 + 3 * 3600)) == nil)
        #expect(LockScreenGaugesWidget.nextHourChance(in: [], at: .now) == nil)
    }
}
