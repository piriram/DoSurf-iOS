//
//  ComplicationDataManager.swift
//  DoSurfWatch Watch App
//
//  Created by 잠만보김쥬디 on 10/15/25.
//

import ClockKit

// MARK: - Complication Data Manager
class ComplicationDataManager {
    static let shared = ComplicationDataManager()
    
    private let userDefaults = UserDefaults.standard
    
    struct LastSessionData {
        let duration: TimeInterval
        let distance: Double
        let waveCount: Int
        let date: Date
        
        var formattedDuration: String {
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }
        
        var shortSummary: String {
            return "\(Int(distance))m • \(waveCount)🌊"
        }
        
        var relativeDateString: String {
            let formatter = RelativeDateTimeFormatter()
            formatter.dateTimeStyle = .named
            return formatter.localizedString(for: date, relativeTo: Date())
        }
    }
    
    private init() {}
    
    func saveLastSession(duration: TimeInterval, distance: Double, waveCount: Int) {
        userDefaults.set(duration, forKey: "lastSessionDuration")
        userDefaults.set(distance, forKey: "lastSessionDistance")
        userDefaults.set(waveCount, forKey: "lastSessionWaveCount")
        userDefaults.set(Date(), forKey: "lastSessionDate")
        
        // Complication 업데이트 요청
        DispatchQueue.main.async {
            let server = CLKComplicationServer.sharedInstance()
            server.activeComplications?.forEach { complication in
                server.reloadTimeline(for: complication)
            }
        }
        
        print("✅ Last session saved to UserDefaults")
    }
    
    func getLastSession() -> LastSessionData? {
        let duration = userDefaults.double(forKey: "lastSessionDuration")
        let distance = userDefaults.double(forKey: "lastSessionDistance")
        let waveCount = userDefaults.integer(forKey: "lastSessionWaveCount")
        
        guard let date = userDefaults.object(forKey: "lastSessionDate") as? Date,
              duration > 0 else {
            return nil
        }
        
        return LastSessionData(
            duration: duration,
            distance: distance,
            waveCount: waveCount,
            date: date
        )
    }
}
