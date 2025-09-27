//
//  MarineDataDTO.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/25/25.
//

import Foundation

// MARK: - Weather Type Enum
enum WeatherType: Int, CaseIterable, Codable {
    case clear = 0
    case rain = 1
    case snow = 2
    case mixed = 3
    
    static func fromPtype(_ ptype: Double) -> WeatherType {
        switch ptype {
        case 0: return .clear
        case 1: return .rain
        case 2: return .snow
        case 3: return .mixed
        default: return .clear
        }
    }
    
    var description: String {
        switch self {
        case .clear: return "맑음"
        case .rain: return "비"
        case .snow: return "눈"
        case .mixed: return "진눈개비"
        }
    }
}
