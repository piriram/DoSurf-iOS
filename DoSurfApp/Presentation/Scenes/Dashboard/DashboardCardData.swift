//
//  DashboardCardData.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/30/25.
//

import Foundation
import UIKit
// MARK: - Dashboard Card Data Model
struct DashboardCardData {
    enum CardType {
        case wind
        case wave
        case temperature
    }
    
    let type: CardType
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let color: UIColor
    
    init(type: CardType, title: String, value: String, subtitle: String? = nil, icon: String, color: UIColor) {
        self.type = type
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.color = color
    }
}
