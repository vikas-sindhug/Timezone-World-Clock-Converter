import WidgetKit
import SwiftUI

@main
struct WorldClockWidgetBundle: WidgetBundle {
    var body: some Widget {
        WorldClockSingleWidget()
        WorldClockMultiWidget()
    }
}
