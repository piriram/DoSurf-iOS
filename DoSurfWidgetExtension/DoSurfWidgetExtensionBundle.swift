import WidgetKit
import SwiftUI

@main
struct DoSurfWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        if #available(iOS 16.2, *) {
            SurfingLiveActivity()
        }
    }
}
