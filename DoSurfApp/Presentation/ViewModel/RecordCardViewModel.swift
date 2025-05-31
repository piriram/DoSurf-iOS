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
        
        #if DEBUG
        print("\n=== RecordCardViewModel Init Debug ===")
        print("Record Date: \(record.surfDate)")
        print("Charts count: \(record.charts.count)")
        #endif
        
        // Convert SurfChartData to Chart
        self.charts = record.charts.enumerated().map { index, chartData in
            // Try to parse as Int first (new format), then fallback to iconName matching (old format)
            let weatherType: WeatherType
            if let rawValue = Int(chartData.weatherIconName),
               let type = WeatherType(rawValue: rawValue) {
                // New format: rawValue stored as String
                weatherType = type
            } else {
                // Old format: iconName stored as String
                weatherType = WeatherType.allCases.first { $0.iconName == chartData.weatherIconName } ?? .unknown
            }
            
            #if DEBUG
            print("\n--- Chart[\(index)] Debug ---")
            print("Time: \(chartData.time)")
            print("WeatherIconName (stored): '\(chartData.weatherIconName)'")
            print("WeatherType: \(weatherType)")
            print("Icon name: \(weatherType.iconName)")
            
            if weatherType == .unknown {
                print("⚠️ WARNING: WeatherType is .unknown!")
                print("   Stored value: '\(chartData.weatherIconName)'")
                print("   Could not match to any WeatherType")
            }
            #endif
            
            return Chart(
                beachID: 0,
                time: chartData.time,
                windDirection: chartData.windDirection,
                windSpeed: chartData.windSpeed,
                waveDirection: chartData.waveDirection,
                waveHeight: chartData.waveHeight,
                wavePeriod: chartData.wavePeriod,
                waterTemperature: chartData.waterTemperature,
                weather: weatherType,
                airTemperature: chartData.airTemperature
            )
        }
        
        #if DEBUG
        print("\n=== Final Charts Summary ===")
        let weatherCounts = Dictionary(grouping: self.charts, by: { $0.weather })
            .mapValues { $0.count }
        print("Weather distribution: \(weatherCounts)")
        print("=====================================\n")
        #endif
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
