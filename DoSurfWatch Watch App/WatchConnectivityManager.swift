//
//  WatchConnectivityManager.swift
//  DoSurfWatch Watch App
//
//  SwiftUI용 WatchConnectivity 매니저
//

import Foundation
import WatchConnectivity
import SwiftUI
import Combine

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    @Published var isActivated = false
    
    override init() {
        super.init()
    }
    
    func activate() async {
        guard WCSession.isSupported() else {
            print("❌ WatchConnectivity not supported")
            return
        }
        
        let session = WCSession.default
        session.delegate = self
        session.activate()
        
        print("🔄 WatchConnectivity activating...")
    }
    
    func sendSurfData(_ data: WatchSurfSessionData) async throws {
        guard WCSession.default.activationState == .activated else {
            throw WatchConnectivityError.notActivated
        }
        
        guard WCSession.default.isReachable else {
            throw WatchConnectivityError.notReachable
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(data.dictionary, replyHandler: { response in
                print("✅ iPhone responded: \(response)")
                continuation.resume()
            }, errorHandler: { error in
                print("❌ Send error: \(error.localizedDescription)")
                continuation.resume(throwing: error)
            })
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isActivated = (activationState == .activated)
            self.isReachable = session.isReachable
            
            print("✅ watchOS WCSession activated: \(activationState.rawValue)")
            if let error = error {
                print("⚠️ Activation error: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("📱 iPhone reachability changed: \(session.isReachable)")
        }
    }
}

// MARK: - 에러 정의
enum WatchConnectivityError: LocalizedError {
    case notActivated
    case notReachable
    case sendFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .notActivated:
            return "WatchConnectivity is not activated"
        case .notReachable:
            return "iPhone is not reachable"
        case .sendFailed(let message):
            return "Send failed: \(message)"
        }
    }
}
