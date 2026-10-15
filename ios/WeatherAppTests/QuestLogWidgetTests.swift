import Foundation
import Testing
@testable import WeatherApp

struct QuestLogWidgetTests {
    private static let start = 1_800_000_000

    private static func hours(_ count: Int) -> [WidgetSnapshot.Hour] {
        (0..<count).map { i in
            WidgetSnapshot.Hour(epoch: start + i * 3600, time: "\(i)", symbol: "cloud.fill", temp: "70°F", chanceOfRain: 0)
        }
    }

    private static func at(_ seconds: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(start + seconds))
    }

    @Test func keepsTheCurrentHour() {
        let visible = QuestLogWidget.visibleHours(Self.hours(8), at: Self.at(3599))
        #expect(visible.first?.epoch == Self.start)
    }

    @Test func dropsPastHours() {
        let visible = QuestLogWidget.visibleHours(Self.hours(8), at: Self.at(2 * 3600))
        #expect(visible.map(\.epoch) == (2..<7).map { Self.start + $0 * 3600 })
    }

    @Test func capsAtCount() {
        #expect(QuestLogWidget.visibleHours(Self.hours(8), at: Self.at(0)).count == 5)
        #expect(QuestLogWidget.visibleHours(Self.hours(8), at: Self.at(0), count: 3).count == 3)
    }

    @Test func returnsFewerThanCountWhenThatsAllThereIs() {
        let visible = QuestLogWidget.visibleHours(Self.hours(8), at: Self.at(5 * 3600 + 10))
        #expect(visible.map(\.epoch) == (5..<8).map { Self.start + $0 * 3600 })
    }

    @Test func emptyInputAndAllPastAreEmpty() {
        #expect(QuestLogWidget.visibleHours([], at: Self.at(0)).isEmpty)
        #expect(QuestLogWidget.visibleHours(Self.hours(3), at: Self.at(3 * 3600)).isEmpty)
    }

    @Test func dateBeforeAllHoursKeepsTheFirstOnes() {
        let visible = QuestLogWidget.visibleHours(Self.hours(8), at: Self.at(-7200))
        #expect(visible.map(\.epoch) == (0..<5).map { Self.start + $0 * 3600 })
        #expect(!visible.contains { QuestLogWidget.isCurrent($0, at: Self.at(-7200)) })
    }

    @Test func onlyTheContainingHourIsCurrent() {
        let hours = Self.hours(3)
        #expect(hours.filter { QuestLogWidget.isCurrent($0, at: Self.at(3600)) }.map(\.epoch) == [Self.start + 3600])
    }
}
