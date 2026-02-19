import Foundation
import RxSwift

final class SurfRecordSyncService {
    private let repository: NoteRepositoryProtocol

    init(repository: NoteRepositoryProtocol = SurfRecordRepository()) {
        self.repository = repository
    }

    func applyWatchPayloads(_ sessions: [WatchSessionPayload]) -> Single<Void> {
        guard !sessions.isEmpty else { return .just(()) }

        let applied = sessions.map { sessionPayload -> Single<Bool> in
            shouldApply(sessionPayload)
                .flatMap { [weak self] shouldApply in
                    guard let self else { return .just(false) }
                    guard shouldApply else { return .just(false) }
                    return self.fetchOrCreateRecord(for: sessionPayload)
                }
        }

        return Single.zip(applied)
            .map { applieds in
                if applieds.contains(true) {
                    NotificationCenter.default.post(name: .surfRecordsDidChange, object: nil)
                }
                return ()
            }
    }

    private func shouldApply(_ payload: WatchSessionPayload) -> Single<Bool> {
        repository.fetchSurfRecord(byRecordId: payload.recordId)
            .map { local in
                guard let local else {
                    return true
                }

                if payload.lastModifiedAt < local.lastModifiedAt {
                    return false
                }

                if payload.lastModifiedAt > local.lastModifiedAt {
                    return true
                }

                if payload.isDeleted != local.isDeleted {
                    return payload.isDeleted
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
        let merged = SurfRecordData(
            beachID: existing?.beachID ?? 0,
            id: existing?.id,
            recordId: payload.recordId,
            payloadVersion: Int16(payload.payloadVersion),
            lastModifiedAt: payload.lastModifiedAt,
            deviceId: payload.deviceId,
            isDeleted: payload.isDeleted,
            surfDate: payload.startTime,
            startTime: payload.startTime,
            endTime: payload.endTime,
            rating: existing?.rating ?? 0,
            memo: existing?.memo,
            isPin: existing?.isPin ?? false,
            charts: existing?.charts ?? []
        )

        if existing == nil {
            return repository.saveSurfRecord(merged).map { true }
        }

        return repository.updateSurfRecord(merged).map { true }
    }
}
