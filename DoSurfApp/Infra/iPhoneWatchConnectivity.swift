import Foundation
import WatchConnectivity

enum WatchPayloadSchema {
    static let currentVersion = 2
    static let minimumSupportedVersion = 1
}

enum WatchSessionLifecycleState: Int, Codable {
    case started = 1
    case inProgress = 2
    case completed = 3
    case deleted = 4
}

// MARK: - Watch payload DTO
struct WatchSessionPayload: Codable {
    let payloadVersion: Int
    let sessionId: String
    let beachID: Int
    let distanceMeters: Double
    let durationSeconds: TimeInterval
    let startTime: Date
    let endTime: Date
    let waveCount: Int
    let maxHeartRate: Double
    let avgHeartRate: Double
    let activeCalories: Double
    let strokeCount: Int
    let lastModifiedAt: Date
    let deviceId: String
    let sessionState: WatchSessionLifecycleState
    let rating: Int
    let memo: String?
    let isPinned: Bool
    let schemaVersion: Int

    init(
        payloadVersion: Int = 1,
        sessionId: String,
        beachID: Int = 0,
        distanceMeters: Double,
        durationSeconds: TimeInterval,
        startTime: Date,
        endTime: Date,
        waveCount: Int,
        maxHeartRate: Double,
        avgHeartRate: Double,
        activeCalories: Double,
        strokeCount: Int,
        lastModifiedAt: Date = Date(),
        deviceId: String,
        sessionState: WatchSessionLifecycleState = .completed,
        rating: Int = 0,
        memo: String? = nil,
        isPinned: Bool = false,
        schemaVersion: Int = WatchPayloadSchema.currentVersion
    ) {
        self.payloadVersion = payloadVersion
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
        self.sessionState = sessionState
        self.rating = rating
        self.memo = memo
        self.isPinned = isPinned
        self.schemaVersion = schemaVersion
    }

    var isDeleted: Bool {
        sessionState == .deleted
    }

    var recordId: String { sessionId }
}

protocol iPhoneWatchConnectivityDelegate: AnyObject {
    func watchConnectivityDidReceivePayloads(
        _ payloads: [WatchSessionPayload],
        completion: @escaping (Result<Int, Error>) -> Void
    )
    func watchConnectivityDidChangeReachability(_ isReachable: Bool)
    func watchConnectivityDidActivate()
}

extension iPhoneWatchConnectivityDelegate {
    func watchConnectivityDidChangeReachability(_ isReachable: Bool) {}
    func watchConnectivityDidActivate() {}
}

final class iPhoneWatchConnectivity: NSObject {
    weak var delegate: iPhoneWatchConnectivityDelegate?
    private(set) var isActivated = false

    func activate() {
        guard WCSession.isSupported() else {
            print("❌ WatchConnectivity not supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
        print("🔄 iPhone WatchConnectivity activating...")
    }

    private func response(success: Bool, message: String = "", acceptedCount: Int = 0) -> [String: Any] {
        [
            "success": success,
            "message": message,
            "acceptedCount": acceptedCount,
            "timestamp": Date().timeIntervalSince1970
        ]
    }

    func pushDeltaToWatch(_ payloads: [WatchSessionPayload]) {
        guard !payloads.isEmpty else { return }
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        guard session.activationState == .activated else {
            print("ℹ️ iPhone delta skipped until WCSession activates")
            return
        }

        let message = makeOutboundMessage(payloads: payloads, syncKind: .delta)
        session.transferUserInfo(message)
    }

    func pushSnapshotToWatch(_ payloads: [WatchSessionPayload]) {
        guard WCSession.isSupported() else { return }

        let session = WCSession.default
        guard session.activationState == .activated else {
            print("ℹ️ iPhone snapshot skipped until WCSession activates")
            return
        }

        let message = makeOutboundMessage(payloads: payloads, syncKind: .snapshot)

        do {
            try session.updateApplicationContext(message)
        } catch {
            print("⚠️ failed to update application context: \(error.localizedDescription)")
        }
    }

    private func makeOutboundMessage(payloads: [WatchSessionPayload], syncKind: WatchSyncKind) -> [String: Any] {
        [
            WatchMessageKey.syncKind: syncKind.rawValue,
            WatchMessageKey.payloadVersion: WatchPayloadSchema.currentVersion,
            WatchMessageKey.payloads: payloads.map(WatchSessionPayloadMapper.toDictionary)
        ]
    }
}

extension iPhoneWatchConnectivity: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        isActivated = (activationState == .activated)

        DispatchQueue.main.async {
            print("✅ iPhone WCSession activated: \(activationState.rawValue)")
            if let error {
                print("⚠️ Activation error: \(error.localizedDescription)")
            }
            if self.isActivated {
                self.delegate?.watchConnectivityDidActivate()
            }
        }
    }

#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("ℹ️ iPhone WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        print("ℹ️ iPhone WCSession deactivated - reactivating...")
        WCSession.default.activate()
    }
#endif

    func session(_ session: WCSession, didReceiveMessage message: [String: Any], replyHandler: @escaping ([String: Any]) -> Void) {
        print("📬 received watch message")

        do {
            let sessions = try parsePayloads(from: message)
            guard !sessions.isEmpty else {
                replyHandler(response(success: false, message: "No sessions in message"))
                return
            }

            guard let delegate else {
                replyHandler(response(success: false, message: WatchDataError.noDelegate.errorDescription ?? "No delegate"))
                return
            }

            DispatchQueue.main.async {
                delegate.watchConnectivityDidReceivePayloads(sessions) { result in
                    switch result {
                    case .success(let acceptedCount):
                        replyHandler(self.response(
                            success: true,
                            message: "Data applied",
                            acceptedCount: acceptedCount
                        ))
                    case .failure(let error):
                        replyHandler(self.response(
                            success: false,
                            message: error.localizedDescription,
                            acceptedCount: 0
                        ))
                    }
                }
            }
        } catch {
            print("❌ failed to parse watch payload: \(error.localizedDescription)")
            replyHandler(response(success: false, message: error.localizedDescription))
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        do {
            let sessions = try parsePayloads(from: message)
            guard !sessions.isEmpty else { return }
            DispatchQueue.main.async {
                self.delegate?.watchConnectivityDidReceivePayloads(sessions) { _ in }
            }
        } catch {
            print("❌ failed to parse watch payload without reply: \(error.localizedDescription)")
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.delegate?.watchConnectivityDidChangeReachability(session.isReachable)
        }
    }

    private func parsePayloads(from message: [String: Any]) throws -> [WatchSessionPayload] {
        if let payloads = message[WatchMessageKey.payloads] as? [[String: Any]], !payloads.isEmpty {
            return try payloads.map { try WatchSessionPayloadMapper.toPayload(from: $0) }
        }

        let fallback = try WatchSessionPayloadMapper.toPayload(from: message)
        return [fallback]
    }
}

private enum WatchMessageKey {
    static let syncKind = "syncKind"
    static let payloads = "payloads"
    static let payloadVersion = "payloadVersion"
    static let schemaVersion = "schemaVersion"
    static let sessionId = "sessionId"
    static let recordId = "recordId"
    static let beachID = "beachID"
    static let distance = "distance"
    static let distanceMeters = "distanceMeters"
    static let duration = "duration"
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

private enum WatchSessionPayloadMapper {
    static func toPayload(from dictionary: [String: Any]) throws -> WatchSessionPayload {
        let sessionId = parseString(dictionary[WatchMessageKey.sessionId])
            ?? parseString(dictionary[WatchMessageKey.recordId])
            ?? UUID().uuidString

        guard let distance = parseDouble(dictionary[WatchMessageKey.distanceMeters])
                ?? parseDouble(dictionary[WatchMessageKey.distance]),
              let duration = parseDouble(dictionary[WatchMessageKey.durationSeconds])
                ?? parseDouble(dictionary[WatchMessageKey.duration]) else {
            throw WatchDataError.missingFields
        }

        let startTime = parseDate(dictionary[WatchMessageKey.startTime]) ?? Date()
        let endTime = parseDate(dictionary[WatchMessageKey.endTime]) ?? Date()

        let schemaVersion = parseInt(dictionary[WatchMessageKey.schemaVersion]) ?? WatchPayloadSchema.currentVersion
        let payloadVersion = parseInt(dictionary[WatchMessageKey.payloadVersion]) ?? 1
        let state = parseState(dictionary[WatchMessageKey.state])
            ?? (parseBool(dictionary[WatchMessageKey.isDeleted]) == true ? .deleted : .completed)

        return WatchSessionPayload(
            payloadVersion: payloadVersion,
            sessionId: sessionId,
            beachID: parseInt(dictionary[WatchMessageKey.beachID]) ?? 0,
            distanceMeters: distance,
            durationSeconds: duration,
            startTime: startTime,
            endTime: endTime,
            waveCount: parseInt(dictionary[WatchMessageKey.waveCount]) ?? 0,
            maxHeartRate: parseDouble(dictionary[WatchMessageKey.maxHeartRate]) ?? 0,
            avgHeartRate: parseDouble(dictionary[WatchMessageKey.avgHeartRate]) ?? 0,
            activeCalories: parseDouble(dictionary[WatchMessageKey.activeCalories]) ?? 0,
            strokeCount: parseInt(dictionary[WatchMessageKey.strokeCount]) ?? 0,
            lastModifiedAt: parseDate(dictionary[WatchMessageKey.lastModifiedAt]) ?? Date(),
            deviceId: parseString(dictionary[WatchMessageKey.deviceId]) ?? "watch-unknown",
            sessionState: state,
            rating: parseInt(dictionary[WatchMessageKey.rating]) ?? 0,
            memo: parseString(dictionary[WatchMessageKey.memo]),
            isPinned: parseBool(dictionary[WatchMessageKey.isPinned]) ?? false,
            schemaVersion: schemaVersion
        )
    }

    static func toDictionary(_ payload: WatchSessionPayload) -> [String: Any] {
        var dictionary: [String: Any] = [
            WatchMessageKey.payloadVersion: payload.payloadVersion,
            WatchMessageKey.schemaVersion: payload.schemaVersion,
            WatchMessageKey.sessionId: payload.sessionId,
            WatchMessageKey.beachID: payload.beachID,
            WatchMessageKey.distanceMeters: payload.distanceMeters,
            WatchMessageKey.durationSeconds: payload.durationSeconds,
            WatchMessageKey.startTime: payload.startTime.timeIntervalSince1970,
            WatchMessageKey.endTime: payload.endTime.timeIntervalSince1970,
            WatchMessageKey.waveCount: payload.waveCount,
            WatchMessageKey.maxHeartRate: payload.maxHeartRate,
            WatchMessageKey.avgHeartRate: payload.avgHeartRate,
            WatchMessageKey.activeCalories: payload.activeCalories,
            WatchMessageKey.strokeCount: payload.strokeCount,
            WatchMessageKey.lastModifiedAt: payload.lastModifiedAt.timeIntervalSince1970,
            WatchMessageKey.deviceId: payload.deviceId,
            WatchMessageKey.state: payload.sessionState.rawValue,
            WatchMessageKey.isDeleted: payload.isDeleted,
            WatchMessageKey.rating: payload.rating,
            WatchMessageKey.isPinned: payload.isPinned
        ]

        if let memo = payload.memo {
            dictionary[WatchMessageKey.memo] = memo
        }

        return dictionary
    }

    private static func parseDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let value as Double:
            return value
        case let value as Int:
            return Double(value)
        case let value as TimeInterval:
            return value
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    private static func parseInt(_ value: Any?) -> Int? {
        switch value {
        case let number as NSNumber:
            return number.intValue
        case let value as Int:
            return value
        case let value as Int64:
            return Int(value)
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }

    private static func parseString(_ value: Any?) -> String? {
        value as? String
    }

    private static func parseBool(_ value: Any?) -> Bool? {
        switch value {
        case let value as Bool: return value
        case let number as NSNumber: return number.boolValue
        case let value as String:
            let lower = value.lowercased()
            return lower == "true" || lower == "1"
        default: return nil
        }
    }

    private static func parseDate(_ value: Any?) -> Date? {
        switch value {
        case let date as Date:
            return date
        case let value as Double:
            return Date(timeIntervalSince1970: value)
        case let value as TimeInterval:
            return Date(timeIntervalSince1970: value)
        case let value as NSNumber:
            return Date(timeIntervalSince1970: value.doubleValue)
        case let value as String:
            if let timestamp = Double(value) {
                return Date(timeIntervalSince1970: timestamp)
            }
            return nil
        default:
            return nil
        }
    }

    private static func parseState(_ value: Any?) -> WatchSessionLifecycleState? {
        switch value {
        case let number as NSNumber:
            return WatchSessionLifecycleState(rawValue: number.intValue)
        case let value as Int:
            return WatchSessionLifecycleState(rawValue: value)
        case let value as String:
            return WatchSessionLifecycleState(rawValue: Int(value) ?? -1)
        default:
            return nil
        }
    }
}

enum WatchDataError: LocalizedError {
    case invalidFormat
    case missingFields
    case noDelegate

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid watch payload format"
        case .missingFields:
            return "Missing required fields in watch payload"
        case .noDelegate:
            return "No watch sync delegate available"
        }
    }
}

private enum WatchSyncKind: String {
    case delta
    case snapshot
}
