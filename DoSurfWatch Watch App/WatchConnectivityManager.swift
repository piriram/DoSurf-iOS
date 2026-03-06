import Foundation
import WatchConnectivity
import SwiftUI
import Combine
#if os(watchOS)
import WatchKit
#endif

@MainActor
final class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published private(set) var isReachable = false
    @Published private(set) var isActivated = false
    @Published private(set) var pendingCount = 0

    private var pendingSessions: [WatchSurfSessionData] = []
    private var isSending = false
    private let maxBatchCount = WatchPayloadSchema.defaultBatchSize
    private let maxRetryCount = 3
    private let pendingStore = PendingSessionStore()

    #if os(watchOS)
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    #endif

    override init() {
        super.init()
        pendingSessions = pendingStore.load()
        pendingCount = pendingSessions.count

        #if os(watchOS)
        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: WKExtension.applicationDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.flushPending()
        }
        #endif
    }

    deinit {
        #if os(watchOS)
        if let observer = appDidBecomeActiveObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        #endif
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

    func enqueuePayload(_ payload: WatchSurfSessionData) {
        upsertPending(payload)
        flushPending()
    }

    func enqueuePayloads(_ sessions: [WatchSurfSessionData]) {
        guard !sessions.isEmpty else { return }

        sessions.forEach { upsertPending($0) }
        flushPending()
    }

    func flushPending() {
        guard !isSending else { return }

        Task { @MainActor in
            guard !isSending else { return }
            isSending = true
            defer { isSending = false }

            do {
                try await sendAllPendingBatches()
            } catch {
                print("⚠️ Flush failed: \(error.localizedDescription)")
            }
        }
    }

    private func sendAllPendingBatches() async throws {
        guard WCSession.default.activationState == .activated else {
            throw WatchConnectivityError.notActivated
        }

        while !pendingSessions.isEmpty {
            guard WCSession.default.isReachable else {
                print("ℹ️ iPhone not reachable. Keep pending: \(pendingSessions.count)")
                throw WatchConnectivityError.notReachable
            }

            let batch = Array(pendingSessions.prefix(maxBatchCount))
            try await sendBatchWithRetry(batch)
        }
    }

    private func sendBatchWithRetry(_ batch: [WatchSurfSessionData]) async throws {
        var attempt = 0

        while true {
            do {
                let response = try await sendBatchOnce(batch)
                guard response.success else {
                    throw WatchConnectivityError.sendFailed(response.message)
                }

                let acknowledgedCount = min(response.acceptedCount, batch.count)
                guard acknowledgedCount > 0 else {
                    throw WatchConnectivityError.sendFailed("No payload acknowledged by iPhone")
                }

                removeConfirmed(batch: batch, acknowledgedCount: acknowledgedCount)
                return
            } catch {
                retainPending(batch: batch, error: error)

                guard attempt < maxRetryCount else {
                    throw error
                }

                attempt += 1
                let delay = UInt64(pow(2.0, Double(attempt)) * 0.5 * Double(NSEC_PER_SEC))
                try? await Task.sleep(nanoseconds: delay)
            }
        }
    }

    private func sendBatchOnce(_ batch: [WatchSurfSessionData]) async throws -> WatchSendReply {
        let payload: [String: Any] = [
            WatchMessageKey.payloadVersion: WatchPayloadSchema.currentVersion,
            WatchMessageKey.payloads: batch.map { $0.dictionary }
        ]

        let reply = try await withCheckedThrowingContinuation { continuation in
            WCSession.default.sendMessage(payload, replyHandler: { response in
                continuation.resume(returning: response)
            }, errorHandler: { error in
                continuation.resume(throwing: error)
            })
        }

        return WatchSendReply(dictionary: reply)
    }

    private func upsertPending(_ payload: WatchSurfSessionData) {
        if let index = pendingSessions.firstIndex(where: { $0.sessionId == payload.sessionId }) {
            let current = pendingSessions[index]
            guard shouldReplace(current: current, incoming: payload) else { return }
            pendingSessions[index] = payload
        } else {
            pendingSessions.append(payload)
        }

        persistPending()
    }

    private func shouldReplace(current: WatchSurfSessionData, incoming: WatchSurfSessionData) -> Bool {
        if incoming.lastModifiedAt != current.lastModifiedAt {
            return incoming.lastModifiedAt > current.lastModifiedAt
        }

        if incoming.state != current.state {
            return incoming.state.rawValue > current.state.rawValue
        }

        return incoming.payloadVersion >= current.payloadVersion
    }

    private func removeConfirmed(batch: [WatchSurfSessionData], acknowledgedCount: Int) {
        guard acknowledgedCount > 0 else { return }

        let confirmed = Array(batch.prefix(acknowledgedCount))

        for snapshot in confirmed {
            guard let index = pendingSessions.firstIndex(where: { $0.sessionId == snapshot.sessionId }) else {
                continue
            }

            let current = pendingSessions[index]
            guard shouldDropPending(current: current, confirmed: snapshot) else {
                continue
            }

            pendingSessions.remove(at: index)
        }

        persistPending()
    }

    private func shouldDropPending(current: WatchSurfSessionData, confirmed: WatchSurfSessionData) -> Bool {
        if current.lastModifiedAt > confirmed.lastModifiedAt {
            return false
        }

        if current.lastModifiedAt == confirmed.lastModifiedAt {
            if current.state.rawValue > confirmed.state.rawValue {
                return false
            }

            if current.state == confirmed.state,
               current.payloadVersion > confirmed.payloadVersion {
                return false
            }
        }

        return true
    }

    private func retainPending(batch: [WatchSurfSessionData], error: Error) {
        persistPending()
        print("↩️ keep pending batch for retry: count=\(batch.count), error=\(error.localizedDescription)")
    }

    private func persistPending() {
        pendingStore.save(pendingSessions)
        pendingCount = pendingSessions.count
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        Task { @MainActor in
            isActivated = (activationState == .activated)
            isReachable = session.isReachable

            print("✅ watchOS WCSession activated: \(activationState.rawValue)")
            if let error {
                print("⚠️ Activation error: \(error.localizedDescription)")
            }

            if isActivated && isReachable {
                flushPending()
            }
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            isReachable = session.isReachable
            print("📱 iPhone reachability: \(session.isReachable)")
            if session.isReachable {
                flushPending()
            }
        }
    }

    #if os(watchOS)
    nonisolated func sessionCompanionAppInstalledDidChange(_ session: WCSession) {
        Task { @MainActor in
            if session.isCompanionAppInstalled {
                flushPending()
            }
        }
    }
    #endif
}

// MARK: - Error
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

private enum WatchMessageKey {
    static let payloadVersion = "payloadVersion"
    static let payloads = "payloads"
}

private enum WatchReplyKey {
    static let success = "success"
    static let message = "message"
    static let acceptedCount = "acceptedCount"
}

private struct WatchSendReply {
    let success: Bool
    let message: String
    let acceptedCount: Int

    init(dictionary: [String: Any]) {
        success = (dictionary[WatchReplyKey.success] as? Bool) ?? false
        message = (dictionary[WatchReplyKey.message] as? String) ?? ""
        acceptedCount = (dictionary[WatchReplyKey.acceptedCount] as? Int) ?? 0
    }
}

private struct PendingSessionStore {
    private let defaults = UserDefaults.standard
    private let storageKey = "watch.pending.sessions.v1"

    func save(_ sessions: [WatchSurfSessionData]) {
        guard !sessions.isEmpty else {
            defaults.removeObject(forKey: storageKey)
            return
        }

        do {
            let data = try JSONEncoder().encode(sessions)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("⚠️ failed to persist pending sessions: \(error.localizedDescription)")
        }
    }

    func load() -> [WatchSurfSessionData] {
        guard let data = defaults.data(forKey: storageKey) else {
            return []
        }

        do {
            return try JSONDecoder().decode([WatchSurfSessionData].self, from: data)
        } catch {
            defaults.removeObject(forKey: storageKey)
            print("⚠️ failed to restore pending sessions: \(error.localizedDescription)")
            return []
        }
    }
}
