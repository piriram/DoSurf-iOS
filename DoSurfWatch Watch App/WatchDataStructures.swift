import Foundation

private enum WatchSurfPayloadKey {
    static let schemaVersion = "schemaVersion"
    static let distance = "distance"
    static let duration = "duration"
    static let startTime = "startTime"
    static let endTime = "endTime"
    static let waveCount = "waveCount"
    static let maxHeartRate = "maxHeartRate"
    static let avgHeartRate = "avgHeartRate"
    static let activeCalories = "activeCalories"
    static let strokeCount = "strokeCount"
    static let currentSchemaVersion = 2
}

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
        [
            WatchSurfPayloadKey.schemaVersion: WatchSurfPayloadKey.currentSchemaVersion,
            WatchSurfPayloadKey.distance: distance,
            WatchSurfPayloadKey.duration: duration,
            WatchSurfPayloadKey.startTime: startTime.timeIntervalSince1970,
            WatchSurfPayloadKey.endTime: endTime.timeIntervalSince1970,
            WatchSurfPayloadKey.waveCount: waveCount,
            WatchSurfPayloadKey.maxHeartRate: maxHeartRate,
            WatchSurfPayloadKey.avgHeartRate: avgHeartRate,
            WatchSurfPayloadKey.activeCalories: activeCalories,
            WatchSurfPayloadKey.strokeCount: strokeCount
        ]
    }
}
