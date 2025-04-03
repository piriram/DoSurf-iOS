//
//  Beach.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/25/25.
//

import Foundation

struct Beach {
    let beachID: String
    let region: Region
    let name: String
    let latitude: Double
    let longitude: Double
    let memo: String?
}

enum Region: String, CaseIterable, Codable {
    case pohang = "pohang"
    case jeju = "jeju"
    
    var displayName: String {
        switch self {
        case .pohang: return "포항/울산"
        case .jeju: return "제주"
        }
    }
}
