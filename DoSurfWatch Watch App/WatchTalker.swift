//
//  WatchTalker.swift
//  DoSurfWatch Watch App
//
//  Created by 잠만보김쥬디 on 10/8/25.
//
import Foundation
import WatchConnectivity

final class WatchTalker: NSObject, WCSessionDelegate {
    static let shared = WatchTalker()
    private override init() {}

    func start() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    func send(summary: [String: Any]) {
        guard WCSession.default.isReachable else {
            print("⚠️ iPhone not reachable")
            return
        }
        WCSession.default.sendMessage(summary, replyHandler: nil) { error in
            print("⚠️ send error:", error.localizedDescription)
        }
    }

    // MARK: - Required delegate (watchOS)
    #if os(watchOS)
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        print("✅ watchOS WCSession activated: \(activationState.rawValue), error: \(String(describing: error))")
    }
    #endif
}
