import Foundation

// Watch 앱에서 사용할 서핑 세션 데이터
struct WatchSurfSessionData: Codable {
    let payloadVersion: Int
    let recordId: String
    let distance: Double
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date
    let waveCount: Int
    let maxHeartRate: Double
    let avgHeartRate: Double
    let activeCalories: Double
    let strokeCount: Int
    let lastModifiedAt: Date
    let deviceId: String
    let isDeleted: Bool

    init(
        payloadVersion: Int = 1,
        recordId: String,
        distance: Double,
        duration: TimeInterval,
        startTime: Date,
        endTime: Date,
        waveCount: Int,
        maxHeartRate: Double,
        avgHeartRate: Double,
        activeCalories: Double,
        strokeCount: Int,
        lastModifiedAt: Date = Date(),
        deviceId: String,
        isDeleted: Bool = false
    ) {
        self.payloadVersion = payloadVersion
        self.recordId = recordId
        self.distance = distance
        self.duration = duration
        self.startTime = startTime
        self.endTime = endTime
        self.waveCount = waveCount
        self.maxHeartRate = maxHeartRate
        self.avgHeartRate = avgHeartRate
        self.activeCalories = activeCalories
        self.strokeCount = strokeCount
        self.lastModifiedAt = lastModifiedAt
        self.deviceId = deviceId
        self.isDeleted = isDeleted
    }

    static func deletePayload(
        recordId: String,
        deviceId: String,
        lastModifiedAt: Date = Date()
    ) -> WatchSurfSessionData {
        return WatchSurfSessionData(
            payloadVersion: 1,
            recordId: recordId,
            distance: 0,
            duration: 0,
            startTime: lastModifiedAt,
            endTime: lastModifiedAt,
            waveCount: 0,
            maxHeartRate: 0,
            avgHeartRate: 0,
            activeCalories: 0,
            strokeCount: 0,
            lastModifiedAt: lastModifiedAt,
            deviceId: deviceId,
            isDeleted: true
        )
    }

    var dictionary: [String: Any] {
        return [
            "payloadVersion": payloadVersion,
            "recordId": recordId,
            "distance": distance,
            "duration": duration,
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970,
            "waveCount": waveCount,
            "maxHeartRate": maxHeartRate,
            "avgHeartRate": avgHeartRate,
            "activeCalories": activeCalories,
            "strokeCount": strokeCount,
            "lastModifiedAt": lastModifiedAt.timeIntervalSince1970,
            "deviceId": deviceId,
            "isDeleted": isDeleted
        ]
    }
}
