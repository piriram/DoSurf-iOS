import Foundation
import WatchConnectivity

// MARK: - Watch payload DTO
struct WatchSessionPayload: Codable {
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
}

struct SurfSessionData {
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
    let isDeleted: Bool
}

private enum WatchMessageKey {
    static let payloadVersion = "payloadVersion"
    static let payloads = "payloads"
    static let distance = "distance"
    static let duration = "duration"
    static let startTime = "startTime"
    static let endTime = "endTime"
    static let waveCount = "waveCount"
    static let maxHeartRate = "maxHeartRate"
    static let avgHeartRate = "avgHeartRate"
    static let activeCalories = "activeCalories"
    static let strokeCount = "strokeCount"
    static let lastModifiedAt = "lastModifiedAt"
    static let deviceId = "deviceId"
    static let isDeleted = "isDeleted"
    static let recordId = "recordId"
}

protocol iPhoneWatchConnectivityDelegate: AnyObject {
    func didReceiveSurfSessions(_ sessions: [WatchSessionPayload])
    func didReceiveLegacySurfData(_ data: SurfSessionData)
    func watchConnectivityDidChangeReachability(_ isReachable: Bool)
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

    private func makeResponse(success: Bool, message: String = "", acceptedCount: Int = 0) -> [String: Any] {
        [
            "success": success,
            "message": message,
            "acceptedCount": acceptedCount,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
}

extension iPhoneWatchConnectivity: WCSessionDelegate {
    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        isActivated = (activationState == .activated)

        DispatchQueue.main.async {
            print("✅ iPhone WCSession activated: \(activationState.rawValue)")
            if let error {
                print("⚠️ Activation error: \(error.localizedDescription)")
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
        print("📬 Received message from Watch")

        do {
            let sessions = try parsePayloads(from: message)
            if sessions.isEmpty {
                replyHandler(makeResponse(success: false, message: "No sessions in message"))
                return
            }

            DispatchQueue.main.async {
                self.delegate?.didReceiveSurfSessions(sessions)
                if let first = sessions.first {
                    self.delegate?.didReceiveLegacySurfData(
                        WatchSessionDataMapper.toLegacy(from: first)
                    )
                }
                replyHandler(self.makeResponse(success: true, message: "Data received successfully", acceptedCount: sessions.count))
            }
        } catch {
            print("❌ Failed to parse surf data: \(error.localizedDescription)")
            replyHandler(makeResponse(success: false, message: error.localizedDescription))
        }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        self.session(session, didReceiveMessage: message) { _ in }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            print("📱 Watch reachability changed: \(session.isReachable)")
            self.delegate?.watchConnectivityDidChangeReachability(session.isReachable)
        }
    }

    private func parsePayloads(from message: [String: Any]) throws -> [WatchSessionPayload] {
        if let payloads = message[WatchMessageKey.payloads] as? [[String: Any]], !payloads.isEmpty {
            return try payloads.map {
                try WatchSessionPayloadMapper.toPayload(from: $0)
            }
        }

        guard let payload = message[WatchMessageKey.distance] as? Double,
              let duration = message[WatchMessageKey.duration] as? TimeInterval,
              let startUnix = parseNumber(message[WatchMessageKey.startTime]),
              let endUnix = parseNumber(message[WatchMessageKey.endTime]) else {
            throw WatchDataError.invalidFormat
        }

        let recordId = message[WatchMessageKey.recordId] as? String ?? UUID().uuidString
        return [
            WatchSessionPayload(
                payloadVersion: (message[WatchMessageKey.payloadVersion] as? Int) ?? 1,
                recordId: recordId,
                distance: payload,
                duration: duration,
                startTime: Date(timeIntervalSince1970: startUnix),
                endTime: Date(timeIntervalSince1970: endUnix),
                waveCount: message[WatchMessageKey.waveCount] as? Int ?? 0,
                maxHeartRate: message[WatchMessageKey.maxHeartRate] as? Double ?? 0,
                avgHeartRate: message[WatchMessageKey.avgHeartRate] as? Double ?? 0,
                activeCalories: message[WatchMessageKey.activeCalories] as? Double ?? 0,
                strokeCount: message[WatchMessageKey.strokeCount] as? Int ?? 0,
                lastModifiedAt: parseDate(message[WatchMessageKey.lastModifiedAt]) ?? Date(),
                deviceId: message[WatchMessageKey.deviceId] as? String ?? "watch-legacy",
                isDeleted: message[WatchMessageKey.isDeleted] as? Bool ?? false
            )
        ]
    }

    private func parseNumber(_ value: Any?) -> Double? {
        guard let value else { return nil }
        if let number = value as? TimeInterval {
            return number
        }
        if let number = value as? NSNumber {
            return number.doubleValue
        }
        if let number = value as? String {
            return Double(number)
        }
        if let number = value as? Int {
            return Double(number)
        }
        return nil
    }

    private func parseDate(_ value: Any?) -> Date? {
        guard let value else { return nil }

        if let timestamp = parseNumber(value), timestamp > 0 {
            return Date(timeIntervalSince1970: timestamp)
        }

        if let date = value as? Date {
            return date
        }

        return nil
    }
}

private enum WatchSessionPayloadMapper {
    static func toPayload(from dictionary: [String: Any]) throws -> WatchSessionPayload {
        guard let recordId = dictionary[WatchMessageKey.recordId] as? String,
              let distance = dictionary[WatchMessageKey.distance] as? Double,
              let duration = dictionary[WatchMessageKey.duration] as? TimeInterval,
              let startTimeUnix = dictionary[WatchMessageKey.startTime] as? TimeInterval,
              let endTimeUnix = dictionary[WatchMessageKey.endTime] as? TimeInterval else {
            throw WatchDataError.invalidFormat
        }

        return WatchSessionPayload(
            payloadVersion: dictionary[WatchMessageKey.payloadVersion] as? Int ?? 1,
            recordId: recordId,
            distance: distance,
            duration: duration,
            startTime: Date(timeIntervalSince1970: startTimeUnix),
            endTime: Date(timeIntervalSince1970: endTimeUnix),
            waveCount: dictionary[WatchMessageKey.waveCount] as? Int ?? 0,
            maxHeartRate: dictionary[WatchMessageKey.maxHeartRate] as? Double ?? 0,
            avgHeartRate: dictionary[WatchMessageKey.avgHeartRate] as? Double ?? 0,
            activeCalories: dictionary[WatchMessageKey.activeCalories] as? Double ?? 0,
            strokeCount: dictionary[WatchMessageKey.strokeCount] as? Int ?? 0,
            lastModifiedAt: parseDate(dictionary[WatchMessageKey.lastModifiedAt]) ?? Date(),
            deviceId: dictionary[WatchMessageKey.deviceId] as? String ?? "watch-device",
            isDeleted: dictionary[WatchMessageKey.isDeleted] as? Bool ?? false
        )
    }

    private static func parseDate(_ value: Any?) -> Date? {
        guard let value else { return nil }
        if let date = value as? Date { return date }
        if let number = value as? NSNumber { return Date(timeIntervalSince1970: number.doubleValue) }
        if let number = value as? TimeInterval { return Date(timeIntervalSince1970: number) }
        if let number = value as? Double { return Date(timeIntervalSince1970: number) }
        if let number = value as? String, let seconds = Double(number) {
            return Date(timeIntervalSince1970: seconds)
        }
        return nil
    }
}

private enum WatchSessionDataMapper {
    static func toLegacy(from payload: WatchSessionPayload) -> SurfSessionData {
        SurfSessionData(
            payloadVersion: payload.payloadVersion,
            recordId: payload.recordId,
            distance: payload.distance,
            duration: payload.duration,
            startTime: payload.startTime,
            endTime: payload.endTime,
            waveCount: payload.waveCount,
            maxHeartRate: payload.maxHeartRate,
            avgHeartRate: payload.avgHeartRate,
            activeCalories: payload.activeCalories,
            strokeCount: payload.strokeCount,
            isDeleted: payload.isDeleted
        )
    }
}

enum WatchDataError: LocalizedError {
    case invalidFormat
    case missingFields

    var errorDescription: String? {
        switch self {
        case .invalidFormat:
            return "Invalid data format received from Watch"
        case .missingFields:
            return "Missing required fields in Watch data"
        }
    }
}
