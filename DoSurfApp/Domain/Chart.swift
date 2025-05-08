//
//  Chart.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

import Foundation

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
