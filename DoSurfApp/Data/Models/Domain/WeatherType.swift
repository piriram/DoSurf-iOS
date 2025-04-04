//
//  MarineDataDTO.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/25/25.
//

import Foundation

// MARK: - Weather Type Enum
enum WeatherType: Int, CaseIterable, Codable {
    case clear = 1
    case rain = 4
    case snow = 5
    case cloudy = 3
    case cloudLittleSun = 9
    case cloudMuchSun = 10
    case forg = 13
    case unknown = 999
    
    static func fromPtype(_ ptype: Double) -> WeatherType {
        switch ptype {
        case 0: return .clear
        case 1: return .rain
        case 2: return .snow
        case 3: return .cloudy
        default: return .clear
        }
    }
    
    var description: String {
        switch self {
        case .clear: return "맑음"
        case .rain: return "비"
        case .snow: return "눈"
        case .cloudy: return "구름많음"
        default: return "알수없음"
        }
    }
    var iconName: String {
        switch self {
        case .clear:
            return "sun"
        case .cloudLittleSun:
            return "cloudLittleSun"
        case .cloudMuchSun:
            return "cloudMuchSun"
        case .cloudy:
            return "cloud"
        case .rain:
            return "rain"
        case .forg:
            return "forg"
        case .snow:
            return "snow"
        case .unknown:
            return "questionmark.circle.fill"
        }
    }
}

