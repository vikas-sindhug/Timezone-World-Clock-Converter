import WidgetKit
import SwiftUI

@main
struct WorldClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        if #available(macOS 14.0, *) {
            WorldClockWidget()
        }
        WorldClockMultiCityWidget()
    }
}
