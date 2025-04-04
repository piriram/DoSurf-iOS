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
