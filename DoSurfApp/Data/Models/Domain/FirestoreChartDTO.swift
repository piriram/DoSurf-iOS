//
//  ForecastData.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/26/25.
//

import Foundation

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
        print(documentId)
        return Chart(beachID: beachId,
                     time: documentId.toDate(dateFormat: "yyyyMMddHHmm") ?? .distantPast, //TODO: 예외 처리 어떻게 하지
                    
                     windDirection: windDirection ?? 0.0,
                     windSpeed: windSpeed ?? 0.0,
                     waveDirection: omWaveDirection ?? 0.0,
                     waveHeight: waveHeight ?? omWaveHeight ?? 0.0,
                     waveSpeed: 0.0,//TODO: 값 서버에서 넣어줘야함
                     waterTemperature: omSeaSurfaceTemperature ?? 0.0,
                     weather: .rain, // TODO: enum 값 연결
                     airTemperature: airTemperature ?? 0.0)
    }
}
struct Chart: Equatable {
    let beachID: Int
    let time: Date
    let windDirection: Double
    let windSpeed: Double
    let waveDirection: Double
    let waveHeight: Double
    let waveSpeed: Double
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



extension String {
    func toDate(dateFormat: String) -> Date?{
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        formatter.locale = Locale(identifier: "ko_KR") //TODO: en?
        formatter.timeZone = TimeZone.current
        return formatter.date(from: self)
    }
}
