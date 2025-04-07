//
//  BeachDataDump.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/26/25.
//

import Foundation

// MARK: - DTOs
struct BeachDataDump {
    let beachInfo: BeachInfo
    let metadata: BeachMetadata?
    let forecasts: [FirestoreChartDTO]
    let lastUpdated: Date
    let foundInRegion: String?
}

struct BeachInfo {
    let id: String
    let name: String
    let region: String
    
    static let availableBeaches: [BeachInfo] = [
        BeachInfo(id: "1001", name: "정동진", region: "gangreung"),
        BeachInfo(id: "2001", name: "월포", region: "pohang"),
        BeachInfo(id: "3001", name: "중문", region: "jeju"),
        BeachInfo(id: "4001", name: "해운대", region: "busan")
    ]
}

struct BeachMetadata {
    let beachId: Int
    let region: String
    let beach: String
    let lastUpdated: Date
    let totalForecasts: Int
    let status: String
    let earliestForecast: Date?
    let latestForecast: Date?
    let nextForecastTime: Date?
}
