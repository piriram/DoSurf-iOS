import Foundation

// Watch 앱에서 사용할 서핑 세션 데이터
struct WatchSurfSessionData: Codable {
    let distance: Double
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date
    let waveCount: Int // 기본값 제거하고 매개변수로 받음
    let maxHeartRate: Double
    let avgHeartRate: Double
    let activeCalories: Double
    let strokeCount: Int
    
    var dictionary: [String: Any] {
        return [
            "distance": distance,
            "duration": duration,
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970,
            "waveCount": waveCount,
            "maxHeartRate": maxHeartRate,
            "avgHeartRate": avgHeartRate,
            "activeCalories": activeCalories,
            "strokeCount": strokeCount
        ]
    }
}
