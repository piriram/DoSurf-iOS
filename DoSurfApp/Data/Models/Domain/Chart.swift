//
//  Chart.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 9/25/25.
//

import Foundation

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


