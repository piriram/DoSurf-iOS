import Foundation

// MARK: - Watch session sync protocol

enum WatchLocalDeviceIdentity {
    private static let storageKey = "watch_device_id"

    static var stableId: String {
        if let saved = UserDefaults.standard.string(forKey: storageKey) {
            return saved
        }

        let newId = UUID().uuidString
        UserDefaults.standard.set(newId, forKey: storageKey)
        return newId
    }
}

enum WatchPayloadSchema {
    static let currentVersion = 2
    static let defaultBatchSize = 8

    static func nextPayloadVersion(after current: Int) -> Int {
        current < Int.max ? current + 1 : current
    }
}

enum WatchSessionLifecycleState: Int, Codable {
    case started = 1
    case inProgress = 2
    case completed = 3
    case deleted = 4
}

struct WatchSurfSessionData: Codable {
    let payloadVersion: Int
    let schemaVersion: Int
    let sessionId: String
    let beachID: Int
    let distanceMeters: Double
    let durationSeconds: Double
    let startTime: Date
    let endTime: Date
    let waveCount: Int
    let maxHeartRate: Double
    let avgHeartRate: Double
    let activeCalories: Double
    let strokeCount: Int
    let lastModifiedAt: Date
    let deviceId: String
    let state: WatchSessionLifecycleState
    let isDeleted: Bool
    let rating: Int
    let memo: String?
    let isPinned: Bool

    init(
        payloadVersion: Int = 1,
        schemaVersion: Int = WatchPayloadSchema.currentVersion,
        sessionId: String,
        beachID: Int = 0,
        distanceMeters: Double,
        durationSeconds: Double,
        startTime: Date,
        endTime: Date,
        waveCount: Int,
        maxHeartRate: Double,
        avgHeartRate: Double,
        activeCalories: Double,
        strokeCount: Int,
        lastModifiedAt: Date = Date(),
        deviceId: String,
        state: WatchSessionLifecycleState = .completed,
        isDeleted: Bool? = nil,
        rating: Int = 0,
        memo: String? = nil,
        isPinned: Bool = false
    ) {
        self.payloadVersion = payloadVersion
        self.schemaVersion = schemaVersion
        self.sessionId = sessionId
        self.beachID = beachID
        self.distanceMeters = distanceMeters
        self.durationSeconds = durationSeconds
        self.startTime = startTime
        self.endTime = endTime
        self.waveCount = waveCount
        self.maxHeartRate = maxHeartRate
        self.avgHeartRate = avgHeartRate
        self.activeCalories = activeCalories
        self.strokeCount = strokeCount
        self.lastModifiedAt = lastModifiedAt
        self.deviceId = deviceId
        self.state = state
        self.isDeleted = isDeleted ?? (state == .deleted)
        self.rating = rating
        self.memo = memo
        self.isPinned = isPinned
    }

    static func deletion(sessionId: String, deviceId: String) -> WatchSurfSessionData {
        WatchSurfSessionData(
            payloadVersion: 1,
            schemaVersion: WatchPayloadSchema.currentVersion,
            sessionId: sessionId,
            beachID: 0,
            distanceMeters: 0,
            durationSeconds: 0,
            startTime: Date(),
            endTime: Date(),
            waveCount: 0,
            maxHeartRate: 0,
            avgHeartRate: 0,
            activeCalories: 0,
            strokeCount: 0,
            deviceId: deviceId,
            state: .deleted,
            isDeleted: true,
            rating: 0,
            memo: nil,
            isPinned: false
        )
    }

    var dictionary: [String: Any] {
        var dictionary: [String: Any] = [
            WatchMessageKey.payloadVersion: payloadVersion,
            WatchMessageKey.schemaVersion: schemaVersion,
            WatchMessageKey.sessionId: sessionId,
            WatchMessageKey.beachID: beachID,
            WatchMessageKey.distanceMeters: distanceMeters,
            WatchMessageKey.durationSeconds: durationSeconds,
            WatchMessageKey.startTime: startTime.timeIntervalSince1970,
            WatchMessageKey.endTime: endTime.timeIntervalSince1970,
            WatchMessageKey.waveCount: waveCount,
            WatchMessageKey.maxHeartRate: maxHeartRate,
            WatchMessageKey.avgHeartRate: avgHeartRate,
            WatchMessageKey.activeCalories: activeCalories,
            WatchMessageKey.strokeCount: strokeCount,
            WatchMessageKey.lastModifiedAt: lastModifiedAt.timeIntervalSince1970,
            WatchMessageKey.deviceId: deviceId,
            WatchMessageKey.state: state.rawValue,
            WatchMessageKey.isDeleted: isDeleted,
            WatchMessageKey.rating: rating,
            WatchMessageKey.isPinned: isPinned
        ]

        if let memo {
            dictionary[WatchMessageKey.memo] = memo
        }

        return dictionary
    }
}

private enum WatchMessageKey {
    static let payloadVersion = "payloadVersion"
    static let schemaVersion = "schemaVersion"
    static let payloads = "payloads"
    static let sessionId = "sessionId"
    static let beachID = "beachID"
    static let distanceMeters = "distanceMeters"
    static let durationSeconds = "durationSeconds"
    static let startTime = "startTime"
    static let endTime = "endTime"
    static let waveCount = "waveCount"
    static let maxHeartRate = "maxHeartRate"
    static let avgHeartRate = "avgHeartRate"
    static let activeCalories = "activeCalories"
    static let strokeCount = "strokeCount"
    static let lastModifiedAt = "lastModifiedAt"
    static let deviceId = "deviceId"
    static let state = "state"
    static let isDeleted = "isDeleted"
    static let rating = "rating"
    static let memo = "memo"
    static let isPinned = "isPinned"
}
