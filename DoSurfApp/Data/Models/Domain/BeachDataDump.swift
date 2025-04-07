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
