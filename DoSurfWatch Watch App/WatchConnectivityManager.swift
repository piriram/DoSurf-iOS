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
    @Published private(set) var mirroredRecordCount = 0
    @Published private(set) var mirroredSessions: [WatchSurfSessionData] = []

    private var pendingSessions: [WatchSurfSessionData] = []
    private var isSending = false
    private let maxBatchCount = WatchPayloadSchema.defaultBatchSize
    private let maxRetryCount = 3
    private let pendingStore = PendingSessionStore()
    private let mirroredStore = MirroredSessionStore()

    #if os(watchOS)
    private var appDidBecomeActiveObserver: NSObjectProtocol?
    #endif

    override init() {
        super.init()
        pendingSessions = pendingStore.load()
        pendingCount = pendingSessions.count
        mirroredSessions = mirroredStore.load()
        mirroredRecordCount = mirroredSessions.filter { !$0.isDeleted }.count

        #if os(watchOS)
        appDidBecomeActiveObserver = NotificationCenter.default.addObserver(
            forName: WKExtension.applicationDidBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.flushPending()
            }
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

    var syncedRecords: [WatchSurfSessionData] {
        mirroredSessions
            .filter { !$0.isDeleted }
            .sorted { lhs, rhs in
                if lhs.isPinned != rhs.isPinned {
                    return lhs.isPinned && !rhs.isPinned
                }
                if lhs.startTime != rhs.startTime {
                    return lhs.startTime > rhs.startTime
                }
                return lhs.sessionId < rhs.sessionId
            }
    }

    func saveMirroredRecordEdits(
        sessionId: String,
        rating: Int,
        memo: String,
        isPinned: Bool
    ) {
        guard let current = mirroredSessions.first(where: { $0.sessionId == sessionId && !$0.isDeleted }) else {
            return
        }

        let trimmedMemo = memo.trimmingCharacters(in: .whitespacesAndNewlines)
        let updated = WatchSurfSessionData(
            payloadVersion: WatchPayloadSchema.nextPayloadVersion(after: current.payloadVersion),
            schemaVersion: current.schemaVersion,
            sessionId: current.sessionId,
            beachID: current.beachID,
            beachName: current.beachName,
            distanceMeters: current.distanceMeters,
            durationSeconds: current.durationSeconds,
            startTime: current.startTime,
            endTime: current.endTime,
            waveCount: current.waveCount,
            maxHeartRate: current.maxHeartRate,
            avgHeartRate: current.avgHeartRate,
            activeCalories: current.activeCalories,
            strokeCount: current.strokeCount,
            lastModifiedAt: Date(),
            deviceId: WatchLocalDeviceIdentity.stableId,
            state: .completed,
            isDeleted: false,
            rating: min(max(rating, 0), 5),
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo,
            isPinned: isPinned,
            avgWaveHeight: current.avgWaveHeight,
            maxWaveHeight: current.maxWaveHeight,
            avgWavePeriod: current.avgWavePeriod,
            avgWaterTemperature: current.avgWaterTemperature,
            avgWindSpeed: current.avgWindSpeed
        )

        mergeMirroredPayloads([updated], source: "local-edit")
        enqueuePayload(updated)
    }

    func deleteMirroredRecord(sessionId: String) {
        guard let current = mirroredSessions.first(where: { $0.sessionId == sessionId && !$0.isDeleted }) else {
            return
        }

        let deleted = WatchSurfSessionData(
            payloadVersion: WatchPayloadSchema.nextPayloadVersion(after: current.payloadVersion),
            schemaVersion: current.schemaVersion,
            sessionId: current.sessionId,
            beachID: current.beachID,
            beachName: current.beachName,
            distanceMeters: current.distanceMeters,
            durationSeconds: current.durationSeconds,
            startTime: current.startTime,
            endTime: current.endTime,
            waveCount: current.waveCount,
            maxHeartRate: current.maxHeartRate,
            avgHeartRate: current.avgHeartRate,
            activeCalories: current.activeCalories,
            strokeCount: current.strokeCount,
            lastModifiedAt: Date(),
            deviceId: WatchLocalDeviceIdentity.stableId,
            state: .deleted,
            isDeleted: true,
            rating: current.rating,
            memo: current.memo,
            isPinned: current.isPinned,
            avgWaveHeight: current.avgWaveHeight,
            maxWaveHeight: current.maxWaveHeight,
            avgWavePeriod: current.avgWavePeriod,
            avgWaterTemperature: current.avgWaterTemperature,
            avgWindSpeed: current.avgWindSpeed
        )

        mergeMirroredPayloads([deleted], source: "local-delete")
        enqueuePayload(deleted)
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

    private func applyMirroredSnapshot(_ payloads: [WatchSurfSessionData], source: String) {
        mirroredSessions = payloads.sorted { lhs, rhs in
            if lhs.lastModifiedAt != rhs.lastModifiedAt {
                return lhs.lastModifiedAt > rhs.lastModifiedAt
            }
            return lhs.sessionId < rhs.sessionId
        }
        mirroredStore.save(mirroredSessions)
        mirroredRecordCount = mirroredSessions.filter { !$0.isDeleted }.count
        print("📦 replaced iPhone records on watch: source=\(source), total=\(mirroredSessions.count)")
    }

    private func mergeMirroredPayloads(_ payloads: [WatchSurfSessionData], source: String) {
        guard !payloads.isEmpty else { return }

        for payload in payloads {
            if let index = mirroredSessions.firstIndex(where: { $0.sessionId == payload.sessionId }) {
                let current = mirroredSessions[index]
                guard shouldReplaceMirror(current: current, incoming: payload) else { continue }
                mirroredSessions[index] = payload
            } else {
                mirroredSessions.append(payload)
            }
        }

        mirroredSessions.sort { lhs, rhs in
            if lhs.lastModifiedAt != rhs.lastModifiedAt {
                return lhs.lastModifiedAt > rhs.lastModifiedAt
            }
            return lhs.sessionId < rhs.sessionId
        }

        mirroredStore.save(mirroredSessions)
        mirroredRecordCount = mirroredSessions.filter { !$0.isDeleted }.count
        print("📥 merged iPhone records on watch: source=\(source), total=\(mirroredSessions.count)")
    }

    private func shouldReplaceMirror(current: WatchSurfSessionData, incoming: WatchSurfSessionData) -> Bool {
        if incoming.isDeleted != current.isDeleted {
            return incoming.isDeleted
        }

        if incoming.lastModifiedAt != current.lastModifiedAt {
            return incoming.lastModifiedAt > current.lastModifiedAt
        }

        if incoming.state != current.state {
            return incoming.state.rawValue > current.state.rawValue
        }

        if incoming.payloadVersion != current.payloadVersion {
            return incoming.payloadVersion > current.payloadVersion
        }

        return incoming.deviceId < current.deviceId
    }

    private func receiveInbound(message: [String: Any], source: String) {
        do {
            let payloads = try parseInboundPayloads(from: message)
            let syncKind = WatchInboundSyncKind(rawValue: (message[WatchMessageKey.syncKind] as? String) ?? "")
            Task { @MainActor in
                if syncKind == .snapshot {
                    applyMirroredSnapshot(payloads, source: source)
                } else {
                    mergeMirroredPayloads(payloads, source: source)
                }
            }
        } catch {
            print("⚠️ failed to parse inbound iPhone sync from \(source): \(error.localizedDescription)")
        }
    }

    private func parseInboundPayloads(from message: [String: Any]) throws -> [WatchSurfSessionData] {
        if let payloads = message[WatchMessageKey.payloads] as? [[String: Any]] {
            if payloads.isEmpty {
                return []
            }
            return try payloads.map { try WatchInboundPayloadMapper.toPayload(from: $0) }
        }

        let fallback = try WatchInboundPayloadMapper.toPayload(from: message)
        return [fallback]
    }
}

private enum WatchInboundSyncKind: String {
    case delta
    case snapshot
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

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
        Task { @MainActor in
            receiveInbound(message: userInfo, source: "userInfo")
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        Task { @MainActor in
            receiveInbound(message: applicationContext, source: "applicationContext")
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
    static let syncKind = "syncKind"
    static let payloadVersion = "payloadVersion"
    static let payloads = "payloads"
    static let schemaVersion = "schemaVersion"
    static let sessionId = "sessionId"
    static let beachID = "beachID"
    static let beachName = "beachName"
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
    static let avgWaveHeight = "avgWaveHeight"
    static let maxWaveHeight = "maxWaveHeight"
    static let avgWavePeriod = "avgWavePeriod"
    static let avgWaterTemperature = "avgWaterTemperature"
    static let avgWindSpeed = "avgWindSpeed"
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

private enum WatchInboundPayloadMapper {
    static func toPayload(from dictionary: [String: Any]) throws -> WatchSurfSessionData {
        guard let sessionId = parseString(dictionary[WatchMessageKey.sessionId]),
              let distance = parseDouble(dictionary[WatchMessageKey.distanceMeters]),
              let duration = parseDouble(dictionary[WatchMessageKey.durationSeconds]) else {
            throw WatchConnectivityError.sendFailed("Missing mirrored record fields")
        }

        let state = parseState(dictionary[WatchMessageKey.state])
            ?? (parseBool(dictionary[WatchMessageKey.isDeleted]) == true ? .deleted : .completed)

        return WatchSurfSessionData(
            payloadVersion: parseInt(dictionary[WatchMessageKey.payloadVersion]) ?? 1,
            schemaVersion: parseInt(dictionary[WatchMessageKey.schemaVersion]) ?? WatchPayloadSchema.currentVersion,
            sessionId: sessionId,
            beachID: parseInt(dictionary[WatchMessageKey.beachID]) ?? 0,
            beachName: parseString(dictionary[WatchMessageKey.beachName]),
            distanceMeters: distance,
            durationSeconds: duration,
            startTime: parseDate(dictionary[WatchMessageKey.startTime]) ?? Date(),
            endTime: parseDate(dictionary[WatchMessageKey.endTime]) ?? Date(),
            waveCount: parseInt(dictionary[WatchMessageKey.waveCount]) ?? 0,
            maxHeartRate: parseDouble(dictionary[WatchMessageKey.maxHeartRate]) ?? 0,
            avgHeartRate: parseDouble(dictionary[WatchMessageKey.avgHeartRate]) ?? 0,
            activeCalories: parseDouble(dictionary[WatchMessageKey.activeCalories]) ?? 0,
            strokeCount: parseInt(dictionary[WatchMessageKey.strokeCount]) ?? 0,
            lastModifiedAt: parseDate(dictionary[WatchMessageKey.lastModifiedAt]) ?? Date(),
            deviceId: parseString(dictionary[WatchMessageKey.deviceId]) ?? "ios-unknown",
            state: state,
            isDeleted: parseBool(dictionary[WatchMessageKey.isDeleted]),
            rating: parseInt(dictionary[WatchMessageKey.rating]) ?? 0,
            memo: parseString(dictionary[WatchMessageKey.memo]),
            isPinned: parseBool(dictionary[WatchMessageKey.isPinned]) ?? false,
            avgWaveHeight: parseDouble(dictionary[WatchMessageKey.avgWaveHeight]),
            maxWaveHeight: parseDouble(dictionary[WatchMessageKey.maxWaveHeight]),
            avgWavePeriod: parseDouble(dictionary[WatchMessageKey.avgWavePeriod]),
            avgWaterTemperature: parseDouble(dictionary[WatchMessageKey.avgWaterTemperature]),
            avgWindSpeed: parseDouble(dictionary[WatchMessageKey.avgWindSpeed])
        )
    }

    private static func parseDouble(_ value: Any?) -> Double? {
        switch value {
        case let number as NSNumber:
            return number.doubleValue
        case let value as Double:
            return value
        case let value as Int:
            return Double(value)
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
        case let value as Bool:
            return value
        case let number as NSNumber:
            return number.boolValue
        case let value as String:
            let normalized = value.lowercased()
            return normalized == "true" || normalized == "1"
        default:
            return nil
        }
    }

    private static func parseDate(_ value: Any?) -> Date? {
        switch value {
        case let date as Date:
            return date
        case let number as NSNumber:
            return Date(timeIntervalSince1970: number.doubleValue)
        case let value as Double:
            return Date(timeIntervalSince1970: value)
        case let value as String:
            guard let timestamp = Double(value) else { return nil }
            return Date(timeIntervalSince1970: timestamp)
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

private struct MirroredSessionStore {
    private let defaults = UserDefaults.standard
    private let storageKey = "watch.mirrored.sessions.v1"

    func save(_ sessions: [WatchSurfSessionData]) {
        guard !sessions.isEmpty else {
            defaults.removeObject(forKey: storageKey)
            return
        }

        do {
            let data = try JSONEncoder().encode(sessions)
            defaults.set(data, forKey: storageKey)
        } catch {
            print("⚠️ failed to persist mirrored sessions: \(error.localizedDescription)")
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
            print("⚠️ failed to restore mirrored sessions: \(error.localizedDescription)")
            return []
        }
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
