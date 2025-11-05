//
//  RecordCardViewModel.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/31/25.
//

import UIKit
import CoreData

// MARK: - RecordCardViewModel
struct RecordCardViewModel {
    let objectID: NSManagedObjectID?
    let date: String
    let dayOfWeek: String
    let rating: Int
    let ratingText: String
    let isPin: Bool
    let charts: [Chart]
    let memo: String?
    
    init(record: SurfRecordData) {
        self.objectID = record.id
        self.isPin = record.isPin
        self.memo = record.memo
        
        // Format date
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.dateFormat = "M월 d일"
        self.date = dateFormatter.string(from: record.surfDate)
        
        dateFormatter.dateFormat = "EEEE"
        self.dayOfWeek = dateFormatter.string(from: record.surfDate)
        
        // Rating
        self.rating = Int(record.rating)
        self.ratingText = Self.ratingToText(Int(record.rating))
        
        // Convert SurfChartData to Chart
        self.charts = record.charts.map { chartData in
            Chart(
                beachID: 0,
                time: chartData.time,
                windDirection: chartData.windDirection,
                windSpeed: chartData.windSpeed,
                waveDirection: chartData.waveDirection,
                waveHeight: chartData.waveHeight,
                wavePeriod: chartData.wavePeriod,
                waterTemperature: chartData.waterTemperature,
                weather: WeatherType(rawValue: Int(chartData.weatherIconName) ?? 999) ?? .unknown,
                airTemperature: chartData.airTemperature
            )
        }
    }
    
    private static func ratingToText(_ rating: Int) -> String {
        switch rating {
        case 5: return "최고예요"
        case 4: return "좋아요"
        case 3: return "보통이에요"
        case 2: return "별로예요"
        case 1: return "최악이에요"
        default: return ""
        }
    }
}
