import Foundation

enum SurfSummaryPayloadKey {
    static let schemaVersion = "schemaVersion"
    static let distance = "distance"
    static let duration = "duration"
    static let startTime = "startTime"
    static let endTime = "endTime"
    static let waveCount = "waveCount"
    static let maxSpeed = "maxSpeed"
    static let averageSpeed = "averageSpeed"
    static let maxHeartRate = "maxHeartRate"
    static let avgHeartRate = "avgHeartRate"
    static let activeCalories = "activeCalories"
    static let strokeCount = "strokeCount"
    static let maxAltitude = "maxAltitude"
    static let minAltitude = "minAltitude"

    static let currentSchemaVersion = 2
}

struct SurfWorkoutSummaryBuilder {
    static func makePayload(
        distance: Double,
        duration: TimeInterval,
        startedAt: Date,
        endedAt: Date,
        waveCount: Int,
        maxSpeed: Double,
        averageSpeed: Double,
        maxHeartRate: Double,
        avgHeartRate: Double,
        activeCalories: Double,
        strokeCount: Int,
        maxAltitude: Double,
        minAltitude: Double
    ) -> [String: Any] {
        [
            SurfSummaryPayloadKey.schemaVersion: SurfSummaryPayloadKey.currentSchemaVersion,
            SurfSummaryPayloadKey.distance: distance,
            SurfSummaryPayloadKey.duration: duration,
            SurfSummaryPayloadKey.startTime: startedAt.timeIntervalSince1970,
            SurfSummaryPayloadKey.endTime: endedAt.timeIntervalSince1970,
            SurfSummaryPayloadKey.waveCount: waveCount,
            SurfSummaryPayloadKey.maxSpeed: maxSpeed,
            SurfSummaryPayloadKey.averageSpeed: averageSpeed,
            SurfSummaryPayloadKey.maxHeartRate: maxHeartRate,
            SurfSummaryPayloadKey.avgHeartRate: avgHeartRate,
            SurfSummaryPayloadKey.activeCalories: activeCalories,
            SurfSummaryPayloadKey.strokeCount: strokeCount,
            SurfSummaryPayloadKey.maxAltitude: maxAltitude,
            SurfSummaryPayloadKey.minAltitude: minAltitude
        ]
    }
}
