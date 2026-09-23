import WidgetKit
import SwiftUI

@main
struct WorldClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorldClockWidget()
        WorldClockMultiCityWidget()
    }
}
