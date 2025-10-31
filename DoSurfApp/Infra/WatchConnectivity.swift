//
//  WatchConnectivity.swift
//  DoSurfApp
//
//  Created by 잠만보김쥬디 on 10/8/25.
//
import Foundation
import WatchConnectivity

final class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()
    private override init() {}
    
    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
    
    // MARK: - Receive
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let distance = message["distance"] as? Double,
           let duration = message["duration"] as? Double,
           let waveCount = message["waveCount"] as? Int {
            print("📬 Watch -> iPhone:", distance, duration, waveCount)
            // TODO: 저장 유스케이스 호출
        }
    }
    
    // MARK: - Required delegate (iOS)
#if os(iOS)
    @available(iOS 9.3, *)
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        // 보통 로깅만 해도 충분
        print("✅ iOS WCSession activated: \(activationState.rawValue), error: \(String(describing: error))")
    }
    
    @available(iOS 9.3, *)
    func sessionDidBecomeInactive(_ session: WCSession) {
        // iPhone이 다른 Watch와 페어링 전환 중일 때 호출
        print("ℹ️ iOS WCSession didBecomeInactive")
    }
    
    @available(iOS 9.3, *)
    func sessionDidDeactivate(_ session: WCSession) {
        // 비활성화가 끝나면 다시 활성화 필요
        WCSession.default.activate()
        print("ℹ️ iOS WCSession didDeactivate -> re-activate called")
    }
#endif
}
