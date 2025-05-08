//
//  iPhoneWatchConnectivity.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/14/25.
//

import Foundation
import WatchConnectivity

// iPhone 앱용 서핑 세션 데이터 구조체
struct SurfSessionData: Codable {
    let distance: Double
    let duration: TimeInterval
    let startTime: Date
    let endTime: Date
    let waveCount: Int = 0
    
    var dictionary: [String: Any] {
        return [
            "distance": distance,
            "duration": duration,
            "startTime": startTime.timeIntervalSince1970,
            "endTime": endTime.timeIntervalSince1970,
            "waveCount": waveCount
        ]
    }
}

// 델리게이트 프로토콜
protocol iPhoneWatchConnectivityDelegate: AnyObject {
    func didReceiveSurfData(_ data: SurfSessionData)
    func watchConnectivityDidChangeReachability(_ isReachable: Bool)
}

class iPhoneWatchConnectivity: NSObject {
    
    weak var delegate: iPhoneWatchConnectivityDelegate?
    
    private var isActivated = false
    
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
    
    // 응답 메시지 전송
    private func sendResponse(success: Bool, message: String = "") -> [String: Any] {
        return [
            "success": success,
            "message": message,
            "timestamp": Date().timeIntervalSince1970
        ]
    }
}

// MARK: - WCSessionDelegate
extension iPhoneWatchConnectivity: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        isActivated = (activationState == .activated)
        
        DispatchQueue.main.async {
            print("✅ iPhone WCSession activated: \(activationState.rawValue)")
            if let error = error {
                print("⚠️ Activation error: \(error.localizedDescription)")
            }
        }
    }
    
    // iOS에서만 사용 가능한 메서드들
#if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("ℹ️ iPhone WCSession became inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("ℹ️ iPhone WCSession deactivated - reactivating...")
        WCSession.default.activate()
    }
#endif
    
    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            print("📱 Watch reachability changed: \(session.isReachable)")
            self.delegate?.watchConnectivityDidChangeReachability(session.isReachable)
        }
    }
    
    // 메시지 수신 (응답 핸들러 포함)
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        
        print("📬 Received message from Watch:")
        print("  Raw message: \(message)")
        
        do {
            // 메시지를 SurfSessionData로 변환
            let surfData = try parseSurfData(from: message)
            
            DispatchQueue.main.async {
                print("  ✅ Successfully parsed surf data:")
                print("     Distance: \(surfData.distance) meters")
                print("     Duration: \(surfData.duration) seconds")
                print("     Start: \(surfData.startTime)")
                print("     End: \(surfData.endTime)")
                
                // 델리게이트에 전달
                self.delegate?.didReceiveSurfData(surfData)
                
                // 성공 응답 전송
                replyHandler(self.sendResponse(success: true, message: "Data received successfully"))
            }
            
        } catch {
            print("  ❌ Failed to parse surf data: \(error.localizedDescription)")
            replyHandler(self.sendResponse(success: false, message: error.localizedDescription))
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
        guard let distance = message["distance"] as? Double,
              let duration = message["duration"] as? Double,
              let startTimeInterval = message["startTime"] as? TimeInterval,
              let endTimeInterval = message["endTime"] as? TimeInterval else {
            throw SurfDataError.invalidFormat
        }
        
        let startTime = Date(timeIntervalSince1970: startTimeInterval)
        let endTime = Date(timeIntervalSince1970: endTimeInterval)
        
        return SurfSessionData(
            distance: distance,
            duration: duration,
            startTime: startTime,
            endTime: endTime
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

