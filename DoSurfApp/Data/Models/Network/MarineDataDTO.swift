//
//  MarineDataDTO.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/25/25.
//

import Foundation

// MARK: - Firestore DTO Models
// TODO - Camel Stretagy 사용하기
struct MarineDataDTO: Codable {
    let timestamp: Date
    let createdAt: Date
    let windSouth: Double
    let windNorth: Double
    let temp: Double
    let ptype: Double
    let wavesHeight: Double
    let wavesDirection: Double
    let wavesPeriod: Double
    
    enum CodingKeys: String, CodingKey {
        case timestamp
        case createdAt = "created_at"
        case windSouth = "wind_south"
        case windNorth = "wind_north"
        case temp
        case ptype
        case wavesHeight = "waves_height"
        case wavesDirection = "waves_direction"
        case wavesPeriod = "waves_period"
    }
}


// MARK: - Chart Domain Model 변환을 위한 Extension
extension MarineDataDTO {
    func toDomain(beachID: String) -> Chart {
        // 풍향 계산 (wind_south, wind_north로부터)
        let windDirection = atan2(windSouth, windNorth) * 180 / .pi
        let windSpeed = sqrt(windSouth * windSouth + windNorth * windNorth)
        
        return Chart(
            beachID: beachID,
            time: timestamp,
            windDirection: windDirection,
            windSpeed: windSpeed,
            waveDirection: Int(wavesDirection),
            waveHeight: wavesHeight,
            waveSpeed: wavesPeriod, // 파도 주기를 속도로 사용
            waterTemperature: temp, // 임시로 기온을 수온으로 사용
            weather: WeatherType.fromPtype(ptype),
            airTemperature: temp
        )
    }
}

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
