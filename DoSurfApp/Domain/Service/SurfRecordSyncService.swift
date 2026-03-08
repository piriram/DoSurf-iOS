import Foundation
import RxSwift
import ActivityKit

final class SurfRecordSyncService {
    private let repository: NoteRepositoryProtocol
    private let clockSkewTolerance: TimeInterval = 2

    init(repository: NoteRepositoryProtocol = SurfRecordRepository()) {
        self.repository = repository
    }

    func applyWatchPayloads(_ sessions: [WatchSessionPayload]) -> Single<Void> {
        guard !sessions.isEmpty else { return .just(()) }

        let reducedPayloads = coalescePayloads(sessions)
        let syncJobs = reducedPayloads.map { syncSession($0) }

        return Single.zip(syncJobs)
            .map { applied in
                if applied.contains(true) {
                    NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
                }
                return ()
            }
    }

    private func coalescePayloads(_ payloads: [WatchSessionPayload]) -> [WatchSessionPayload] {
        var latestByRecordId: [String: WatchSessionPayload] = [:]

        for payload in payloads {
            guard let current = latestByRecordId[payload.recordId] else {
                latestByRecordId[payload.recordId] = payload
                continue
            }

            if shouldPreferIncoming(payload, over: current) {
                latestByRecordId[payload.recordId] = payload
            }
        }

        return latestByRecordId.values.sorted { $0.lastModifiedAt < $1.lastModifiedAt }
    }

    private func shouldPreferIncoming(_ incoming: WatchSessionPayload, over current: WatchSessionPayload) -> Bool {
        if incoming.lastModifiedAt != current.lastModifiedAt {
            return incoming.lastModifiedAt > current.lastModifiedAt
        }

        if incoming.sessionState != current.sessionState {
            return incoming.sessionState.rawValue > current.sessionState.rawValue
        }

        if incoming.isDeleted != current.isDeleted {
            return incoming.isDeleted
        }

        if incoming.payloadVersion != current.payloadVersion {
            return incoming.payloadVersion > current.payloadVersion
        }

        return incoming.deviceId < current.deviceId
    }

    private func syncSession(_ payload: WatchSessionPayload) -> Single<Bool> {
        switch payload.sessionState {
        case .started:
            startLiveActivityIfNeeded(payload)
            return .just(false)
        case .inProgress:
            updateLiveActivity(payload)
            return .just(false)
        case .completed, .deleted:
            handleLiveActivityOnTerminalState(payload)
            return shouldApply(payload)
                .flatMap { [weak self] shouldApply in
                    guard let self else { return .just(false) }
                    if !shouldApply { return .just(false) }
                    return self.fetchOrCreateRecord(for: payload)
                }
        }
    }

    private func shouldApply(_ payload: WatchSessionPayload) -> Single<Bool> {
        repository.fetchSurfRecord(byRecordId: payload.recordId)
            .map { [clockSkewTolerance] local in
                guard let local else {
                    return payload.schemaVersion >= WatchPayloadSchema.minimumSupportedVersion
                }

                if payload.schemaVersion < WatchPayloadSchema.minimumSupportedVersion {
                    return false
                }

                let delta = payload.lastModifiedAt.timeIntervalSince(local.lastModifiedAt)
                if delta > clockSkewTolerance {
                    return true
                }
                if delta < -clockSkewTolerance {
                    return false
                }

                if payload.isDeleted != local.isDeleted {
                    return payload.isDeleted
                }

                if payload.payloadVersion != Int(local.payloadVersion) {
                    return payload.payloadVersion >= Int(local.payloadVersion)
                }

                if payload.deviceId == local.deviceId {
                    return true
                }

                return payload.deviceId < local.deviceId
            }
    }

    private func fetchOrCreateRecord(for payload: WatchSessionPayload) -> Single<Bool> {
        repository.fetchSurfRecord(byRecordId: payload.recordId)
            .flatMap { [weak self] existing in
                guard let self else { return .just(false) }
                return self.saveOrUpdate(payload, existing: existing)
            }
    }

    private func saveOrUpdate(_ payload: WatchSessionPayload, existing: SurfRecordData?) -> Single<Bool> {
        if existing == nil && payload.isDeleted {
            return .just(false)
        }

        let merged = SurfRecordData(
            beachID: payload.beachID != 0 ? payload.beachID : (existing?.beachID ?? 0),
            id: existing?.id,
            recordId: payload.recordId,
            payloadVersion: Int16(max(payload.payloadVersion, Int(existing?.payloadVersion ?? 0))),
            lastModifiedAt: max(payload.lastModifiedAt, existing?.lastModifiedAt ?? .distantPast),
            deviceId: payload.deviceId,
            isDeleted: payload.isDeleted,
            surfDate: payload.startTime,
            startTime: payload.startTime,
            endTime: payload.endTime,
            rating: Int16(payload.rating),
            memo: payload.memo,
            isPin: payload.isPinned,
            charts: existing?.charts ?? []
        )

        guard let existing else {
            return repository.saveSurfRecord(merged).map { true }
        }

        return repository.updateSurfRecord(
            SurfRecordData(
                beachID: merged.beachID,
                id: existing.id,
                recordId: merged.recordId,
                payloadVersion: merged.payloadVersion,
                lastModifiedAt: merged.lastModifiedAt,
                deviceId: merged.deviceId,
                isDeleted: merged.isDeleted,
                surfDate: merged.surfDate,
                startTime: merged.startTime,
                endTime: merged.endTime,
                rating: merged.rating,
                memo: merged.memo,
                isPin: merged.isPin,
                charts: merged.charts
            )
        )
        .map { true }
    }

    private func startLiveActivityIfNeeded(_ payload: WatchSessionPayload) {
        guard #available(iOS 16.2, *) else { return }
        SurfingActivityManager.shared.startActivity(
            startTime: payload.startTime,
            beachName: "서핑 중",
            rideCount: payload.waveCount,
            averageHeartRate: payload.avgHeartRate
        )
    }

    private func updateLiveActivity(_ payload: WatchSessionPayload) {
        guard #available(iOS 16.2, *) else { return }
        SurfingActivityManager.shared.updateSummary(
            beachName: "서핑 중",
            rideCount: payload.waveCount,
            averageHeartRate: payload.avgHeartRate
        )
    }

    private func handleLiveActivityOnTerminalState(_ payload: WatchSessionPayload) {
        guard #available(iOS 16.2, *) else { return }
        SurfingActivityManager.shared.updateSummary(
            beachName: "서핑 완료",
            rideCount: payload.waveCount,
            averageHeartRate: payload.avgHeartRate
        )

        SurfingActivityManager.shared.endActivity(dismissalPolicy: .immediate)
    }
}
