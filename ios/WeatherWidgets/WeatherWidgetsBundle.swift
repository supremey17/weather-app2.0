import SwiftUI
import WidgetKit

@main
struct WeatherWidgetsBundle: WidgetBundle {
    var body: some Widget {
        PlayerHUDWidget()
        QuestLogWidget()
        LoadoutWidget()
        LockScreenGaugesWidget()
    }
}
