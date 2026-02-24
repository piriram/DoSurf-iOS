import Foundation
import WatchConnectivity
import SwiftUI
import Combine

@MainActor
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isReachable = false
    @Published var isActivated = false
    
    private var pendingSessions: [WatchSurfSessionData] = []
    private var isSending = false
    private let maxBatchCount = 5
    private let maxRetryCount = 2

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
        pendingSessions.append(data)
        try await sendPendingSessions(retryCount: 0)
    }
    
    func sendBatch(_ sessions: [WatchSurfSessionData]) async throws {
        pendingSessions.append(contentsOf: sessions)
        try await sendPendingSessions(retryCount: 0)
    }
    
    func flushPending() {
        Task {
            do {
                try await sendPendingSessions(retryCount: 0)
            } catch {
                print("⚠️ flush failed: \(error.localizedDescription)")
            }
        }
    }
    
    private func sendPendingSessions(retryCount: Int) async throws {
        guard WCSession.default.activationState == .activated else {
            throw WatchConnectivityError.notActivated
        }
        guard WCSession.default.isReachable else {
            print("ℹ️ WatchConnectivity is not reachable. Pending sessions retained: \(pendingSessions.count)")
            throw WatchConnectivityError.notReachable
        }
        guard !pendingSessions.isEmpty else { return }
        guard !isSending else { return }
        
        isSending = true
        defer { isSending = false }
        
        let batch = Array(pendingSessions.prefix(maxBatchCount))
        let payload: [String: Any] = [
            "payloadVersion": 1,
            "payloads": batch.map { $0.dictionary }
        ]
        
        do {
            try await withCheckedThrowingContinuation { continuation in
                WCSession.default.sendMessage(payload, replyHandler: { [weak self] _ in
                    self?.confirmSent(batchCount: batch.count)
                    continuation.resume()
                }, errorHandler: { [weak self] error in
                    print("❌ Send error: \(error.localizedDescription)")
                    self?.rollbackBatch(batchCount: batch.count)
                    continuation.resume(throwing: error)
                })
            }
            
            if !pendingSessions.isEmpty {
                try await sendPendingSessions(retryCount: 0)
            }
        } catch {
            if retryCount < maxRetryCount {
                print("↻ retry send pending sessions (\(retryCount + 1)/\(maxRetryCount))")
                let nextRetry = retryCount + 1
                try await Task.sleep(nanoseconds: UInt64(0.5 * Double(1 << nextRetry) * 1_000_000_000))
                try await sendPendingSessions(retryCount: nextRetry)
                return
            }
            throw error
        }
    }
    
    private func confirmSent(batchCount: Int) {
        pendingSessions.removeFirst(min(batchCount, pendingSessions.count))
        print("✅ sent session batch. pending: \(pendingSessions.count)")
    }
    
    private func rollbackBatch(batchCount: Int) {
        // 현재는 append-only 큐라 rollback은 필요하지 않음.
        // 실패한 배치만 pending 상태로 유지
        print("↩️ keep pending batch for retry: +\(batchCount)")
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            self.isActivated = (activationState == .activated)
            self.isReachable = session.isReachable
            
            print("✅ watchOS WCSession activated: \(activationState.rawValue)")
            if let error {
                print("⚠️ Activation error: \(error.localizedDescription)")
            }
        }
    }
    
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("📱 iPhone reachability changed: \(session.isReachable)")
            if session.isReachable {
                self.flushPending()
            }
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
