//
//  DoSurfWidgetExtensionBundle.swift
//  DoSurfWidgetExtension
//
//  Created by 잠만보김쥬디 on 11/17/25.
//

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
