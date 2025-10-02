//
//  BeachDataDump.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/26/25.
//
import Foundation

// MARK: - Firestore DTOs (Data Layer에서만 사용)
struct BeachMetadataDTO {
    let beachId: Int
    let region: String
    let beach: String
    let lastUpdated: Date
    let totalForecasts: Int
    let status: String
    let earliestForecast: Date?
    let latestForecast: Date?
    let nextForecastTime: Date?
    
    func toDomain() -> BeachMetadata {
        return BeachMetadata(
            id: String(beachId),
            name: beach,
            region: region,
            status: status,
            lastUpdated: lastUpdated,
            totalForecasts: totalForecasts
        )
    }
}

struct FirestoreChartDTO {
    let documentId: String
    let beachId: Int
    let region: String
    let beach: String
    let datetime: String
    let timestamp: Date
    let windSpeed: Double?
    let windDirection: Double?
    let waveHeight: Double?
    let airTemperature: Double?
    let precipitationProbability: Double?
    let precipitationType: Int?
    let skyCondition: Int?
    let humidity: Double?
    let precipitation: Double?
    let snow: Double?
    let omWaveHeight: Double?
    let omWaveDirection: Double?
    let omSeaSurfaceTemperature: Double?
    
    func toDomain() -> Chart {
        return Chart(
            beachID: beachId,
            time: timestamp,
            windDirection: windDirection ?? 0.0,
            windSpeed: windSpeed ?? 0.0,
            waveDirection: omWaveDirection ?? 0.0,
            waveHeight: waveHeight ?? omWaveHeight ?? 0.0,
            wavePeriod: 0.0, // TODO: 서버에서 값 추가 필요
            waterTemperature: omSeaSurfaceTemperature ?? 0.0,
            weather: mapWeather(skyCondition: skyCondition, precipitationType: precipitationType),
            airTemperature: airTemperature ?? 0.0
        )
    }
    
    private func mapWeather(skyCondition: Int?, precipitationType: Int?) -> WeatherType {
        return .clear
        
    }
}

// MARK: - Domain Models (Domain/Presentation Layer에서 사용)
struct BeachMetadata {
    let id: String
    let name: String
    let region: String
    let status: String
    let lastUpdated: Date
    let totalForecasts: Int
    
    // beachID를 Int로 반환하는 계산 속성 추가
    var beachID: Int {
        return Int(id) ?? 0
    }
}


struct Chart: Equatable {
    let beachID: Int
    let time: Date
    let windDirection: Double
    let windSpeed: Double
    let waveDirection: Double
    let waveHeight: Double
    let wavePeriod: Double
    let waterTemperature: Double
    let weather: WeatherType
    let airTemperature: Double
}
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



struct ChartList {
    let id: String
    let beachID: String
    let chartList: [Chart]
    let lastUpdateTime: Date
}


struct BeachData {
    let metadata: BeachMetadata
    let charts: [Chart]
    let lastUpdated: Date
}


extension String {
    func toDate(dateFormat: String) -> Date?{
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "ko_KR") //TODO: en?
        formatter.timeZone = TimeZone.current
        return formatter.date(from: self)
    }
}
