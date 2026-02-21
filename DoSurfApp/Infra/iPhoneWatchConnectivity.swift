import Foundation
import WatchConnectivity
import os

// iPhone 앱용 서핑 세션 데이터 구조체
struct SurfSessionData: Codable {
    let distance: Double
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date
    let waveCount: Int

    var dictionary: [String: Any] {
        [
            PayloadKey.schemaVersion: PayloadKey.currentSchemaVersion,
            PayloadKey.distance: distance,
            PayloadKey.duration: duration,
            PayloadKey.startTime: startTime.timeIntervalSince1970,
            PayloadKey.endTime: endTime.timeIntervalSince1970,
            PayloadKey.waveCount: waveCount
        ]
    }
}

private enum PayloadKey {
    static let currentSchemaVersion = 2

    static let schemaVersion = "schemaVersion"
    static let distance = "distance"
    static let duration = "duration"
    static let startTime = "startTime"
    static let endTime = "endTime"
    static let waveCount = "waveCount"
}

// 델리게이트 프로토콜
protocol iPhoneWatchConnectivityDelegate: AnyObject {
    func didReceiveSurfData(_ data: SurfSessionData)
    func watchConnectivityDidChangeReachability(_ isReachable: Bool)
}

class iPhoneWatchConnectivity: NSObject {

    weak var delegate: iPhoneWatchConnectivityDelegate?

    private var isActivated = false
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "DoSurfApp", category: "WatchConnectivity")

    func activate() {
        guard WCSession.isSupported() else {
            logger.error("WatchConnectivity not supported on this device")
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()

        logger.debug("iPhone WatchConnectivity activating")
    }

    // 응답 메시지 전송
    private func sendResponse(success: Bool, message: String = "") -> [String: Any] {
        [
            "success": success,
            "message": message,
            "timestamp": Date().timeIntervalSince1970
        ]
    }

    private func number(from rawValue: Any?) -> Double? {
        switch rawValue {
        case let value as Double:
            return value
        case let value as Float:
            return Double(value)
        case let value as Int:
            return Double(value)
        case let value as Int64:
            return Double(value)
        case let value as NSNumber:
            return value.doubleValue
        case let value as String:
            return Double(value)
        default:
            return nil
        }
    }

    private func integer(from rawValue: Any?) -> Int? {
        switch rawValue {
        case let value as Int:
            return value
        case let value as Int64:
            return Int(value)
        case let value as NSNumber:
            return value.intValue
        case let value as String:
            return Int(value)
        default:
            return nil
        }
    }
}

// MARK: - WCSessionDelegate
extension iPhoneWatchConnectivity: WCSessionDelegate {

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        isActivated = (activationState == .activated)

        if let error {
            logger.error("iPhone WCSession activation error: \(error.localizedDescription, privacy: .public)")
        } else {
            logger.debug("iPhone WCSession activated: \(activationState.rawValue)")
        }
    }

    // iOS에서만 사용 가능한 메서드들
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        logger.debug("iPhone WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        logger.debug("iPhone WCSession deactivated - reactivating")
        WCSession.default.activate()
    }
#endif

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.logger.debug("Watch reachability changed: \(session.isReachable)")
            self.delegate?.watchConnectivityDidChangeReachability(session.isReachable)
        }
    }

    // 메시지 수신 (응답 핸들러 포함)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        do {
            let surfData = try parseSurfData(from: message)

            DispatchQueue.main.async {
                self.delegate?.didReceiveSurfData(surfData)
                replyHandler(self.sendResponse(success: true, message: "Data received successfully"))
            }
        } catch {
            logger.error("Failed to parse surf data: \(error.localizedDescription, privacy: .public)")
            replyHandler(sendResponse(success: false, message: error.localizedDescription))
        }
    }

    // 메시지 수신 (응답 핸들러 없음 - 호환성)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // 응답 핸들러가 있는 메서드로 리다이렉트
        self.session(session, didReceiveMessage: message) { _ in
            // 빈 응답 핸들러
        }
    }

    // MARK: - Helper Methods
    private func parseSurfData(from message: [String: Any]) throws -> SurfSessionData {
        guard let distance = number(from: message[PayloadKey.distance]),
              let duration = number(from: message[PayloadKey.duration]) else {
            throw SurfDataError.missingFields
        }

        // 하위호환: 구버전 payload(start/end 없음)도 수용
        let now = Date().timeIntervalSince1970
        let endTimeInterval = number(from: message[PayloadKey.endTime]) ?? now
        let startTimeInterval = number(from: message[PayloadKey.startTime]) ?? (endTimeInterval - duration)
        let waveCount = integer(from: message[PayloadKey.waveCount]) ?? 0

        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime = Date(timeIntervalSince1970: endTimeInterval)

        return SurfSessionData(
            distance: distance,
            duration: duration,
            startTime: startTime,
            endTime: endTime,
            waveCount: waveCount
        )
    }
}

// MARK: - 에러 정의
enum SurfDataError: LocalizedError {
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
